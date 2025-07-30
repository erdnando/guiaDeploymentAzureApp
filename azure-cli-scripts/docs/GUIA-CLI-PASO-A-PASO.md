# 🎓 Guía PASO A PASO: Azure CLI Scripts para Ingenieros Principiantes

## 🎯 **OBJETIVO GENERAL**
> **Al finalizar esta guía, serás capaz de:**
> - ✅ Entender cómo funciona Azure "por dentro" usando comandos CLI
> - ✅ Crear infraestructura paso a paso con Azure CLI imperativo
> - ✅ Debuggear deployments de ARM/BICEP/Terraform usando CLI
> - ✅ Automatizar operaciones de mantenimiento con scripts CLI
> - ✅ Tener foundation sólida para cualquier herramienta IaC
> - ✅ Dominar troubleshooting en producción con CLI

## 🧠 **CARACTERÍSTICAS DE APRENDIZAJE:**

### ✅ **"¿Qué estamos haciendo?"** - Explicación del objetivo
### ✅ **"¿Por qué?"** - Justificación pedagógica  
### ✅ **"¿Qué esperar?"** - Resultados esperados
### ✅ **"✅ CHECKPOINT"** - Validación de comprensión
### ✅ **"🎓 APRENDIZAJE"** - Conceptos clave
### ✅ **"🎉 LOGRO"** - Celebración de progreso

## 📚 **CONOCIMIENTOS QUE APRENDERÁS**
- 🔧 **Azure CLI fundamentals** - comandos imperativos básicos
- 🏗️ **Infrastructure building blocks** - networking, compute, storage
- 🐳 **Container Apps** desde CLI - comprensión profunda
- 📊 **Monitoring setup** - observabilidad manual
- 🔐 **Security configuration** - NSGs, SSL, policies
- 🛠️ **Debugging mastery** - troubleshooting production issues

---

