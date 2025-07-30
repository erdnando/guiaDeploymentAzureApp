# Guía de Despliegue - Sistema de Pagos Azure

> **📋 Sobre esta guía**: Este documento es para **despliegue rápido**. Si eres principiante en ARM Templates, considera usar primero la [guía educativa completa](plantillas_arm_azure.md) para entender los conceptos.

## Introducción

Esta guía te llevará paso a paso para desplegar un sistema de pagos completo en Azure utilizando Container Apps, Application Gateway y PostgreSQL. El proceso está automatizado con scripts que simplifican la configuración.

### 🏗️ Arquitectura Desplegada
```
Internet → Application Gateway (WAF v2) → Container Apps (Frontend/Backend) → PostgreSQL Flexible Server
                    ↓
              Log Analytics ← Application Insights
```

## Pre-requisitos

### Software Requerido

1. **Azure CLI** (versión 2.50+)
   ```bash
   # Instalar en Linux/macOS
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   
   # Verificar instalación
   az --version
   ```

2. **Git** (para clonar el repositorio)
   ```bash
   git --version
   ```

3. **jq** (para validación JSON - opcional pero recomendado)
   ```bash
   # Ubuntu/Debian
   sudo apt-get install jq
   
   # macOS
   brew install jq
   ```

### Cuentas y Servicios

1. **Suscripción de Azure** activa
2. **GitHub Account** (para Container Registry)
3. **GitHub Personal Access Token** con permisos de packages

### Recursos Mínimos en Azure

- **Suscripción con permisos de Contributor**
- **Quotas suficientes**:
  - vCPUs: 4+ (para Container Apps y PostgreSQL)
  - Public IPs: 1 (para Application Gateway)
  - Application Gateways: 1

## Configuración Inicial

### Paso 1: Autenticación en Azure

```bash
# ▶️ EJECUTAR: Iniciar sesión
az login

# ▶️ EJECUTAR: Verificar suscripción
az account show

# ▶️ EJECUTAR: Cambiar suscripción si es necesario
az account set --subscription "tu-suscripcion-id"
```

### Paso 2: Configurar GitHub Container Registry

1. **Crear Personal Access Token**:
   - Ve a GitHub → Settings → Developer settings → Personal access tokens
   - Genera un token con permisos `read:packages` y `write:packages`
   - Guarda el token de forma segura

2. **Preparar imágenes de contenedor** (opcional para testing):
   ```bash
   # Ejemplo con imágenes públicas para testing
   docker pull nginx:alpine
   docker pull node:18-alpine
   
   # Tag para tu registry
   docker tag nginx:alpine ghcr.io/tu-usuario/payment-frontend:latest
   docker tag node:18-alpine ghcr.io/tu-usuario/payment-api:latest
   
   # Push a GitHub Container Registry
   echo "tu-github-token" | docker login ghcr.io -u tu-usuario --password-stdin
   docker push ghcr.io/tu-usuario/payment-frontend:latest
   docker push ghcr.io/tu-usuario/payment-api:latest
   ```

### Paso 3: Descargar y Configurar el Proyecto

```bash
# Clonar o descargar el proyecto
git clone <tu-repositorio>
cd azure-arm-deployment

# O si descargaste los archivos
cd azure-arm-deployment
```

### Paso 4: Configurar Variables de Entorno

#### Para Linux/macOS:

```bash
# Editar variables
nano scripts/variables.sh

# Cambiar estos valores obligatoriamente:
export REGISTRY_USERNAME="tu-usuario-github"          # Tu usuario de GitHub
export REGISTRY_PASSWORD="tu-github-token"            # Tu token de GitHub
export ALERT_EMAIL="tu-email@empresa.com"             # Tu email para alertas

# Opcional - personalizar otros valores:
export PROJECT_NAME="paymentapp"                      # Nombre de tu proyecto
export ENVIRONMENT="dev"                              # dev, test, prod
export LOCATION="eastus"                              # Región de Azure
```

#### Para Windows PowerShell:

```powershell
# Editar variables
notepad scripts\variables.ps1

# Cambiar los mismos valores que en Linux
```

