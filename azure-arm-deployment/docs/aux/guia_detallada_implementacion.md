# Guía Detallada de Implementación: Azure Container Apps + Application Gateway + PostgreSQL Database

## Índice
1. [Introducción y arquitectura](#introducción-y-arquitectura)
2. [Pre-requisitos detallados](#pre-requisitos-detallados)
3. [Preparación del entorno de trabajo](#preparación-del-entorno-de-trabajo)
4. [Fase 1: Infraestructura base](#fase-1-infraestructura-base)
5. [Fase 2: Configuración de la base de datos](#fase-2-configuración-de-la-base-de-datos)
6. [Fase 3: Preparación de las aplicaciones](#fase-3-preparación-de-las-aplicaciones)
7. [Fase 4: Despliegue en Container Apps](#fase-4-despliegue-en-container-apps)
8. [Fase 5: Configuración de Application Gateway](#fase-5-configuración-de-application-gateway)
9. [Fase 6: Configuración de WAF](#fase-6-configuración-de-waf)
10. [Fase 7: Testing y validación](#fase-7-testing-y-validación)
11. [Fase 8: Monitoreo y alertas](#fase-8-monitoreo-y-alertas)
12. [Troubleshooting común](#troubleshooting-común)
13. [Optimizaciones y buenas prácticas](#optimizaciones-y-buenas-prácticas)
14. [Recursos adicionales](#recursos-adicionales)

---

## Introducción y arquitectura

### Descripción del sistema

Este documento detalla la implementación paso a paso de una aplicación web moderna con las siguientes características:

- **Frontend**: Aplicación React que proporciona la interfaz de usuario
- **Backend**: API REST desarrollada en ASP.NET Core 
- **Base de datos**: Azure Database for PostgreSQL para almacenamiento persistente
- **Infraestructura**: Uso de Azure Container Apps con integración de red virtual
- **Seguridad**: Application Gateway con Web Application Firewall (WAF)

### Arquitectura objetivo

```
                                   ┌─► Container App (React Frontend)
                                   │
Internet → Application Gateway (WAF)
                                   │
                                   └─► Container App (ASP.NET API) ─► Azure PostgreSQL
                      ↓
                 VNET Integration
```

### ¿Por qué esta arquitectura?

- **Container Apps**: Servicio gestionado para ejecutar contenedores con escalado automático y sin necesidad de administrar Kubernetes
- **Application Gateway**: Enrutamiento inteligente basado en rutas, balanceo de carga y WAF para protección
- **VNET Integration**: Aislamiento de red y seguridad mejorada
- **PostgreSQL Database**: Base de datos relacional de código abierto con excelente rendimiento para aplicaciones transaccionales y soporte nativo para tipos JSON

---

## Pre-requisitos detallados

### Software necesario en tu estación de trabajo

1. **Azure CLI**: 
   - Versión mínima recomendada: 2.40.0
   - Instalación en Linux: 
     ```bash
     curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
     ```
   - Instalación en Windows: [Descargar instalador](https://aka.ms/installazurecliwindows)
   - Verificar instalación: 
     ```bash
     az --version
     ```

2. **Docker Desktop**:
   - Versión mínima recomendada: 4.13.0
   - Instalación en Linux:
     ```bash
     curl -fsSL https://get.docker.com | sh
     ```
   - Instalación en Windows/Mac: [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - Verificar instalación:
     ```bash
     docker --version
     ```

3. **Herramientas de desarrollo**:
   - Visual Studio Code con extensiones: Azure Tools, Docker, C#, React
   - O Visual Studio 2022 con carga de trabajo ASP.NET y desarrollo web
   - Node.js y npm (para desarrollo React)
   - .NET SDK 8.0 o superior

### Requisitos de cuenta Azure

1. **Suscripción Azure activa** con permisos de propietario o colaborador
2. **Límites de servicio**: Verificar cuotas para recursos en la región elegida
3. **Permisos**: El usuario debe tener derechos para crear:
   - Grupos de recursos
   - Redes virtuales
   - Container Apps
   - PostgreSQL Database
   - Application Gateway
   
   **Verificación de permisos**:
   
   Para validar si tienes los permisos necesarios, puedes ejecutar estos comandos:
   
   ```bash
   # Verificar rol en la suscripción
   az role assignment list --assignee "tu-correo@ejemplo.com" --output table
   
   # Verificar si tienes permisos para crear recursos específicos
   # (Un intento de validación sin crear recursos reales)
   az provider operation show --namespace Microsoft.App --query "resourceTypes[?resourceType=='containerApps'].operations[].name" --output table
   az provider operation show --namespace Microsoft.Network --query "resourceTypes[?resourceType=='applicationGateways'].operations[].name" --output table
   az provider operation show --namespace Microsoft.DBforPostgreSQL --query "resourceTypes[?resourceType=='flexibleServers'].operations[].name" --output table
   
   # Verificar si puedes crear un grupo de recursos (validación específica)
   az group create --name "test-permissions" --location "eastus" --query "properties.provisioningState" --dry-run
   ```
   
   Si alguno de estos comandos devuelve un error de autorización, deberás solicitar permisos adicionales al administrador de tu suscripción Azure.

### Requisitos para la aplicación

1. **Código fuente**:
   - Aplicación ASP.NET Core API lista para contenedorizar
   - Aplicación React lista para contenedorizar
   - Archivos Dockerfile para ambos componentes
   
   **Ejemplo de Dockerfile para ASP.NET Core API**:
   ```dockerfile
   FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
   WORKDIR /app
   EXPOSE 8080
   
   FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
   WORKDIR /src
   COPY ["PaymentAPI.csproj", "./"]
   RUN dotnet restore "PaymentAPI.csproj"
   COPY . .
   RUN dotnet build "PaymentAPI.csproj" -c Release -o /app/build
   
   FROM build AS publish
   RUN dotnet publish "PaymentAPI.csproj" -c Release -o /app/publish
   
   FROM base AS final
   WORKDIR /app
   COPY --from=publish /app/publish .
   # Configuración para múltiples instancias
   ENV ASPNETCORE_URLS=http://+:8080
   ENTRYPOINT ["dotnet", "PaymentAPI.dll"]
   ```
   
   **Ejemplo de Dockerfile para React Frontend**:
   ```dockerfile
   # Etapa de compilación
   FROM node:18-alpine AS build
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci
   COPY . .
   # Configurar variables de entorno para producción
   ARG API_URL=/api
   ENV REACT_APP_API_BASE_URL=$API_URL
   RUN npm run build
   
   # Etapa de producción
   FROM nginx:alpine
   # Copiar configuración de nginx optimizada para SPA
   COPY nginx.conf /etc/nginx/conf.d/default.conf
   COPY --from=build /app/build /usr/share/nginx/html
   EXPOSE 80
   # Iniciar nginx en modo no-daemon
   CMD ["nginx", "-g", "daemon off;"]
   ```

2. **Preparación de datos**:
   - Scripts SQL de inicialización (si corresponde)
   - Datos de migración (si aplica)

3. **Consideraciones para escalado horizontal**:

   **Para la API (.NET Core)**:
   - **Stateless**: La API debe ser completamente stateless (sin estado). No almacenar información de sesión en memoria local.
   - **Almacenamiento distribuido para caché**: Usar Redis o similar para compartir caché entre instancias.
     
     **Costos aproximados de Azure Cache for Redis**:
     | Tier | Tamaño | Costo mensual (USD) | Casos de uso |
     |------|--------|---------------------|-------------|
     | Basic | C0 (250MB) | ~$17 | Desarrollo/pruebas, no recomendado para producción |
     | Basic | C1 (1GB) | ~$42 | Desarrollo/pruebas, no recomendado para producción |
     | Standard | C1 (1GB) | ~$56 | Producción pequeña escala, incluye replicación y SLA |
     | Standard | C2 (2.5GB) | ~$112 | Producción escala media |
     | Premium | P1 (6GB) | ~$412 | Producción con alto rendimiento, persistencia y VNET |
     | Premium | P2 (13GB) | ~$824 | Cargas de trabajo empresariales |
     
     > **NOTA DE OPTIMIZACIÓN DE COSTOS**: Para este proyecto de pago, una instancia Standard C1 (1GB) por ~$56/mes sería suficiente para comenzar, considerando que proporcionará alta disponibilidad con replicación y SLA garantizado. Si las necesidades de caché son mínimas, se puede usar temporalmente un Basic C0 (~$17/mes) durante desarrollo, aunque sin garantías de disponibilidad.
   
   - **Idempotencia**: Los endpoints POST/PUT deben ser idempotentes para soportar reintentos.
   - **Correlación**: Implementar IDs de correlación en logs para seguir solicitudes a través de múltiples instancias.
   - **Health checks**: Implementar endpoints de health con verificación de dependencias (DB, servicios externos).
   - **Circuit breakers**: Implementar patrones de circuit breaker para manejar fallos en servicios dependientes.
   - **Configuración centralizada**: Usar Azure App Configuration o similar para configuración dinámica.
   
   **Para el Frontend (React)**:
   - **Gestión de sesión**: Almacenar estado de sesión en almacenamiento del lado del cliente o servicios compartidos.
   - **Estrategia de caché**: Implementar estrategia de caché eficiente para assets estáticos (con invalidación adecuada).
   - **Sticky sessions**: Considerar si se necesitan sticky sessions para mantener estado de usuario en una instancia específica.
   - **API versioning**: Consumir APIs con versionado explícito.
   - **Manejo de errores robusto**: Implementar reintentos con backoff exponencial para llamadas a API.
   - **Progressive loading**: Implementar carga progresiva para mejorar la experiencia cuando hay latencia.

---

## Estrategia para ambientes de desarrollo y producción

Una arquitectura bien diseñada requiere una separación clara entre los ambientes de desarrollo, pruebas y producción. Esta separación asegura que los cambios puedan probarse adecuadamente antes de afectar a los usuarios finales.

### Enfoque de separación por grupos de recursos

Para empresas pequeñas y medianas (PyMES) o startups, el enfoque más práctico y costo-efectivo es la separación por grupos de recursos dentro de una única suscripción de Azure:

```
Suscripción única → RG-Desarrollo → Recursos de desarrollo
                  → RG-Pruebas    → Recursos de pruebas
                  → RG-Producción → Recursos de producción
```

**Ventajas de este enfoque**:
- Menor complejidad administrativa y reducción de costos de gestión
- Permite compartir recursos comunes como Container Registry o Key Vault
- Facturación centralizada que facilita el control de gastos
- Simplifica la administración de permisos y control de acceso
- Ideal para equipos pequeños con recursos limitados

**Implementación práctica**:
- Usa convención de nombres consistente: `rg-<proyecto>-dev`, `rg-<proyecto>-test`, `rg-<proyecto>-prod`
- Aplica etiquetas (tags) para identificar claramente cada ambiente: `Environment=Development|Test|Production`
- Crea grupos de recursos en la misma región para minimizar latencia durante promoción entre ambientes
- Configura políticas de Azure (Azure Policy) a nivel de grupo de recursos para asegurar cumplimiento

### Configuración específica para cada ambiente

| Componente | Desarrollo | Pruebas | Producción |
|------------|------------|---------|------------|
| **Container Apps** | Basic tier<br>Min Replicas: 0<br>Max Replicas: 2 | Basic tier<br>Min Replicas: 1<br>Max Replicas: 3 | Premium tier<br>Min Replicas: 2<br>Max Replicas: 10 |
| **PostgreSQL Database** | Basic tier<br>vCores mínimos | General Purpose<br>Con opción de escalado | Memory Optimized<br>Sin auto-pause |
| **Application Gateway** | Standard_v2<br>Sin WAF | Standard_v2<br>WAF en modo Detection | WAF_v2<br>WAF en modo Prevention |
| **Redis Cache** | Basic C0 (250MB) | Standard C1 (1GB) | Standard C2+ o Premium |
| **Networking** | VNET simplificada | Similar a producción | VNET completa con NSGs |

### Automatización de despliegues entre ambientes (CI/CD)

Para gestionar eficientemente los diferentes grupos de recursos (ambientes), es fundamental implementar un pipeline de CI/CD que automatice los despliegues:

1. **Flujo de promoción entre ambientes**:
   ```
   RG-Desarrollo → RG-Pruebas → RG-Producción
   ```

2. **Ejemplo de pipeline usando GitHub Actions para múltiples grupos de recursos**:
   ```yaml
   # Ejemplo para el enfoque de separación por grupos de recursos
   name: Deploy Container Apps Multi-Environment
   
   on:
     push:
       branches: [ main, staging, development ]
   
   jobs:
     build-and-deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v2
         
         - name: Set environment variables
           run: |
             if [[ ${{ github.ref }} == 'refs/heads/main' ]]; then
               echo "ENVIRONMENT=production" >> $GITHUB_ENV
               echo "AZURE_RG=rg-paymentapp-prod" >> $GITHUB_ENV
               echo "REPLICA_MIN=2" >> $GITHUB_ENV
               echo "REPLICA_MAX=10" >> $GITHUB_ENV
               echo "DB_SKU=S3" >> $GITHUB_ENV
             elif [[ ${{ github.ref }} == 'refs/heads/staging' ]]; then
               echo "ENVIRONMENT=test" >> $GITHUB_ENV
               echo "AZURE_RG=rg-paymentapp-test" >> $GITHUB_ENV
               echo "REPLICA_MIN=1" >> $GITHUB_ENV
               echo "REPLICA_MAX=3" >> $GITHUB_ENV
               echo "DB_SKU=S2" >> $GITHUB_ENV
             else
               echo "ENVIRONMENT=dev" >> $GITHUB_ENV
               echo "AZURE_RG=rg-paymentapp-dev" >> $GITHUB_ENV
               echo "REPLICA_MIN=0" >> $GITHUB_ENV
               echo "REPLICA_MAX=2" >> $GITHUB_ENV
               echo "DB_SKU=Basic" >> $GITHUB_ENV
             fi
         
         - name: Login to Azure
           uses: azure/login@v1
           with:
             creds: ${{ secrets.AZURE_CREDENTIALS }}
             
         - name: Build and push image
           run: |
             # Construir y subir la imagen - compartiendo el mismo Container Registry
             # entre los diferentes grupos de recursos/ambientes
             
         - name: Deploy to Container Apps
           run: |
             # Desplegar a Container App en el grupo de recursos correspondiente
             az containerapp update \
               --name api-paymentapp \
               --resource-group $AZURE_RG \
               --image $IMAGE_NAME \
               --min-replicas $REPLICA_MIN \
               --max-replicas $REPLICA_MAX \
               --env-vars "ASPNETCORE_ENVIRONMENT=$ENVIRONMENT"
   ```

### Manejo de variables de entorno y secretos en grupos de recursos separados

Cuando utilizamos diferentes grupos de recursos para cada ambiente, podemos configurar variables específicas para cada uno:

1. **Configuración diferenciada por grupo de recursos**:
   ```bash
   # Variables para desarrollo (grupo de recursos de desarrollo)
   PROJECT_NAME="paymentapp"
   RG_DEV="rg-$PROJECT_NAME-dev"
   
   az containerapp update \
     --name api-$PROJECT_NAME \
     --resource-group $RG_DEV \
     --env-vars "ASPNETCORE_ENVIRONMENT=Development" \
               "LogLevel__Default=Debug" \
               "UseDetailedErrors=true" \
               "AllowedOrigins=*"
   
   # Variables para producción (grupo de recursos de producción)
   RG_PROD="rg-$PROJECT_NAME-prod"
   
   az containerapp update \
     --name api-$PROJECT_NAME \
     --resource-group $RG_PROD \
     --env-vars "ASPNETCORE_ENVIRONMENT=Production" \
               "LogLevel__Default=Warning" \
               "UseDetailedErrors=false" \
               "AllowedOrigins=https://payment.example.com"
   ```

2. **Gestión eficiente de secretos con un solo Key Vault**:
   
   Una ventaja del enfoque de grupos de recursos es que podemos usar un único Key Vault con acceso controlado:
   
   ```bash
   # Crear un Key Vault compartido
   az keyvault create \
     --name "kv-$PROJECT_NAME-shared" \
     --resource-group "rg-$PROJECT_NAME-shared" \
     --location $LOCATION
   
   # Asignar políticas de acceso diferentes según el ambiente
   # Equipo de desarrollo: acceso completo a secretos de dev, solo lectura a test
   az keyvault set-policy \
     --name "kv-$PROJECT_NAME-shared" \
     --resource-group "rg-$PROJECT_NAME-shared" \
     --object-id "$DEV_TEAM_OBJECT_ID" \
     --secret-permissions get list set delete \
     --secret-permissions-for-keys get list
   
   # Equipo de operaciones: acceso completo a todos los secretos
   az keyvault set-policy \
     --name "kv-$PROJECT_NAME-shared" \
     --resource-group "rg-$PROJECT_NAME-shared" \
     --object-id "$OPS_TEAM_OBJECT_ID" \
     --secret-permissions get list set delete \
     --secret-permissions-for-keys get list
   ```

   > **BUENA PRÁCTICA**: Usa prefijos en los nombres de los secretos para distinguir entre ambientes: "dev-postgres-connection", "prod-postgres-connection".

### Estrategia de rollback y testing con grupos de recursos

1. **Despliegue gradual en el grupo de recursos de producción**:
   ```bash
   # Crear una nueva revisión y dividir el tráfico (50% a la nueva versión)
   az containerapp revision activate \
     --name api-$PROJECT_NAME \
     --resource-group "rg-$PROJECT_NAME-prod" \
     --percentage 50 50
   ```

2. **Revertir cambios rápidamente**:
   ```bash
   # Revertir a la revisión anterior en caso de problemas
   az containerapp revision list \
     --name api-$PROJECT_NAME \
     --resource-group "rg-$PROJECT_NAME-prod" \
     --query "[?!active].name" -o tsv | head -1 | xargs -I {} \
     az containerapp revision activate \
       --name api-$PROJECT_NAME \
       --resource-group "rg-$PROJECT_NAME-prod" \
       --revision {}
   ```

3. **Pruebas A/B entre grupos de recursos**:
   
   Puedes configurar Application Gateway para dirigir un porcentaje del tráfico al ambiente de pruebas antes de desplegar completamente a producción, permitiendo validar cambios con tráfico real.

> **RECOMENDACIÓN**: Aunque uses grupos de recursos separados dentro de una sola suscripción, mantén un tiempo de congelación de cambios (mínimo 24 horas) entre el despliegue en el grupo de pruebas y la promoción al grupo de producción.

---

## Preparación del entorno de trabajo

### Inicio de sesión en Azure

1. Abrir una terminal (PowerShell o Bash)
2. Ejecutar el comando de inicio de sesión:
   ```bash
   az login
   ```
3. Se abrirá un navegador para autenticarte. Inicia sesión con tus credenciales.
4. Verifica que has iniciado sesión correctamente:
   ```bash
   az account show
   ```

### Seleccionar la suscripción correcta

Si tienes múltiples suscripciones, asegúrate de estar trabajando en la correcta:

1. Listar todas las suscripciones disponibles:
   ```bash
   az account list --output table
   ```
2. Seleccionar la suscripción deseada:
   ```bash
   az account set --subscription "<ID-o-nombre-de-suscripción>"
   ```

### Configuración del entorno de trabajo

1. Crear un directorio para el proyecto:
   ```bash
   mkdir azure-containerapp-project
   cd azure-containerapp-project
   ```

2. Preparar directorios para el código:
   ```bash
   mkdir -p backend frontend infrastructure
   ```

---

## Fase 1: Infraestructura base

### Definición de variables de entorno

Para evitar errores de tipeo y facilitar la reutilización de comandos, comenzaremos definiendo variables para nuestros recursos:

```bash
# Variables principales
RESOURCE_GROUP="rg-containerapp-demo"
LOCATION="eastus"     # East US es la región más cercana a México con buena latencia
PROJECT_NAME="paymentapp"  # Nombre base para nuestros recursos

# Variables para red
VNET_NAME="vnet-$PROJECT_NAME"
SUBNET_APPGW="subnet-appgw"
SUBNET_CONTAINERAPP="subnet-containerapp"
```

> **NOTA IMPORTANTE**: Mantén un registro de estas variables en un archivo seguro, ya que las necesitarás durante todo el proceso de despliegue. Puedes crear un archivo `variables.sh` para reutilizarlas en futuras sesiones.

### Crear grupo de recursos

El grupo de recursos es un contenedor lógico para todos los recursos de Azure relacionados con este proyecto:

```bash
# Crear resource group
az group create --name $RESOURCE_GROUP --location $LOCATION
```

**Verificación**: Comprueba que el grupo de recursos se ha creado correctamente:
```bash
az group show --name $RESOURCE_GROUP
```

### Crear red virtual y subredes

La red virtual aislará nuestros recursos y permitirá comunicación segura entre ellos:

#### Explicación del espacio de direcciones 10.0.0.0/16

El valor `10.0.0.0/16` define el rango de direcciones IP privadas que estará disponible en nuestra red virtual:

- **¿Por qué 10.0.0.0/16?**
  - Este es un rango de direcciones IP privadas (no enrutables públicamente) según RFC 1918
  - El prefijo `/16` significa que tenemos disponibles 16 bits para definir hosts (2^16 = 65,536 direcciones IP)
  - Este rango va desde 10.0.0.0 hasta 10.0.255.255, proporcionando 65,536 direcciones IP
  - Es suficientemente grande para permitir múltiples subredes y futuro crecimiento

- **Beneficios de esta elección**:
  - **Espacio amplio**: Permite crear múltiples subredes sin restricciones
  - **Sin solapamiento**: Utiliza un rango que normalmente no se solapa con redes corporativas
  - **Flexibilidad para arquitectura**: Permite segmentar adecuadamente los recursos
  - **Planificación para crecimiento**: Espacio suficiente para expansiones futuras

- **Consideraciones de diseño**:
  - La subred de Application Gateway necesita al menos un rango `/24` (256 direcciones)
  - La subred de Container Apps necesita un rango más amplio `/21` (2,048 direcciones)
  - Dejamos espacio para posibles componentes adicionales (bases de datos, VMs, etc.)

```bash
# Crear VNET con espacio de direcciones 10.0.0.0/16 (65,536 direcciones IP)
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --location $LOCATION \
  --address-prefix 10.0.0.0/16
```

A continuación, crearemos dos subredes específicas dentro de la VNET, siguiendo un plan de segmentación cuidadosamente diseñado:

#### Plan de segmentación de subredes

Dividiremos el espacio 10.0.0.0/16 en subredes específicas para cada servicio, siguiendo estas prácticas:

| Servicio | Rango CIDR | Tamaño | Direcciones IP | Ubicación en VNET |
|----------|------------|--------|---------------|-------------------|
| Application Gateway | 10.0.1.0/24 | /24 | 256 | Inicio de la VNET |
| Container Apps | 10.0.8.0/21 | /21 | 2,048 | Centro de la VNET |
| [Reservado] | 10.0.0.0/24, 10.0.2.0-7.0/24 | /24 | Múltiples bloques de 256 | Varias zonas |
| [Expansión futura] | 10.0.16.0/20 y superiores | Varios | Miles | Final de la VNET |

Esta estructura permite:
- **Aislamiento por servicio**: Cada componente en su propia subred
- **Seguridad granular**: Control de tráfico entre subredes mediante NSGs
- **Espacio para crecimiento**: Amplias reservas para futuras necesidades
- **Evitar reorganizaciones**: No será necesario recrear la VNET por falta de espacio

1. Subnet para Application Gateway:
   ```bash
   az network vnet subnet create \
     --resource-group $RESOURCE_GROUP \
     --vnet-name $VNET_NAME \
     --name $SUBNET_APPGW \
     --address-prefix 10.0.1.0/24  # 256 direcciones IP (10.0.1.0 - 10.0.1.255)
   ```

   > **IMPORTANTE**: Application Gateway requiere una subred dedicada de al menos tamaño /24 ya que necesita múltiples direcciones IP para sus instancias internas, especialmente cuando se configura con alta disponibilidad o se escala horizontalmente.

2. Subnet para Container Apps:
   ```bash
   az network vnet subnet create \
     --resource-group $RESOURCE_GROUP \
     --vnet-name $VNET_NAME \
     --name $SUBNET_CONTAINERAPP \
     --address-prefix 10.0.8.0/21  # 2,048 direcciones IP (10.0.8.0 - 10.0.15.255)
   ```

   > **IMPORTANTE**: Container Apps Environment con integración VNET requiere una subred de al menos tamaño /21. Este requisito es mayor de lo normal debido a que Container Apps utiliza muchas direcciones IP internas para orquestar los contenedores, administrar la red interna de Kubernetes subyacente, y permitir el escalado automático.

**Verificación**: Lista las subredes creadas para confirmar:
```bash
az network vnet subnet list \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --output table
```

#### Consideraciones sobre el espacio de direcciones para múltiples proyectos

Si planeas tener múltiples proyectos en diferentes grupos de recursos en el futuro, es importante planificar adecuadamente los espacios de direcciones IP para evitar solapamientos:

**Análisis del espacio actual (10.0.0.0/16)**:
- Este rango proporciona 65,536 direcciones IP, lo cual es bastante amplio para un solo proyecto
- Para Container Apps estamos reservando 2,048 direcciones (/21), que podría ser excesivo en algunas situaciones
- Si se planean muchos proyectos, este enfoque podría consumir rápidamente el espacio de direcciones privadas

**Recomendaciones para múltiples proyectos**:

1. **Planificación a nivel de organización**:
   ```
   10.0.0.0/16    → Proyecto actual (Sistema de Pagos)
   10.1.0.0/16    → Proyecto futuro A
   10.2.0.0/16    → Proyecto futuro B
   172.16.0.0/16  → Proyecto futuro C (usando otro rango privado)
   ```

2. **Opción más conservadora para el proyecto actual**:
   ```bash
   # VNET más pequeña para el proyecto actual
   az network vnet create \
     --resource-group $RESOURCE_GROUP \
     --name $VNET_NAME \
     --location $LOCATION \
     --address-prefix 10.0.0.0/20  # 4,096 direcciones (suficiente y más conservador)
   
   # Subredes ajustadas
   az network vnet subnet create \
     --resource-group $RESOURCE_GROUP \
     --vnet-name $VNET_NAME \
     --name $SUBNET_APPGW \
     --address-prefix 10.0.0.0/24  # Sin cambios, 256 direcciones
   
   az network vnet subnet create \
     --resource-group $RESOURCE_GROUP \
     --vnet-name $VNET_NAME \
     --name $SUBNET_CONTAINERAPP \
     --address-prefix 10.0.8.0/22  # Reducido a 1,024 direcciones (todavía suficiente)
   ```

3. **Peering de VNET para comunicación entre proyectos**:
   - En lugar de usar VNETs superpuestas, utiliza peering de VNET para conectar proyectos
   - Cada proyecto tiene su propio espacio de direcciones no superpuesto
   - La comunicación entre VNETs se realiza mediante peering o Azure Virtual WAN

> **RECOMENDACIÓN FINAL**: Para el proyecto actual, el espacio 10.0.0.0/16 es adecuado si es el único proyecto o hay pocos proyectos planificados. Si se anticipan muchos proyectos (10+), considera reducir a 10.0.0.0/20, que todavía ofrece 4,096 direcciones IP pero es más conservador con el espacio global de direcciones privadas.

---

## Fase 2: Configuración de la base de datos PostgreSQL

### Definición de variables para PostgreSQL

```bash
# IMPORTANTE: Asegúrate que estas variables estén definidas antes de continuar
# Si ya ejecutaste la Fase 1, verifica que $RESOURCE_GROUP, $LOCATION y $PROJECT_NAME existen
POSTGRES_SERVER_NAME="pg-$PROJECT_NAME-$(date +%s)"  # Sufijo único con timestamp
POSTGRES_DB_NAME="paymentdb"
POSTGRES_ADMIN_USER="pgadmin"
POSTGRES_ADMIN_PASSWORD="YourComplexPassword123!"  # ¡Usa una contraseña segura!
POSTGRES_VERSION="14"  # Versión recomendada de PostgreSQL
```

> **ATENCIÓN DE SEGURIDAD**: En un entorno de producción real, NUNCA almacenes contraseñas en scripts. Usa Azure Key Vault o variables de entorno seguras.

### Crear servidor PostgreSQL Flexible

Azure Database for PostgreSQL ofrece dos modelos de implementación: Servidor único (legacy) y Servidor flexible (recomendado). Utilizaremos el servidor flexible por sus ventajas en alta disponibilidad, escalabilidad y mejor control:

```bash
# Crear PostgreSQL Flexible Server
az postgres flexible-server create \
  --name $POSTGRES_SERVER_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --admin-user $POSTGRES_ADMIN_USER \
  --admin-password $POSTGRES_ADMIN_PASSWORD \
  --version $POSTGRES_VERSION \
  --tier Burstable \
  --sku-name Standard_B1ms \
  --storage-size 32 \
  --high-availability Disabled \
  --yes # Confirma automáticamente la creación
```

> **NOTA**: El comando anterior abrirá una interfaz interactiva. Selecciona 'yes' cuando pregunte si quieres configurar las reglas de firewall.

### Crear la base de datos

Una vez creado el servidor, creamos la base de datos:

```bash
# Crear base de datos en el servidor PostgreSQL
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name $POSTGRES_SERVER_NAME \
  --database-name $POSTGRES_DB_NAME
```

> **NOTA DE OPTIMIZACIÓN**: Para producción, considera las siguientes optimizaciones:
> - Usar tier General Purpose (GP) en lugar de Burstable
> - Habilitar alta disponibilidad con `--high-availability Enabled`
> - Configurar backups con retención adecuada para tu RTO/RPO
> - Configurar zonas de disponibilidad con `--zone 1`

### Configurar reglas de firewall de PostgreSQL

Para permitir el acceso desde los servicios de Azure y tu IP para administración:

```bash
# Permitir acceso desde servicios de Azure
az postgres flexible-server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER_NAME \
  --rule-name "AllowAzureServices" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Permitir tu IP actual para gestión inicial
MY_IP=$(curl -s ifconfig.me)
az postgres flexible-server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER_NAME \
  --rule-name "AllowMyIP" \
  --start-ip-address $MY_IP \
  --end-ip-address $MY_IP
```

### Configurar parámetros de PostgreSQL (opcional)

Podemos optimizar algunos parámetros de PostgreSQL para un mejor rendimiento:

```bash
# Ajustar parámetros recomendados
az postgres flexible-server parameter set \
  --resource-group $RESOURCE_GROUP \
  --server-name $POSTGRES_SERVER_NAME \
  --name max_connections \
  --value 100

az postgres flexible-server parameter set \
  --resource-group $RESOURCE_GROUP \
  --server-name $POSTGRES_SERVER_NAME \
  --name shared_buffers \
  --value 16384
```

### Obtener cadena de conexión

Guarda la cadena de conexión para usarla posteriormente en la configuración de la API:

```bash
# Construir la cadena de conexión para PostgreSQL
POSTGRES_FQDN=$(az postgres flexible-server show \
  --resource-group $RESOURCE_GROUP \
  --name $POSTGRES_SERVER_NAME \
  --query "fullyQualifiedDomainName" \
  --output tsv)

# Verificar que se obtuvo el FQDN correctamente
if [ -z "$POSTGRES_FQDN" ]; then
  echo "Error: No se pudo obtener el FQDN del servidor PostgreSQL"
  echo "Usando nombre del servidor como alternativa"
  POSTGRES_FQDN="${POSTGRES_SERVER_NAME}.postgres.database.azure.com"
fi

POSTGRES_CONNECTION_STRING="Server=$POSTGRES_FQDN;Database=$POSTGRES_DB_NAME;Port=5432;User Id=$POSTGRES_ADMIN_USER;Password=$POSTGRES_ADMIN_PASSWORD;Ssl Mode=Require;"

echo "Cadena de conexión: $POSTGRES_CONNECTION_STRING"
```

> **RECUERDA**: Guarda esta cadena de conexión de forma segura. La necesitarás para configurar tu aplicación.

> **NOTA SOBRE EFICIENCIA**: PostgreSQL es ideal para aplicaciones de procesamiento de pagos debido a:
> 1. Su integridad transaccional ACID que garantiza consistencia
> 2. Excelente manejo de concurrencia
> 3. Extensiones como pg_partman para manejar grandes volúmenes de datos de transacciones
> 4. Tipos de datos JSON nativos para almacenar datos flexibles de transacciones

---

## Fase 3: Preparación de las aplicaciones

### Preparación de variables del entorno

```bash
# IMPORTANTE: Asegúrate que las variables siguientes estén definidas desde fases anteriores
# Si estás ejecutando los comandos en una nueva sesión, debes definirlas nuevamente
if [ -z "$PROJECT_NAME" ] || [ -z "$RESOURCE_GROUP" ] || [ -z "$LOCATION" ]; then
  echo "Error: Variables requeridas no están definidas. Define PROJECT_NAME, RESOURCE_GROUP y LOCATION antes de continuar."
  # Aquí podrías redefinir las variables:
  # PROJECT_NAME="payment-app"
  # RESOURCE_GROUP="rg-$PROJECT_NAME"
  # LOCATION="eastus"
fi

if [ -z "$POSTGRES_CONNECTION_STRING" ]; then
  echo "Advertencia: POSTGRES_CONNECTION_STRING no está definida. Será necesaria para configurar la API."
fi
```

### Estructuración del código fuente

Asegúrate de tener las aplicaciones organizadas de la siguiente manera:

```
azure-containerapp-project/
├── backend/           # API ASP.NET Core
├── frontend/          # Aplicación React
└── infrastructure/    # Scripts y configuraciones
```

### Preparación del backend (ASP.NET Core API)

1. Navega al directorio backend:
   ```bash
   cd backend
   ```

2. Crea un archivo Dockerfile para la API:
   ```dockerfile
   FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
   WORKDIR /app
   EXPOSE 8080
   
   FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
   WORKDIR /src
   COPY ["PaymentAPI.csproj", "./"]
   RUN dotnet restore "PaymentAPI.csproj"
   COPY . .
   RUN dotnet build "PaymentAPI.csproj" -c Release -o /app/build
   
   FROM build AS publish
   RUN dotnet publish "PaymentAPI.csproj" -c Release -o /app/publish
   
   FROM base AS final
   WORKDIR /app
   COPY --from=publish /app/publish .
   # Configuración para múltiples instancias
   ENV ASPNETCORE_URLS=http://+:8080
   ENTRYPOINT ["dotnet", "PaymentAPI.dll"]
   ```

3. Asegúrate de tener un archivo appsettings.json con la siguiente configuración:
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Server=pg-paymentapp.postgres.database.azure.com;Database=paymentdb;Port=5432;User Id=pgadmin;Password=YourPassword;Ssl Mode=Require;"
     },
     "Logging": {
       "LogLevel": {
         "Default": "Information",
         "Microsoft": "Warning",
         "Microsoft.Hosting.Lifetime": "Information"
       }
     },
     "AllowedHosts": "*",
     "CorsSettings": {
       "AllowedOrigins": ["*"]
     }
   }
   ```

4. Crea un endpoint de health check en tu API:
   ```csharp
   // En Program.cs o Startup.cs
   app.MapGet("/api/health", () => "Healthy");
   ```

### Preparación del frontend (React)

1. Navega al directorio frontend:
   ```bash
   cd ../frontend
   ```

2. Crea un archivo Dockerfile para el frontend:
   ```dockerfile
   # Etapa de compilación
   FROM node:18-alpine AS build
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci
   COPY . .
   # Configurar variables de entorno para producción
   ARG API_URL=/api
   ENV REACT_APP_API_BASE_URL=$API_URL
   RUN npm run build

   # Etapa de producción
   FROM nginx:alpine
   # Copiar configuración de nginx optimizada para SPA
   COPY nginx.conf /etc/nginx/conf.d/default.conf
   COPY --from=build /app/build /usr/share/nginx/html
   EXPOSE 80
   # Iniciar nginx en modo no-daemon
   CMD ["nginx", "-g", "daemon off;"]
   ```

3. Crea un archivo nginx.conf para configurar Nginx:
   ```nginx
   server {
     listen 80;
     
     location / {
       root /usr/share/nginx/html;
       index index.html index.htm;
       try_files $uri $uri/ /index.html;
     }
     
     # Configuración para redireccionar peticiones API
     location /api {
       proxy_pass http://localhost:8080;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection 'upgrade';
       proxy_set_header Host $host;
       proxy_cache_bypass $http_upgrade;
     }
   }
   ```

4. Asegúrate de configurar un archivo .env para la aplicación React:
   ```
   REACT_APP_API_BASE_URL=/api
   ```

### Selección y configuración del registro de contenedores

Tienes dos opciones para almacenar tus imágenes: Azure Container Registry (ACR) o GitHub Container Registry (GHCR). Para este tutorial, mostraremos ambas opciones:

#### Opción A: GitHub Container Registry (Recomendado por costo)

1. Requisitos:
   - Cuenta de GitHub
   - Token de acceso personal (PAT) con permisos `write:packages`

2. Definición de variables:
   ```bash
   GH_USERNAME="tu-usuario-github"
   GH_TOKEN="tu-personal-access-token"  # Token con permisos write:packages
   GH_REGISTRY="ghcr.io"
   ```

3. Iniciar sesión en GitHub Container Registry:
   ```bash
   echo $GH_TOKEN | docker login ghcr.io -u $GH_USERNAME --password-stdin
   ```

4. Construir y etiquetar imágenes:
   ```bash
   # Construir la imagen de la API
   cd ../backend
   docker build -t $GH_REGISTRY/$GH_USERNAME/payment-api:latest .

   # Construir la imagen del frontend
   cd ../frontend
   docker build -t $GH_REGISTRY/$GH_USERNAME/payment-frontend:latest .
   ```

5. Subir imágenes a GitHub Container Registry:
   ```bash
   docker push $GH_REGISTRY/$GH_USERNAME/payment-api:latest
   docker push $GH_REGISTRY/$GH_USERNAME/payment-frontend:latest
   
   # Guardar las URLs completas para uso posterior
   BACKEND_IMAGE="$GH_REGISTRY/$GH_USERNAME/payment-api:latest"
   FRONTEND_IMAGE="$GH_REGISTRY/$GH_USERNAME/payment-frontend:latest"
   ```

#### Opción B: Azure Container Registry

1. Definición de variables:
   ```bash
   ACR_NAME="acr${PROJECT_NAME}$(date +%s)"  # Nombre único para el registro
   ```

2. Crear el registro:
   ```bash
   az acr create \
     --resource-group $RESOURCE_GROUP \
     --name $ACR_NAME \
     --sku Basic \
     --admin-enabled true
   ```

3. Obtener credenciales:
   ```bash
   ACR_USERNAME=$ACR_NAME
   ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv)
   ```

4. Iniciar sesión en ACR:
   ```bash
   az acr login --name $ACR_NAME
   ```

5. Construir y etiquetar imágenes:
   ```bash
   # Construir la imagen de la API
   cd ../backend
   docker build -t $ACR_NAME.azurecr.io/payment-api:latest .

   # Construir la imagen del frontend
   cd ../frontend
   docker build -t $ACR_NAME.azurecr.io/payment-frontend:latest .
   ```

6. Subir imágenes a ACR:
   ```bash
   docker push $ACR_NAME.azurecr.io/payment-api:latest
   docker push $ACR_NAME.azurecr.io/payment-frontend:latest
   
   # Guardar las URLs completas para uso posterior
   BACKEND_IMAGE="$ACR_NAME.azurecr.io/payment-api:latest"
   FRONTEND_IMAGE="$ACR_NAME.azurecr.io/payment-frontend:latest"
   ```

---

## Fase 4: Despliegue en Container Apps

### Crear Container Apps Environment

El environment es el entorno compartido donde se ejecutarán las Container Apps:

```bash
# IMPORTANTE: Verifica que las variables necesarias estén definidas
if [ -z "$PROJECT_NAME" ] || [ -z "$RESOURCE_GROUP" ] || [ -z "$LOCATION" ]; then
  echo "Error: Variables requeridas no están definidas. Define PROJECT_NAME, RESOURCE_GROUP y LOCATION."
  # PROJECT_NAME="payment-app"
  # RESOURCE_GROUP="rg-$PROJECT_NAME"
  # LOCATION="eastus"
fi

# Definir variables para el environment
CONTAINERAPP_ENV_NAME="env-$PROJECT_NAME"
LOG_ANALYTICS_WORKSPACE="log-$PROJECT_NAME"

# Crear environment con integración VNET
az containerapp env create \
  --name $CONTAINERAPP_ENV_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --infrastructure-subnet-resource-id "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/$SUBNET_CONTAINERAPP" \
  --internal-only true
```

> **IMPORTANTE**: La opción `--internal-only true` garantiza que las Container Apps sean accesibles únicamente dentro de la VNET, no directamente desde internet. El Application Gateway será el punto de entrada público.

### Desplegar la API backend

Ahora desplegaremos la aplicación API en Container Apps:

```bash
# Definir nombre para la API
API_CONTAINERAPP_NAME="app-payment-api"

# Si estás usando GitHub Container Registry:
az containerapp create \
  --name $API_CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPP_ENV_NAME \
  --image $BACKEND_IMAGE \
  --registry-server $GH_REGISTRY \
  --registry-username $GH_USERNAME \
  --registry-password $GH_TOKEN \
  --target-port 8080 \
  --ingress internal \
  --min-replicas 1 \
  --max-replicas 5 \
  --cpu 0.5 \
  --memory 1Gi \
  --env-vars "ConnectionStrings__DefaultConnection=$POSTGRES_CONNECTION_STRING" "ASPNETCORE_ENVIRONMENT=Production" \
  --query properties.configuration.ingress.fqdn

# O si estás usando Azure Container Registry:
az containerapp create \
  --name $API_CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPP_ENV_NAME \
  --image $BACKEND_IMAGE \
  --registry-server "$ACR_NAME.azurecr.io" \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --target-port 8080 \
  --ingress internal \
  --min-replicas 1 \
  --query properties.configuration.ingress.fqdn \
  --max-replicas 5 \
  --cpu 0.5 \
  --memory 1Gi \
  --env-vars "ConnectionStrings__DefaultConnection=$POSTGRES_CONNECTION_STRING" "ASPNETCORE_ENVIRONMENT=Production"
```

> **NOTA DE SEGURIDAD**: En un entorno de producción, es recomendable usar Azure Key Vault para almacenar la cadena de conexión y otras secretos, y usar identidades administradas para el acceso.

### Desplegar el frontend React

A continuación, desplegaremos la aplicación frontend:

```bash
# Definir nombre para el frontend
FRONTEND_CONTAINERAPP_NAME="app-payment-frontend"

# Si estás usando GitHub Container Registry:
az containerapp create \
  --name $FRONTEND_CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPP_ENV_NAME \
  --image $FRONTEND_IMAGE \
  --registry-server $GH_REGISTRY \
  --registry-username $GH_USERNAME \
  --registry-password $GH_TOKEN \
  --target-port 80 \
  --ingress internal \
  --min-replicas 0 \  # Puede escalar a cero cuando no hay tráfico
  --max-replicas 3 \
  --cpu 0.25 \
  --memory 0.5Gi \
  --env-vars "REACT_APP_API_BASE_URL=/api" "NODE_ENV=production"

# O si estás usando Azure Container Registry:
az containerapp create \
  --name $FRONTEND_CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPP_ENV_NAME \
  --image $FRONTEND_IMAGE \
  --registry-server "$ACR_NAME.azurecr.io" \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --target-port 80 \
  --ingress internal \
  --min-replicas 0 \  # Puede escalar a cero cuando no hay tráfico
  --max-replicas 3 \
  --cpu 0.25 \
  --memory 0.5Gi \
  --env-vars "REACT_APP_API_BASE_URL=/api" "NODE_ENV=production"
```

> **NOTA DE OPTIMIZACIÓN**: Hemos configurado `min-replicas 0` para el frontend, lo que permite escalar a cero cuando no hay tráfico, ahorrando costos.

### Obtener FQDN internos

Necesitamos los FQDN (Fully Qualified Domain Names) internos para configurar el Application Gateway:

```bash
# Obtener FQDN del API
API_FQDN=$(az containerapp show \
  --name $API_CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

echo "API Container App FQDN: $API_FQDN"

# Obtener FQDN del Frontend
FRONTEND_FQDN=$(az containerapp show \
  --name $FRONTEND_CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

echo "Frontend Container App FQDN: $FRONTEND_FQDN"
```

> **IMPORTANTE**: Asegúrate de guardar estos FQDN ya que los necesitaremos en la siguiente fase.

---

## Fase 5: Configuración de Application Gateway

### Crear IP pública

Primero, necesitamos una dirección IP pública para nuestro Application Gateway:

```bash
APPGW_PUBLIC_IP_NAME="pip-$PROJECT_NAME-appgw"

az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name $APPGW_PUBLIC_IP_NAME \
  --allocation-method Static \
  --sku Standard
```

### Crear Application Gateway

Ahora crearemos el Application Gateway con configuración básica:

```bash
APPGW_NAME="appgw-$PROJECT_NAME"

az network application-gateway create \
  --name $APPGW_NAME \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_APPGW \
  --capacity 2 \
  --sku WAF_v2 \  # Usamos el SKU con WAF incluido
  --public-ip-address $APPGW_PUBLIC_IP_NAME \
  --frontend-port 80 \
  --routing-rule-type Basic
```

> **NOTA**: La creación del Application Gateway puede tomar unos 15-20 minutos. Es un buen momento para tomar un café ☕.

### Configurar backend pools para API y Frontend

Configuramos pools separados para cada servicio:

```bash
# Backend pool para API
az network application-gateway address-pool create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "api-backend-pool" \
  --servers $API_FQDN

# Backend pool para Frontend
az network application-gateway address-pool create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "frontend-backend-pool" \
  --servers $FRONTEND_FQDN
```

### Configurar health probes

Las health probes verifican regularmente que los servicios están funcionando correctamente:

```bash
# Health probe para API
az network application-gateway probe create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "api-health-probe" \
  --protocol Http \
  --host-name-from-http-settings true \
  --path "/api/health" \
  --interval 30 \
  --timeout 30 \
  --threshold 3

# Health probe para Frontend
az network application-gateway probe create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "frontend-health-probe" \
  --protocol Http \
  --host-name-from-http-settings true \
  --path "/" \
  --interval 30 \
  --timeout 30 \
  --threshold 3
```

### Configurar HTTP Settings

Estos ajustes definen cómo el Application Gateway se comunica con los backends:

```bash
# HTTP Settings para API
az network application-gateway http-settings create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "api-http-settings" \
  --port 443 \
  --protocol Https \
  --cookie-based-affinity Disabled \
  --host-name-from-backend-pool true \
  --probe "api-health-probe"

# HTTP Settings para Frontend con optimización para activos estáticos
az network application-gateway http-settings create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "frontend-http-settings" \
  --port 443 \
  --protocol Https \
  --cookie-based-affinity Disabled \
  --host-name-from-backend-pool true \
  --probe "frontend-health-probe"
```

### Configurar Path-Based Routing

Este es un paso crucial que configura el enrutamiento basado en rutas URL:

```bash
# Crear URL Path Map
az network application-gateway url-path-map create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "app-routing" \
  --paths "/api/*" \
  --address-pool "api-backend-pool" \
  --http-settings "api-http-settings" \
  --default-address-pool "frontend-backend-pool" \
  --default-http-settings "frontend-http-settings"
```

> **EXPLICACIÓN**: Esta configuración enruta todas las peticiones que comienzan con "/api/" al backend de la API, mientras que cualquier otra ruta se dirige al frontend React.

### Configurar regla de routing basada en Path

Ahora conectamos nuestro path map con un listener HTTP:

```bash
# Crear listener HTTP
az network application-gateway http-listener create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "http-listener" \
  --frontend-port appGatewayFrontendPort \
  --frontend-ip appGatewayFrontendIP

# Crear regla de routing
az network application-gateway rule create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "path-based-routing-rule" \
  --rule-type PathBasedRouting \
  --http-listener "http-listener" \
  --url-path-map "app-routing" \
  --priority 100
```

### Configurar TLS/SSL (Recomendado para producción)

Para entornos de producción, es esencial configurar HTTPS:

```bash
# Para producción, usa un certificado real de una CA
# Este ejemplo usa un certificado autofirmado solo para desarrollo

# 1. Crear certificado autofirmado
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -out appgw.crt -keyout appgw.key -subj "/CN=payment-app.example.com"
openssl pkcs12 -export -out appgw.pfx -inkey appgw.key -in appgw.crt -passout pass:YourSecurePassword

# 2. Importar certificado al Application Gateway
az network application-gateway ssl-cert create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "appgw-ssl-cert" \
  --cert-file "appgw.pfx" \
  --cert-password "YourSecurePassword"

# 3. Crear listener HTTPS
az network application-gateway http-listener create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "https-listener" \
  --frontend-port 443 \
  --frontend-ip appGatewayFrontendIP \
  --ssl-cert "appgw-ssl-cert"

# 4. Crear regla para HTTPS
az network application-gateway rule create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "https-routing-rule" \
  --rule-type PathBasedRouting \
  --http-listener "https-listener" \
  --url-path-map "app-routing" \
  --priority 90
```

> **NOTA PARA PRODUCCIÓN**: Para un entorno de producción, deberías utilizar un certificado SSL válido emitido por una Autoridad Certificadora (CA) o usar Azure App Service Certificates.

---

## Fase 6: Configuración de WAF

### Habilitar y configurar Web Application Firewall

El WAF protege tu aplicación contra vulnerabilidades comunes como SQL Injection, XSS, etc.:

```bash
WAF_POLICY_NAME="waf-policy-$PROJECT_NAME"

# Crear WAF Policy
az network application-gateway waf-policy create \
  --resource-group $RESOURCE_GROUP \
  --name $WAF_POLICY_NAME \
  --location $LOCATION \
  --mode Detection  # Comenzar en modo detección para evitar bloqueos falsos positivos

# Configurar reglas administradas (OWASP 3.1)
az network application-gateway waf-policy managed-rule-set add \
  --resource-group $RESOURCE_GROUP \
  --policy-name $WAF_POLICY_NAME \
  --type OWASP \
  --version 3.1

# Aplicar política al Application Gateway
az network application-gateway update \
  --resource-group $RESOURCE_GROUP \
  --name $APPGW_NAME \
  --waf-policy $WAF_POLICY_NAME
```

> **RECOMENDACIÓN DE SEGURIDAD**: Inicialmente configura el WAF en modo "Detection" para monitorear el tráfico sin bloquear peticiones. Después de una semana de validación, cámbialo a modo "Prevention".

---

## Fase 7: Testing y validación

### Obtener la dirección IP pública

```bash
APPGW_PUBLIC_IP=$(az network public-ip show \
  --resource-group $RESOURCE_GROUP \
  --name $APPGW_PUBLIC_IP_NAME \
  --query ipAddress \
  --output tsv)

echo "Application Gateway Public IP: $APPGW_PUBLIC_IP"
echo "Test URL: http://$APPGW_PUBLIC_IP"
```

### Testing del frontend

1. Abre un navegador web y visita:
   ```
   http://<APPGW_PUBLIC_IP>/
   ```
   
2. Deberías ver la interfaz de usuario de React.

### Testing de la API

1. Prueba un endpoint de la API:
   ```bash
   curl -X GET http://$APPGW_PUBLIC_IP/api/health
   ```

2. Verifica la respuesta exitosa (deberías ver "Healthy").

### Validación de enrutamiento

1. Prueba los endpoints de la API:
   ```bash
   # Debería devolver datos JSON
   curl -X GET http://$APPGW_PUBLIC_IP/api/v1/payments
   ```

2. Confirma que el frontend sirve archivos estáticos:
   ```bash
   # Verifica que recibas HTML
   curl -I http://$APPGW_PUBLIC_IP/
   ```

3. Verifica que el enrutamiento sea correcto:
   ```bash
   # Este debe ser manejado por React (código HTML)
   curl -I http://$APPGW_PUBLIC_IP/dashboard
   
   # Este debe ser manejado por la API (.NET Core)
   curl -I http://$APPGW_PUBLIC_IP/api/v1/status
   ```

---

## Fase 8: Monitoreo y alertas

### Configurar Log Analytics Workspace

```bash
LOG_ANALYTICS_NAME="law-$PROJECT_NAME"

# Crear Log Analytics Workspace
az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $LOG_ANALYTICS_NAME \
  --location $LOCATION \
  --sku PerGB2018  # Pago por GB ingerido
```

### Habilitar diagnósticos para Application Gateway

```bash
# Para Application Gateway
az monitor diagnostic-settings create \
  --name "appgw-diagnostics" \
  --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/applicationGateways/$APPGW_NAME" \
  --workspace "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/$LOG_ANALYTICS_NAME" \
  --logs '[{"category":"ApplicationGatewayAccessLog","enabled":true},{"category":"ApplicationGatewayPerformanceLog","enabled":true},{"category":"ApplicationGatewayFirewallLog","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]'
```

### Habilitar diagnósticos para Container Apps

```bash
# Para la API Container App
az monitor diagnostic-settings create \
  --name "containerapp-api-diagnostics" \
  --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.App/containerApps/$API_CONTAINERAPP_NAME" \
  --workspace "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/$LOG_ANALYTICS_NAME" \
  --logs '[{"category":"ContainerAppConsoleLogs","enabled":true},{"category":"ContainerAppSystemLogs","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]'

# Para el Frontend Container App
az monitor diagnostic-settings create \
  --name "containerapp-frontend-diagnostics" \
  --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.App/containerApps/$FRONTEND_CONTAINERAPP_NAME" \
  --workspace "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/$LOG_ANALYTICS_NAME" \
  --logs '[{"category":"ContainerAppConsoleLogs","enabled":true},{"category":"ContainerAppSystemLogs","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]'
```

### Configurar alertas

```bash
# Crear grupo de acciones para notificaciones
az monitor action-group create \
  --name "ag-$PROJECT_NAME-critical" \
  --resource-group $RESOURCE_GROUP \
  --short-name "Critical" \
  --email-receiver name="Admin" email="admin@example.com"

# Alerta para latencia alta en Application Gateway
az monitor metrics alert create \
  --name "appgw-high-latency" \
  --resource-group $RESOURCE_GROUP \
  --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/applicationGateways/$APPGW_NAME" \
  --condition "avg LatencyInMilliSeconds > 1000" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Insights/actionGroups/ag-$PROJECT_NAME-critical" \
  --description "Alert when Application Gateway latency is high"

# Alerta para alta utilización de CPU en API
az monitor metrics alert create \
  --name "api-high-cpu" \
  --resource-group $RESOURCE_GROUP \
  --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.App/containerApps/$API_CONTAINERAPP_NAME" \
  --condition "avg CpuUtilization > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Insights/actionGroups/ag-$PROJECT_NAME-critical" \
  --description "Alert when API CPU usage is high"
```

### Configurar dashboard de monitoreo

Para facilitar la visualización de métricas, puedes crear un dashboard en Azure Portal:

1. Ve a Azure Portal
2. Busca "Dashboards" y crea uno nuevo
3. Añade widgets para:
   - Métricas de Application Gateway (Latency, Throughput, Failed Requests)
   - Métricas de Container Apps (CPU, Memory)
   - Logs de WAF (posibles ataques)
   - Estado de las health probes

---

## Troubleshooting común

### Problema 1: 502 Bad Gateway

**Posibles causas y soluciones:**

1. **Health probe fallando**:
   - Verifica que los endpoints de health configurados (/api/health y /) respondan correctamente:
     ```bash
     # Verificar API health desde dentro de la VNET
     az container create \
       --name troubleshoot-container \
       --resource-group $RESOURCE_GROUP \
       --image mcr.microsoft.com/azure-cli \
       --vnet $VNET_NAME \
       --subnet $SUBNET_CONTAINERAPP \
       --command-line "curl -v $API_FQDN/api/health"
     ```

2. **Problemas con la integración VNET**:
   - Verifica que las subredes estén correctamente configuradas
   - Comprueba que no haya NSGs bloqueando el tráfico entre subnets

3. **Problemas con el FQDN interno**:
   - Verifica que el FQDN interno resoluble dentro de la VNET:
     ```bash
     az container create \
       --name dns-test-container \
       --resource-group $RESOURCE_GROUP \
       --image mcr.microsoft.com/azure-cli \
       --vnet $VNET_NAME \
       --subnet $SUBNET_CONTAINERAPP \
       --command-line "nslookup $API_FQDN"
     ```

### Problema 2: Errores de timeout

**Posibles causas y soluciones:**

1. **Timeouts en Application Gateway**:
   - Aumentar timeout settings:
     ```bash
     az network application-gateway http-settings update \
       --gateway-name $APPGW_NAME \
       --resource-group $RESOURCE_GROUP \
       --name "api-http-settings" \
       --connection-draining-timeout 60 \
       --timeout 120
     ```

2. **Timeouts en la API**:
   - Verificar tiempos de respuesta de la API directamente:
     ```bash
     # Dentro de la VNET
     time curl $API_FQDN/api/endpoint-lento
     ```
   - Analizar posibles cuellos de botella en la base de datos

### Problema 3: Problemas con certificados SSL

**Posibles causas y soluciones:**

1. **Certificado expirado o malformado**:
   - Verificar fecha de expiración:
     ```bash
     openssl x509 -in appgw.crt -text -noout | grep -i "not after"
     ```
   - Regenerar e importar un nuevo certificado

2. **Problemas con la cadena de certificados**:
   - Asegurarse de incluir certificados intermedios si es necesario

### Problema 4: Problemas de conexión a PostgreSQL

**Posibles causas y soluciones:**

1. **Reglas de firewall de PostgreSQL Server**:
   - Verificar que las reglas permitan el tráfico desde Container Apps:
     ```bash
     az postgres server firewall-rule list \
       --resource-group $RESOURCE_GROUP \
       --server $POSTGRES_SERVER_NAME \
       --output table
     ```
   - Añadir regla si es necesario

2. **Cadena de conexión incorrecta**:
   - Revisar las variables de entorno de la Container App:
     ```bash
     az containerapp show \
       --name $API_CONTAINERAPP_NAME \
       --resource-group $RESOURCE_GROUP \
       --query "properties.template.containers[0].env"
     ```
   - Actualizar si es necesario

---

## Optimizaciones y buenas prácticas

### Seguridad

1. **Managed Identity**:
   - Usar identidades administradas para autenticación:
     ```bash
     az containerapp identity assign \
       --name $API_CONTAINERAPP_NAME \
       --resource-group $RESOURCE_GROUP \
       --system-assigned
     ```

2. **Azure Key Vault**:
   - Almacenar secretos (como contraseñas) en Key Vault:
     ```bash
     # Crear Key Vault
     az keyvault create \
       --name "kv-$PROJECT_NAME" \
       --resource-group $RESOURCE_GROUP \
       --location $LOCATION
     
     # Añadir secreto
     az keyvault secret set \
       --vault-name "kv-$PROJECT_NAME" \
       --name "PostgresConnectionString" \
       --value "$POSTGRES_CONNECTION_STRING"
     ```

3. **Network Security Groups**:
   - Añadir NSGs para control granular:
     ```bash
     # Crear NSG para la subred de Container Apps
     az network nsg create \
       --resource-group $RESOURCE_GROUP \
       --name "nsg-containerapp"
     
     # Aplicar NSG a la subred
     az network vnet subnet update \
       --resource-group $RESOURCE_GROUP \
       --vnet-name $VNET_NAME \
       --name $SUBNET_CONTAINERAPP \
       --network-security-group "nsg-containerapp"
     ```

4. **CORS en API**:
   - Configurar CORS específico en lugar de permitir cualquier origen

### Rendimiento

1. **Auto-scaling**:
   - Configurar reglas de escala basadas en métricas:
     ```bash
     # Ejemplo: escalar basado en CPU
     az containerapp update \
       --name $API_CONTAINERAPP_NAME \
       --resource-group $RESOURCE_GROUP \
       --scale-rule-name "cpu-scaling" \
       --scale-rule-type cpu \
       --scale-rule-metadata type=Utilization value=70
     ```

2. **Cachés**:
   - Implementar caché Redis para datos frecuentemente accedidos:
     ```bash
     # Crear Azure Cache for Redis
     az redis create \
       --name "redis-$PROJECT_NAME" \
       --resource-group $RESOURCE_GROUP \
       --location $LOCATION \
       --sku Basic \
       --vm-size c0
     ```

3. **CDN para frontend**:
   - Considerar Azure CDN para assets estáticos

### Costos

1. **Escala a cero**:
   - Ya configurada para el frontend, considerar para entornos de desarrollo
  
2. **PostgreSQL Database**:
   - Considerar tier serverless para cargas variables:
     ```bash
     az postgres flexible-server update \
       --resource-group $RESOURCE_GROUP \
       --name $POSTGRES_SERVER_NAME \
       --sku-name Standard_D4s_v3 \
       --tier GeneralPurpose \
       --capacity 2 \
       --compute-model Serverless \
       --auto-pause-delay 60
     ```

3. **Application Gateway**:
   - En entornos de desarrollo, usar el SKU Standard en lugar de WAF_v2

4. **Container Registry**:
   - Usar GitHub Container Registry para ahorro de costos

### Backup y DR

1. **PostgreSQL Database Backup**:
   - Configurar backup de largo plazo:
     ```bash
     # Configurar política de backups para PostgreSQL Flexible Server
     az postgres flexible-server backup update \
       --resource-group $RESOURCE_GROUP \
       --name $POSTGRES_SERVER_NAME \
       --backup-retention $BACKUP_RETENTION_DAYS \
       --geo-redundant-backup $GEO_REDUNDANT_BACKUP \
       --week-of-year 1
     ```

2. **IaC (Infrastructure as Code)**:
   - Mantener todos los comandos en scripts para recrear la infraestructura:
     ```bash
     # Guardar los comandos en un archivo
     cat > deploy-infrastructure.sh << 'EOF'
     #!/bin/bash
     # [Todos los comandos de creación de infraestructura]
     EOF
     
     chmod +x deploy-infrastructure.sh
     ```

---

## Recursos adicionales

### Documentación oficial

- [Azure Container Apps](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Application Gateway](https://learn.microsoft.com/en-us/azure/application-gateway/)
- [Azure Database for PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/)
- [Web Application Firewall](https://learn.microsoft.com/en-us/azure/web-application-firewall/)

### Ejemplos de código y plantillas

- [Ejemplos de Container Apps en GitHub](https://github.com/Azure-Samples/container-apps-store-api-microservice)
- [Plantillas ARM para Application Gateway](https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.network/application-gateway-create)

### Herramientas útiles

- [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
- [Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/)
- [Azure Monitor Metrics Explorer](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/metrics-getting-started)

---

## Notas finales

Este documento ha sido preparado como una guía completa y detallada para implementar una arquitectura moderna de aplicación web utilizando Azure Container Apps, Application Gateway, y PostgreSQL Database. La arquitectura ha sido optimizada para seguridad, rendimiento y costo.

Recuerda siempre adaptar los pasos a tus necesidades específicas y mantener actualizados los servicios Azure y sus respectivas prácticas recomendadas.

---

© 2025 - Guía de Implementación Técnica - Versión 1.0