## 📋 Índice Detallado
1. [🚀 FASE 0: Foundation y CLI Setup](#fase-0-foundation-y-cli-setup)
2. [🌐 FASE 1: Networking desde Cero](#fase-1-networking-desde-cero)
3. [🗄️ FASE 2: Database PostgreSQL](#fase-2-database-postgresql)
4. [🐳 FASE 3: Container Apps Environment](#fase-3-container-apps-environment)
5. [📊 FASE 4: Monitoring y Observabilidad](#fase-4-monitoring-y-observabilidad)
6. [🚀 FASE 5: Deploy de Aplicaciones](#fase-5-deploy-de-aplicaciones)
7. [⚖️ FASE 6: Application Gateway](#fase-6-application-gateway)
8. [🔧 FASE 7: Debugging y Troubleshooting](#fase-7-debugging-y-troubleshooting)
9. [🧹 FASE 8: Operaciones y Cleanup](#fase-8-operaciones-y-cleanup)

---

## 🚀 FASE 0: Foundation y CLI Setup

### 📋 **Objetivo de esta Fase**
> **¿QUÉ ESTAMOS HACIENDO?** Configurar fundaciones y entender Azure CLI como herramienta fundamental  
> **¿POR QUÉ?** CLI es la base de TODAS las herramientas Azure - ARM, BICEP, Terraform usan CLI internamente  
> **¿QUÉ ESPERAR?** Confianza total en Azure CLI y variables configuradas para el proyecto  

#### ✅ **Paso 0.1: Entender el Paradigma CLI**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Comprender la diferencia fundamental CLI vs IaC
# ¿POR QUÉ? Para entender cuándo usar cada enfoque

echo "🎯 CLI vs IaC - Diferencias Fundamentales:"
echo ""
echo "📜 CLI (IMPERATIVO):"
echo "   - Describes 'CÓMO hacer' paso a paso"
echo "   - Ejecutas comandos en secuencia"
echo "   - Flexible y dinámico"
echo "   - Ideal para: debugging, prototipado, operaciones"
echo ""
echo "📋 IaC (DECLARATIVO):"  
echo "   - Describes 'QUÉ quieres' como estado final"
echo "   - La herramienta decide cómo llegar ahí"
echo "   - Idempotente y reproducible"
echo "   - Ideal para: producción, versionado, CI/CD"
```

**🎓 APRENDIZAJE:** CLI scripts son el **foundation** de Azure. Entender CLI te da:
- **Debugging superpowers**: Puedes diagnosticar problemas en cualquier deployment
- **Flexibility**: Operaciones que no están disponibles en IaC
- **Understanding**: Sabes qué está pasando "por dentro"

#### ✅ **Paso 0.2: Verificar Azure CLI y Extensions**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Asegurar que tenemos todas las herramientas CLI
# ¿POR QUÉ? Container Apps requiere extensiones específicas

# Verificar Azure CLI
az --version

# Verificar login
az account show

# Instalar/actualizar extensiones necesarias
echo "🔧 Instalando extensiones Azure CLI..."
az extension add --name containerapp --upgrade
az extension add --name application-insights --upgrade
az extension add --name log-analytics --upgrade

# Verificar extensiones instaladas
az extension list --query '[].{Name:name, Version:version}' --output table
```

**¿QUÉ ESPERAR?** Extensions instaladas:
- `containerapp` - Para Container Apps
- `application-insights` - Para monitoring
- `log-analytics` - Para logs centralizados

#### ✅ **Paso 0.3: Configurar Variables de Entorno**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Definir configuración central del proyecto
# ¿POR QUÉ? Variables centralizadas = consistency + fácil modificación

# Cargar configuración desde archivo
source parameters/dev.env

# Verificar variables cargadas
echo "📋 CONFIGURACIÓN DEL PROYECTO:"
echo "   PROJECT_NAME: $PROJECT_NAME"
echo "   ENVIRONMENT: $ENVIRONMENT" 
echo "   LOCATION: $LOCATION"
echo "   RESOURCE_GROUP: $RESOURCE_GROUP"
echo "   DB_ADMIN_USER: $DB_ADMIN_USER"
echo "   CONTAINER_IMAGE: $CONTAINER_IMAGE"

# Verificar que variables están configuradas
if [ -z "$PROJECT_NAME" ]; then
    echo "❌ Error: Variables no cargadas. Ejecutar: source parameters/dev.env"
    exit 1
else
    echo "✅ Variables configuradas correctamente"
fi
```

**🎓 APRENDIZAJE:** Variables de entorno en CLI equivalen a parámetros en IaC:
- **Reutilización**: Mismo script para dev/test/prod
- **Maintenance**: Cambio centralizado de configuración
- **Security**: Valores sensibles separados del código

#### ✅ **Paso 0.4: Crear Resource Group**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Crear el contenedor lógico para todos los recursos
# ¿POR QUÉ? Resource Group = scope de lifecycle, permissions, billing

echo "🏗️ Creando Resource Group: $RESOURCE_GROUP"

# Crear Resource Group con tags
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --tags \
    Project=$PROJECT_NAME \
    Environment=$ENVIRONMENT \
    CreatedBy="CLI-Scripts" \
    ManagedBy="Manual-CLI" \
    Purpose="Payment-Processing-System"

# Verificar creación
az group show --name $RESOURCE_GROUP --query '{Name:name, Location:location, Tags:tags}' --output table

echo "✅ Resource Group creado exitosamente"
```

**✅ CHECKPOINT:** ¿Puedes ver el Resource Group en Azure Portal con los tags correctos?

**🎉 LOGRO:** ¡Tienes el foundation CLI configurado y primer recurso creado!

---

## 🌐 FASE 1: Networking desde Cero

### 📋 **Objetivo de esta Fase**
> **¿QUÉ ESTAMOS HACIENDO?** Crear la infraestructura de red paso a paso usando CLI  
> **¿POR QUÉ?** Networking es fundamental - sin red no hay comunicación entre servicios  
> **¿QUÉ ESPERAR?** VNet con subnets, NSGs y reglas de seguridad configuradas manualmente  

#### ✅ **Paso 1.1: Crear Virtual Network**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Crear la red privada principal
# ¿POR QUÉ? VNet es el foundation de conectividad en Azure

echo "🌐 Creando Virtual Network..."

# Crear VNet
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --address-prefix "10.0.0.0/16" \
  --location $LOCATION \
  --tags \
    Project=$PROJECT_NAME \
    Environment=$ENVIRONMENT

# Verificar VNet creada
az network vnet show \
  --resource-group $RESOURCE_GROUP \
  --name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --query '{Name:name, AddressSpace:addressSpace.addressPrefixes[0]}' \
  --output table

echo "✅ Virtual Network creada"
```

**🎓 APRENDIZAJE:** En CLI defines address spaces explícitamente:
- **10.0.0.0/16**: Permite 65,536 IPs (10.0.0.1 - 10.0.255.254)
- **Subnetting manual**: Tú decides la segmentación
- **Explicit control**: Cada decisión es consciente

#### ✅ **Paso 1.2: Crear Subnets por Función**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Segmentar la red por funcionalidad
# ¿POR QUÉ? Separation of concerns + security boundaries

echo "🔧 Creando subnets especializadas..."

# Subnet para Container Apps
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --name "snet-containerapp" \
  --address-prefix "10.0.1.0/24"

# Subnet para Application Gateway  
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --name "snet-appgateway" \
  --address-prefix "10.0.2.0/24"

# Subnet para PostgreSQL (cuando sea necesario)
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --name "snet-database" \
  --address-prefix "10.0.3.0/24"

# Listar subnets creadas
echo "📋 Subnets configuradas:"
az network vnet subnet list \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --query '[].{Name:name, AddressPrefix:addressPrefix}' \
  --output table
```

**🎓 APRENDIZAJE:** Subnet design en CLI:
- **Container Apps**: 10.0.1.0/24 (254 IPs disponibles)
- **App Gateway**: 10.0.2.0/24 (reservado para load balancer)
- **Database**: 10.0.3.0/24 (private database access)

#### ✅ **Paso 1.3: Crear Network Security Groups**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Crear firewalls a nivel de subnet
# ¿POR QUÉ? Security = defense in depth, NSGs = primera línea

echo "🔐 Creando Network Security Groups..."

# NSG para Container Apps
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name "nsg-containerapp-$ENVIRONMENT" \
  --location $LOCATION \
  --tags Project=$PROJECT_NAME Environment=$ENVIRONMENT

# NSG para Application Gateway
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name "nsg-appgateway-$ENVIRONMENT" \
  --location $LOCATION \
  --tags Project=$PROJECT_NAME Environment=$ENVIRONMENT

echo "✅ NSGs creados"
```

#### ✅ **Paso 1.4: Configurar Reglas de Seguridad**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Definir qué tráfico está permitido
# ¿POR QUÉ? Principle of least privilege - solo el tráfico necesario

echo "🛡️ Configurando reglas de seguridad..."

# Reglas para Application Gateway NSG
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name "nsg-appgateway-$ENVIRONMENT" \
  --name "AllowHTTPS" \
  --priority 100 \
  --protocol Tcp \
  --source-address-prefixes "*" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 443 \
  --access Allow \
  --direction Inbound

az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name "nsg-appgateway-$ENVIRONMENT" \
  --name "AllowHTTP" \
  --priority 110 \
  --protocol Tcp \
  --source-address-prefixes "*" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 80 \
  --access Allow \
  --direction Inbound

# Reglas para Container Apps NSG
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name "nsg-containerapp-$ENVIRONMENT" \
  --name "AllowFromAppGateway" \
  --priority 100 \
  --protocol Tcp \
  --source-address-prefixes "10.0.2.0/24" \
  --source-port-ranges "*" \
  --destination-address-prefixes "10.0.1.0/24" \
  --destination-port-ranges 80 443 \
  --access Allow \
  --direction Inbound

echo "✅ Reglas de seguridad configuradas"
```

**✅ CHECKPOINT:** ¿Entiendes por qué App Gateway puede acceder a Container Apps pero Internet no directamente?

#### ✅ **Paso 1.5: Asociar NSGs con Subnets**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Activar la protección de firewall en las subnets
# ¿POR QUÉ? NSG sin asociación = no hace nada

echo "🔗 Asociando NSGs con subnets..."

# Asociar NSG con subnet de Application Gateway
az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --name "snet-appgateway" \
  --network-security-group "nsg-appgateway-$ENVIRONMENT"

# Asociar NSG con subnet de Container Apps
az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --name "snet-containerapp" \
  --network-security-group "nsg-containerapp-$ENVIRONMENT"

# Verificar asociaciones
echo "🔍 Verificando asociaciones NSG:"
az network vnet subnet list \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --query '[].{Subnet:name, NSG:networkSecurityGroup.id}' \
  --output table

echo "✅ NSGs asociados exitosamente"
```

**🎉 LOGRO:** ¡Tienes una red segura y segmentada creada paso a paso!

**🎓 APRENDIZAJE:** En CLI cada paso es explícito:
1. **VNet** → Red principal
2. **Subnets** → Segmentación funcional  
3. **NSGs** → Firewalls de software
4. **Rules** → Políticas de tráfico específicas
5. **Association** → Activación de protección

---

## 🗄️ FASE 2: Database PostgreSQL

### 📋 **Objetivo de esta Fase**
> **¿QUÉ ESTAMOS HACIENDO?** Crear PostgreSQL Flexible Server con configuración de seguridad manual  
> **¿POR QUÉ?** Para entender database networking, firewall rules y SSL desde CLI  
> **¿QUÉ ESPERAR?** PostgreSQL funcionando con acceso controlado y monitoreo configurado  

#### ✅ **Paso 2.1: Crear PostgreSQL Flexible Server**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Crear la base de datos para el sistema de pagos
# ¿POR QUÉ? Aplicaciones necesitan persistencia - PostgreSQL es enterprise-grade

echo "🗄️ Creando PostgreSQL Flexible Server..."

# Crear PostgreSQL server
az postgres flexible-server create \
  --resource-group $RESOURCE_GROUP \
  --name "$DB_SERVER_NAME" \
  --location $LOCATION \
  --admin-user $DB_ADMIN_USER \
  --admin-password $DB_ADMIN_PASSWORD \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --version 13 \
  --storage-size 32 \
  --tags \
    Project=$PROJECT_NAME \
    Environment=$ENVIRONMENT \
    Purpose="Payment-Database"

echo "✅ PostgreSQL server creado"
```

**🎓 APRENDIZAJE:** CLI te obliga a entender cada parámetro:
- **SKU**: Standard_B1ms = 1 vCore, 2GB RAM (burstable)
- **Tier**: Burstable = cost-optimized para dev/test
- **Storage**: 32GB = mínimo para development
- **Version**: 13 = stable PostgreSQL version

#### ✅ **Paso 2.2: Configurar Database Firewall**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Configurar acceso de red a la base de datos
# ¿POR QUÉ? Security by default - PostgreSQL bloquea todo por defecto

echo "🔥 Configurando firewall de PostgreSQL..."

# Permitir acceso desde Container Apps subnet
az postgres flexible-server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --name "$DB_SERVER_NAME" \
  --rule-name "AllowContainerApps" \
  --start-ip-address "10.0.1.0" \
  --end-ip-address "10.0.1.255"

# Permitir acceso temporal desde tu IP para configuración
MY_IP=$(curl -s ifconfig.me)
az postgres flexible-server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --name "$DB_SERVER_NAME" \
  --rule-name "AllowMyIP" \
  --start-ip-address $MY_IP \
  --end-ip-address $MY_IP

echo "✅ Firewall configurado - acceso desde Container Apps y tu IP: $MY_IP"
```

**✅ CHECKPOINT:** ¿Entiendes por qué limitamos acceso solo a la subnet de Container Apps?

#### ✅ **Paso 2.3: Crear Databases de Aplicación**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Crear schemas separados por microservicio
# ¿POR QUÉ? Separation of concerns - cada servicio su database

echo "💾 Creando databases de aplicación..."

# Database para Payment Service
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name "$DB_SERVER_NAME" \
  --database-name "payments"

# Database para Order Service  
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name "$DB_SERVER_NAME" \
  --database-name "orders"

# Database para User Service
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name "$DB_SERVER_NAME" \
  --database-name "users"

# Listar databases creadas
az postgres flexible-server db list \
  --resource-group $RESOURCE_GROUP \
  --server-name "$DB_SERVER_NAME" \
  --query '[].name' \
  --output table

echo "✅ Databases de aplicación creadas"
```

#### ✅ **Paso 2.4: Verificar Conectividad**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Probar que la database está accesible
# ¿POR QUÉ? Validar configuración antes de continuar

echo "🔍 Verificando conectividad PostgreSQL..."

# Obtener connection string
DB_HOST=$(az postgres flexible-server show \
  --resource-group $RESOURCE_GROUP \
  --name "$DB_SERVER_NAME" \
  --query fullyQualifiedDomainName \
  --output tsv)

echo "📋 Información de conexión:"
echo "   Host: $DB_HOST"
echo "   User: $DB_ADMIN_USER"
echo "   Databases: payments, orders, users"
echo "   SSL: Required (default)"

# Test de conectividad básica (si psql está disponible)
if command -v psql &> /dev/null; then
    echo "🔌 Testing conexión..."
    PGPASSWORD=$DB_ADMIN_PASSWORD psql \
      -h $DB_HOST \
      -U $DB_ADMIN_USER \
      -d postgres \
      -c "SELECT version();" \
      --set=sslmode=require
else
    echo "💡 psql no disponible - conexión será verificada por las aplicaciones"
fi

echo "✅ PostgreSQL configurado y listo"
```

**🎉 LOGRO:** ¡Database enterprise-grade configurada manualmente!

**🎓 APRENDIZAJE:** CLI database management incluye:
- **Server creation**: Hardware sizing explícito
- **Firewall rules**: Network security manual
- **Database schemas**: Application separation
- **SSL enforcement**: Security by default

---

## 🐳 FASE 3: Container Apps Environment

### 📋 **Objetivo de esta Fase**
> **¿QUÉ ESTAMOS HACIENDO?** Crear entorno de contenedores con configuración manual de networking y monitoring  
> **¿POR QUÉ?** Para entender cómo funciona la plataforma serverless por dentro  
> **¿QUÉ ESPERAR?** Container Apps Environment listo para recibir aplicaciones  

#### ✅ **Paso 3.1: Crear Log Analytics Workspace**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Crear centralización de logs antes del Container Environment
# ¿POR QUÉ? Container Apps requiere Log Analytics para monitoring

echo "📊 Creando Log Analytics Workspace..."

az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name "log-$PROJECT_NAME-$ENVIRONMENT" \
  --location $LOCATION \
  --sku PerGB2018 \
  --retention-time 30 \
  --tags \
    Project=$PROJECT_NAME \
    Environment=$ENVIRONMENT \
    Purpose="Container-Monitoring"

# Obtener workspace ID para uso posterior
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RESOURCE_GROUP \
  --workspace-name "log-$PROJECT_NAME-$ENVIRONMENT" \
  --query customerId \
  --output tsv)

echo "✅ Log Analytics Workspace creado"
echo "   Workspace ID: $WORKSPACE_ID"
```

**🎓 APRENDIZAJE:** Log Analytics es prerequisito para Container Apps:
- **PerGB2018**: Pricing model por GB de logs
- **30 days retention**: Balance costo-compliance
- **Centralized**: Todos los containers envían logs aquí

#### ✅ **Paso 3.2: Crear Container Apps Environment**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Crear la plataforma donde correrán los containers
# ¿POR QUÉ? Container Apps Environment = managed Kubernetes cluster

echo "🐳 Creando Container Apps Environment..."

az containerapp env create \
  --resource-group $RESOURCE_GROUP \
  --name "cae-$PROJECT_NAME-$ENVIRONMENT" \
  --location $LOCATION \
  --logs-workspace-id $WORKSPACE_ID \
  --tags \
    Project=$PROJECT_NAME \
    Environment=$ENVIRONMENT \
    Purpose="Container-Platform"

echo "✅ Container Apps Environment creado"
```

#### ✅ **Paso 3.3: Configurar VNet Integration**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Conectar Container Environment con nuestra VNet
# ¿POR QUÉ? Para controlar networking y comunicación segura

echo "🌐 Configurando VNet integration..."

# Actualizar environment para usar nuestra VNet
az containerapp env update \
  --resource-group $RESOURCE_GROUP \
  --name "cae-$PROJECT_NAME-$ENVIRONMENT" \
  --infrastructure-subnet-resource-id "/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/vnet-$PROJECT_NAME-$ENVIRONMENT/subnets/snet-containerapp"

echo "✅ VNet integration configurada"
```

**✅ CHECKPOINT:** ¿Entiendes por qué Container Apps necesita su propia subnet?

#### ✅ **Paso 3.4: Verificar Environment Status**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Confirmar que el environment está listo
# ¿POR QUÉ? Environment creation puede tomar varios minutos

echo "🔍 Verificando estado del Container Apps Environment..."

# Verificar status
az containerapp env show \
  --resource-group $RESOURCE_GROUP \
  --name "cae-$PROJECT_NAME-$ENVIRONMENT" \
  --query '{Name:name, ProvisioningState:provisioningState, DefaultDomain:defaultDomain}' \
  --output table

# Obtener información de networking
ENVIRONMENT_ID=$(az containerapp env show \
  --resource-group $RESOURCE_GROUP \
  --name "cae-$PROJECT_NAME-$ENVIRONMENT" \
  --query id \
  --output tsv)

echo "📋 Environment configurado:"
echo "   ID: $ENVIRONMENT_ID"
echo "   Logs: Enviados a Log Analytics"
echo "   Network: Integrado con VNet"
echo "   Status: Listo para aplicaciones"

# Guardar Environment ID para uso posterior
echo "export CONTAINER_ENV_ID=\"$ENVIRONMENT_ID\"" >> /tmp/cli-vars.env

echo "✅ Container Apps Environment listo"
```

**🎉 LOGRO:** ¡Plataforma de containers lista para recibir aplicaciones!

**🎓 APRENDIZAJE:** Container Apps Environment equivale a:
- **Kubernetes cluster**: Pero fully managed
- **Networking**: Integrado con Azure VNet
- **Monitoring**: Log Analytics built-in
- **Scaling**: Auto-scaling configurado

---

## 📊 FASE 4: Monitoring y Observabilidad

### 📋 **Objetivo de esta Fase**
> **¿QUÉ ESTAMOS HACIENDO?** Configurar observabilidad completa con Application Insights y alertas  
> **¿POR QUÉ?** Para tener visibilidad total del sistema desde el día 1  
> **¿QUÉ ESPERAR?** Dashboard de monitoring y alertas configuradas manualmente  

#### ✅ **Paso 4.1: Crear Application Insights**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Crear APM (Application Performance Monitoring)
# ¿POR QUÉ? Application Insights = telemetría, métricas, distributed tracing

echo "📱 Creando Application Insights..."

az monitor app-insights component create \
  --app "ai-$PROJECT_NAME-$ENVIRONMENT" \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --application-type web \
  --kind web \
  --workspace "/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/log-$PROJECT_NAME-$ENVIRONMENT" \
  --tags \
    Project=$PROJECT_NAME \
    Environment=$ENVIRONMENT \
    Purpose="Application-Monitoring"

# Obtener Instrumentation Key
APPINSIGHTS_KEY=$(az monitor app-insights component show \
  --app "ai-$PROJECT_NAME-$ENVIRONMENT" \
  --resource-group $RESOURCE_GROUP \
  --query instrumentationKey \
  --output tsv)

echo "✅ Application Insights creado"
echo "   Instrumentation Key: $APPINSIGHTS_KEY"
```

#### ✅ **Paso 4.2: Configurar Métricas Personalizadas**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Configurar métricas específicas del negocio
# ¿POR QUÉ? Default metrics + business metrics = observabilidad completa

echo "📊 Configurando métricas de negocio..."

# Las métricas se configurarán via código de aplicación, pero preparamos queries
cat > /tmp/payment-metrics.kql << 'EOF'
// Métricas de Payment System
customEvents
| where name == "PaymentProcessed"
| summarize 
    PaymentCount = count(),
    TotalAmount = sum(todouble(customMeasurements["amount"])),
    AvgProcessingTime = avg(todouble(customMeasurements["processingTimeMs"]))
by bin(timestamp, 5m)
| order by timestamp desc
EOF

echo "📋 Queries de métricas preparadas:"
echo "   - Payment count por minuto"
echo "   - Total amount procesado"  
echo "   - Average processing time"
echo "   - Archivo: /tmp/payment-metrics.kql"

echo "✅ Métricas configuradas"
```

#### ✅ **Paso 4.3: Crear Alertas Proactivas**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Configurar alertas para problemas críticos
# ¿POR QUÉ? Proactive monitoring > reactive troubleshooting

echo "🚨 Configurando alertas críticas..."

# Alerta para high error rate
az monitor metrics alert create \
  --name "HighErrorRate-$ENVIRONMENT" \
  --resource-group $RESOURCE_GROUP \
  --scopes "/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Insights/components/ai-$PROJECT_NAME-$ENVIRONMENT" \
  --condition "avg exceptions/count > 5" \
  --window-size "5m" \
  --evaluation-frequency "1m" \
  --severity 2 \
  --description "High error rate detected in payment system" \
  --tags Project=$PROJECT_NAME Environment=$ENVIRONMENT

# Alerta para high response time
az monitor metrics alert create \
  --name "HighResponseTime-$ENVIRONMENT" \
  --resource-group $RESOURCE_GROUP \
  --scopes "/subscriptions/$(az account show --query id --output tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Insights/components/ai-$PROJECT_NAME-$ENVIRONMENT" \
  --condition "avg requests/duration > 2000" \
  --window-size "5m" \
  --evaluation-frequency "1m" \
  --severity 3 \
  --description "High response time detected" \
  --tags Project=$PROJECT_NAME Environment=$ENVIRONMENT

echo "✅ Alertas configuradas"
```

**✅ CHECKPOINT:** ¿Entiendes la diferencia entre métricas (Application Insights) y logs (Log Analytics)?

#### ✅ **Paso 4.4: Configurar Dashboard**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Crear dashboard centralizado
# ¿POR QUÉ? Single pane of glass para monitoring

echo "📈 Creando dashboard de monitoring..."

# Crear dashboard usando Azure Portal REST API sería complejo en CLI
# En su lugar, documentamos los KPIs importantes
cat > /tmp/dashboard-config.md << 'EOF'
# Payment System Dashboard

## KPIs Críticos:
1. **Requests per minute**: requests/count
2. **Error rate**: exceptions/count / requests/count * 100
3. **Response time P95**: requests/duration (95th percentile)
4. **Database connections**: customMetrics/database_connections
5. **Payment success rate**: customEvents/PaymentSuccess vs PaymentFailed

## Queries importantes:
- `requests | summarize count() by bin(timestamp, 1m)`
- `exceptions | summarize count() by problemId`
- `customEvents | where name == "PaymentProcessed"`

## URLs:
- Application Insights: https://portal.azure.com/#resource/...
- Log Analytics: https://portal.azure.com/#resource/...
EOF

echo "📋 Dashboard configuration documentada en: /tmp/dashboard-config.md"
echo "💡 Acceder a Application Insights en Azure Portal para crear dashboard visual"

echo "✅ Monitoring setup completado"
```

**🎉 LOGRO:** ¡Observabilidad enterprise-grade configurada manualmente!

**🎓 APRENDIZAJE:** Monitoring stack completo incluye:
- **Log Analytics**: Logs centralizados + queries KQL
- **Application Insights**: APM + distributed tracing  
- **Metrics**: Business KPIs + technical metrics
- **Alerts**: Proactive notifications
- **Dashboards**: Single pane of glass

---

*[La guía continúa con las fases restantes: Deploy de Aplicaciones, Application Gateway, Debugging y Operaciones]*

---

## 🎓 **RESUMEN DE APRENDIZAJES HASTA AQUÍ**

### ✅ **Lo que has LOGRADO:**
- ✅ **Configurado** Azure CLI como herramienta fundamental
- ✅ **Creado** networking seguro paso a paso
- ✅ **Deployado** PostgreSQL enterprise-grade
- ✅ **Establecido** Container Apps Environment
- ✅ **Implementado** monitoring completo

### 🧠 **CONCEPTOS DOMINADOS:**
- 🔧 **CLI Fundamentals**: Comandos imperativos vs declarativos
- 🌐 **Azure Networking**: VNet, subnets, NSGs desde cero
- 🗄️ **Database Security**: Firewall rules, SSL, access control
- 🐳 **Container Platform**: Environment, logging, VNet integration
- 📊 **Observability**: Metrics, logs, alerts, dashboards

### 🎯 **PRÓXIMAS FASES:**
- 🚀 **FASE 5**: Deploy de aplicaciones Container Apps
- ⚖️ **FASE 6**: Application Gateway con load balancing
- 🔧 **FASE 7**: Debugging y troubleshooting mastery
- 🧹 **FASE 8**: Operaciones y cleanup

**¡Continuemos construyendo! 🚀**

---

## 🚀 FASE 5: Deploy de Aplicaciones

**¿QUÉ ESTAMOS HACIENDO?**
Desplegando nuestros microservicios en Container Apps con configuración enterprise: auto-scaling, health checks, y comunicación inter-servicios segura.

**¿POR QUÉ ES CRÍTICO?**
Container Apps nos da Kubernetes sin complejidad:
- Auto-scaling basado en demanda real
- Zero-downtime deployments
- Service discovery automático
- Networking isolation

### 🎯 **OBJETIVO:** Sistema de microservicios funcionando

```bash
# Ejecutar deployment
./scripts/06-deploy-applications.sh
```

**🔍 CHECKPOINT:** Verificar que todas las apps estén desplegadas:
```bash
az containerapp list --resource-group $RESOURCE_GROUP --output table
```

**🎓 APRENDIZAJE: Microservices en Azure**

🏗️ **Arquitectura Desplegada:**
```
Internet → API Gateway → { Payment API, User API, Notification Service }
```

- **API Gateway**: Punto de entrada, routing, rate limiting
- **Payment API**: Core business logic + database
- **User API**: Autenticación + user management 
- **Notification Service**: Async communications

⚡ **Auto-scaling Inteligente:**
- HTTP concurrency-based scaling
- CPU/Memory thresholds
- Scale-to-zero para cost optimization
- Instant warm-up cuando llega tráfico

**🎉 LOGRO:** Microservices stack completo funcionando!

---

## ⚖️ FASE 6: Application Gateway - Load Balancer Enterprise

**¿QUÉ ESTAMOS HACIENDO?**
Creando Application Gateway como load balancer Layer 7 con SSL termination, WAF protection y path-based routing inteligente.

**¿POR QUÉ APPLICATION GATEWAY?**
- Punto único de entrada con dominio custom
- SSL offloading (descarga trabajo de backends)
- Web Application Firewall contra OWASP Top 10
- Performance optimization (compression, caching)

### 🎯 **OBJETIVO:** Load balancer enterprise-grade

```bash
# Crear Application Gateway (puede tomar 10-15 min)
./scripts/07-create-app-gateway.sh
```

**🔍 CHECKPOINT:** Verificar health de backends:
```bash
az network application-gateway show-backend-health \
  --name "agw-$PROJECT_NAME-$ENVIRONMENT" \
  --resource-group $RESOURCE_GROUP
```

**🎓 APRENDIZAJE: Load Balancing Avanzado**

🔀 **Path-based Routing:**
```
http://your-ip/api/payments/* → Payment API
http://your-ip/api/users/*    → User API  
http://your-ip/api/notify/*   → Notification Service
http://your-ip/              → API Gateway (default)
```

🛡️ **Security Stack:**
- SSL/TLS termination en el edge
- WAF rules para injection attacks
- Rate limiting per-client
- Geo-blocking capabilities

� **Performance Features:**
- Connection multiplexing
- HTTP/2 support
- Compression automática
- Session affinity cuando sea necesario

**🎉 LOGRO:** Load balancer enterprise con SSL y WAF protección!

---

## 🔧 FASE 7: Debugging y Troubleshooting Mastery

**¿QUÉ ESTAMOS HACIENDO?**
Implementando toolkit completo de debugging: logs en tiempo real, métricas de performance, tests de conectividad y recovery procedures.

**¿POR QUÉ ES FUNDAMENTAL?**
En producción, los problemas SIEMPRE ocurren:
- Detectar issues antes que afecten usuarios
- Root cause analysis rápido
- Recovery procedures automatizados
- Performance optimization basado en data

### 🎯 **OBJETIVO:** Debugging mastery

```bash
# Abrir herramientas de troubleshooting
./scripts/98-troubleshoot.sh
```

**🔍 CHECKPOINT:** Test completo del sistema:
1. ✅ Estado de todos los recursos
2. ✅ Conectividad end-to-end  
3. ✅ Logs de aplicaciones
4. ✅ Métricas de performance

**🎓 APRENDIZAJE: DevOps Debugging**

🔍 **Debugging Flow:**
```
1. Check Resource Status → ¿Healthy todos los recursos?
2. Review Application Logs → ¿Qué dicen las apps?
3. Test Network Connectivity → ¿Problemas de red?
4. Analyze Performance Metrics → ¿Degradation?
5. Trace Requests End-to-End → ¿Dónde falla?
```

📊 **Key Metrics Dashboard:**
- **Request Rate**: requests/second por service
- **Response Time**: P50, P95, P99 latency
- **Error Rate**: 4xx, 5xx error percentage  
- **Resource Utilization**: CPU, Memory, Connections
- **Business Metrics**: Payment success rate, etc.

🚨 **Incident Response Toolkit:**
- Real-time log streaming
- Distributed tracing correlation
- Automated health checks
- One-click service restart
- Rollback procedures

**🎉 LOGRO:** Production-ready debugging capabilities!

---

## 🧹 FASE 8: Operaciones y Resource Lifecycle

**¿QUÉ ESTAMOS HACIENDO?**
Implementando resource lifecycle management: cleanup automático, cost optimization y governance para mantener Azure subscription limpia.

**¿POR QUÉ ES CRÍTICO?**
- Evitar surprise bills (Azure puede ser caro!)
- Resource hygiene para compliance
- Environment preparation para nuevos projects
- Cost optimization automático

### 🎯 **OBJETIVO:** Operational excellence

```bash
# ⚠️ CUIDADO: Esto elimina TODOS los recursos
./scripts/99-cleanup.sh
```

**🔍 CHECKPOINT:** Verificar eliminación completa:
```bash
az group show --name $RESOURCE_GROUP
# Debe devolver error "ResourceGroupNotFound"
```

**🎓 APRENDIZAJE: Azure Cost Management**

💰 **Cost Optimization Strategy:**
- **Container Apps**: Scale-to-zero en development
- **Database**: Burstable tiers para testing
- **Application Gateway**: Reserved instances en prod
- **Log Analytics**: Retention policies apropiadas

🏷️ **Resource Tagging Strategy:**
```bash
Environment=Dev|Staging|Prod
Project=PaymentSystem
Owner=TeamName
CostCenter=Engineering
Purpose=Learning|Testing|Production
```

🔄 **Lifecycle Management:**
- **Development**: Auto-cleanup nocturno
- **Staging**: Cleanup fin de semana
- **Production**: Retention policies + monitoring

**🎉 LOGRO:** Complete operational control de Azure resources!

---

## 🎓 **FELICITACIONES - MASTERY COMPLETADO!**

### ✅ **Has DOMINADO:**

**🔧 Azure CLI Fundamentals:**
- ✅ Comandos imperativos vs declarativos
- ✅ Resource management programático
- ✅ Scripting para automation
- ✅ Error handling y debugging

**🏗️ Infrastructure as Code:**
- ✅ Networking completo desde cero
- ✅ Database security y configuration
- ✅ Container orchestration
- ✅ Load balancing enterprise-grade

**🔍 Operations & Debugging:**
- ✅ Monitoring stack completo
- ✅ Real-time troubleshooting
- ✅ Performance optimization
- ✅ Incident response procedures

**💰 Cost Management:**
- ✅ Resource lifecycle management
- ✅ Cost optimization strategies
- ✅ Governance y compliance
- ✅ Environment hygiene

### 🚀 **NEXT LEVEL CHALLENGES:**

1. **CI/CD Integration**: Integrar estos scripts en Azure DevOps
2. **Infrastructure Testing**: Unit tests para infrastructure
3. **Multi-Environment**: Dev/Staging/Prod automation
4. **Security Hardening**: RBAC, Key Vault, Private endpoints
5. **High Availability**: Multi-region deployment

### 🎯 **VALOR PROFESIONAL AGREGADO:**

Ahora puedes:
- ✅ **Debuggear** cualquier problema de Azure CLI
- ✅ **Automatizar** deployments complejos
- ✅ **Optimizar** costos en Azure
- ✅ **Implementar** best practices de DevOps
- ✅ **Mentorear** a otros en Azure CLI

**🏆 ¡Eres oficialmente un Azure CLI Expert!**

---

*📚 Esta guía es parte del proyecto Azure Infrastructure Learning. Has completado el track completo de Azure CLI - continúa con Terraform, BICEP o ARM para dominar todos los enfoques de IaC.*