## Proceso de Despliegue

### Opción 1: Despliegue Automatizado (Recomendado)

```bash
# ▶️ EJECUTAR: Validar configuración y templates
./scripts/validate.sh

# ▶️ EJECUTAR: Si la validación es exitosa, desplegar
./scripts/deploy.sh
```

### Opción 2: Despliegue Manual Paso a Paso

```bash
# ▶️ EJECUTAR: Cargar variables
source scripts/variables.sh

# ▶️ EJECUTAR: Crear Resource Group
az group create --name "$RESOURCE_GROUP" --location "$LOCATION"

# ▶️ EJECUTAR: Desplegar templates en orden
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file templates/01-infrastructure.json \
  --parameters @parameters/01-infrastructure.dev.json

# ▶️ EJECUTAR: Continuar con PostgreSQL
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file templates/02-postgresql.json \
  --parameters @parameters/02-postgresql.dev.json

# 📖 NOTA: Continuar con los demás templates en orden (03-06)
```

## Verificación del Despliegue

### Paso 1: Verificar Recursos en Azure Portal

1. Ve a [Azure Portal](https://portal.azure.com)
2. Busca tu Resource Group (ej: `rg-paymentapp-dev`)
3. Verifica que existen estos recursos:
   - Application Gateway
   - Container Apps Environment
   - 2 Container Apps (frontend y backend)
   - PostgreSQL Flexible Server
   - Log Analytics Workspace
   - Application Insights

### Paso 2: Probar Conectividad

```bash
# ▶️ EJECUTAR: Obtener IP del Application Gateway
APP_GW_IP=$(az network public-ip show \
  --resource-group "$RESOURCE_GROUP" \
  --name "pip-appgw-$PROJECT_NAME-$ENVIRONMENT" \
  --query "ipAddress" --output tsv)

echo "Application Gateway IP: $APP_GW_IP"

# ▶️ EJECUTAR: Probar conectividad
curl -I http://$APP_GW_IP
```

### Paso 3: Verificar Container Apps

```bash
# Obtener URLs de las Container Apps
az containerapp list \
  --resource-group "$RESOURCE_GROUP" \
  --query "[].{Name:name,URL:properties.configuration.ingress.fqdn}" \
  --output table
```

### Paso 4: Verificar PostgreSQL

```bash
# Probar conexión a PostgreSQL
az postgres flexible-server connect \
  --name "$POSTGRES_SERVER_NAME" \
  --admin-user "$POSTGRES_ADMIN_USER" \
  --database-name "$POSTGRES_DB_NAME"
```

## Configuración Post-Despliegue

### Configurar Aplicación

1. **Actualizar cadenas de conexión** en tu aplicación:
   ```bash
   # Obtener cadena de conexión de PostgreSQL
   az postgres flexible-server show-connection-string \
     --server-name "$POSTGRES_SERVER_NAME" \
     --database-name "$POSTGRES_DB_NAME" \
     --admin-user "$POSTGRES_ADMIN_USER"
   ```

2. **Configurar variables de entorno** en Container Apps:
   ```bash
   # Ejemplo para el backend
   az containerapp update \
     --name "ca-payment-api-$ENVIRONMENT" \
     --resource-group "$RESOURCE_GROUP" \
     --set-env-vars DATABASE_URL="postgresql://user:pass@server:5432/db"
   ```

### Configurar Dominio Personalizado (Opcional)

```bash
# Obtener IP del Application Gateway
APP_GW_IP=$(az network public-ip show \
  --resource-group "$RESOURCE_GROUP" \
  --name "pip-appgw-$PROJECT_NAME-$ENVIRONMENT" \
  --query "ipAddress" --output tsv)

# Configurar DNS A record apuntando a $APP_GW_IP
echo "Configura tu DNS A record: api.tudominio.com -> $APP_GW_IP"
```

## Monitoreo y Logs

### Ver Logs de Container Apps

```bash
# Logs del backend
az containerapp logs show \
  --name "ca-payment-api-$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP" \
  --follow

# Logs del frontend
az containerapp logs show \
  --name "ca-payment-frontend-$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP" \
  --follow
```

### Acceder a Application Insights

1. Ve a Azure Portal → Application Insights
2. Busca `ai-<proyecto>-<ambiente>`
3. Explora métricas, logs y traces

## Troubleshooting

### Problemas Comunes

#### 1. Error de Autenticación Azure CLI

```bash
# Solución: Re-autenticarse
az logout
az login
```

#### 2. Container Apps no arrancan

```bash
# Verificar logs de deployment
az containerapp revision list \
  --name "ca-payment-api-$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP" \
  --output table

# Ver logs detallados
az containerapp logs show \
  --name "ca-payment-api-$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP"
```

#### 3. PostgreSQL Connection Failed

```bash
# Verificar que la VNET integration está correcta
az postgres flexible-server list \
  --resource-group "$RESOURCE_GROUP" \
  --output table

# Verificar firewall rules
az postgres flexible-server firewall-rule list \
  --name "$POSTGRES_SERVER_NAME" \
  --resource-group "$RESOURCE_GROUP"
```

#### 4. Application Gateway 502 Bad Gateway

```bash
# Verificar health probes
az network application-gateway probe list \
  --gateway-name "appgw-$PROJECT_NAME-$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP"

# Verificar backend health
az network application-gateway show-backend-health \
  --name "appgw-$PROJECT_NAME-$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP"
```

### Logs de Debugging

```bash
# Habilitar logs detallados en Azure CLI
az configure --defaults group="$RESOURCE_GROUP"
az config set core.only_show_errors=false
az config set core.output=table
```

## Limpieza de Recursos

### Eliminar Todo

```bash
# Opción 1: Script automatizado
./scripts/cleanup.sh

# Opción 2: Manual
az group delete --name "$RESOURCE_GROUP" --yes --no-wait
```

### Eliminar Recursos Específicos

```bash
# Solo Container Apps
az containerapp delete --name "ca-payment-api-$ENVIRONMENT" --resource-group "$RESOURCE_GROUP"
az containerapp delete --name "ca-payment-frontend-$ENVIRONMENT" --resource-group "$RESOURCE_GROUP"

# Solo PostgreSQL
az postgres flexible-server delete --name "$POSTGRES_SERVER_NAME" --resource-group "$RESOURCE_GROUP"
```

## Actualizaciones y Mantenimiento

### Actualizar Container Apps

```bash
# Actualizar imagen del backend
az containerapp update \
  --name "ca-payment-api-$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP" \
  --image "ghcr.io/tu-usuario/payment-api:v2.0"

# Actualizar imagen del frontend
az containerapp update \
  --name "ca-payment-frontend-$ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP" \
  --image "ghcr.io/tu-usuario/payment-frontend:v2.0"
```

### Backup de PostgreSQL

```bash
# Crear backup manual
az postgres flexible-server backup create \
  --name "$POSTGRES_SERVER_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --backup-name "manual-backup-$(date +%Y%m%d)"
```

## Scripts de Automatización

El proyecto incluye varios scripts para automatizar tareas comunes:

- **`validate.sh`**: Valida templates y configuración
- **`deploy.sh`**: Despliega toda la infraestructura
- **`cleanup.sh`**: Elimina todos los recursos
- **`variables.sh`**: Configuración centralizada de variables

### Usar en CI/CD

```yaml
# Ejemplo para GitHub Actions
- name: Deploy to Azure
  run: |
    source scripts/variables.sh
    ./scripts/validate.sh
    ./scripts/deploy.sh
```

## Próximos Pasos

1. **Implementar CI/CD** con GitHub Actions
2. **Configurar SSL/TLS** con certificados personalizados
3. **Optimizar auto-scaling** basado en métricas reales
4. **Implementar backup strategy** automatizada
5. **Configurar alertas** adicionales en Azure Monitor

## Soporte y Recursos

- **Documentación Azure Container Apps**: https://docs.microsoft.com/azure/container-apps/
- **Documentación Application Gateway**: https://docs.microsoft.com/azure/application-gateway/
- **Documentación PostgreSQL Flexible Server**: https://docs.microsoft.com/azure/postgresql/flexible-server/
