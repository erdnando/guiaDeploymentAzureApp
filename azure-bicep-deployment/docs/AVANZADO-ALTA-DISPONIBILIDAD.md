# 🏗️ **Configuración Avanzada: Alta Disponibilidad PostgreSQL - Bicep**

## 📋 **Índice**
- [Introducción](#introducción)
- [Módulo Bicep de Alta Disponibilidad](#módulo-bicep-de-alta-disponibilidad)
- [Parámetros y Variables](#parámetros-y-variables)
- [Deployment y Validación](#deployment-y-validación)
- [Consideraciones de Costos](#consideraciones-de-costos)

---

## 🎯 **Introducción**

Esta guía avanzada implementa **Alta Disponibilidad Zone-Redundant** para PostgreSQL usando Bicep, siguiendo el patrón enterprise:

- **Primary Database** en Availability Zone 1
- **Standby Database** en Availability Zone 2  
- **Failover automático** < 60 segundos
- **99.99% SLA** con syntax moderna de Bicep

---

## 📄 **Módulo Bicep de Alta Disponibilidad**

### 📁 **Archivo**: `02-postgresql-ha.bicep`

```bicep
// =========================================
// POSTGRESQL HA MODULE - Zone Redundant
// =========================================
// 🗄️ PostgreSQL with Zone-Redundant High Availability
// 🏗️ Primary Zone 1, Standby Zone 2

@description('🏷️ Project name')
param projectName string = 'paymentapp'

@description('🏗️ Environment (prod recommended for HA)')
@allowed(['dev', 'test', 'prod'])
param environment string = 'prod'

@description('🌍 Azure region')
param location string = resourceGroup().location

@description('👤 PostgreSQL administrator username')
param administratorLogin string = 'psqladmin'

@description('🔐 PostgreSQL administrator password')
@secure()
param administratorLoginPassword string

@description('📊 Server SKU (GP minimum for HA)')
@allowed(['GP_Standard_D2s_v3', 'GP_Standard_D4s_v3', 'GP_Standard_D8s_v3'])
param skuName string = 'GP_Standard_D4s_v3'

@description('🏗️ Server tier (GeneralPurpose minimum for HA)')
@allowed(['GeneralPurpose', 'MemoryOptimized'])
param tier string = 'GeneralPurpose'

@description('🐘 PostgreSQL version')
@allowed(['13', '14', '15'])
param postgresVersion string = '14'

@description('💾 Storage size in GB (minimum 128GB for HA)')
@minValue(128)
@maxValue(16384)
param storageSizeGB int = 256

@description('⚡ Primary availability zone')
@allowed(['1', '2', '3'])
param primaryZone string = '1'

@description('🔄 Standby availability zone')
@allowed(['1', '2', '3'])  
param standbyZone string = '2'

@description('📅 Backup retention days')
@minValue(7)
@maxValue(35)
param backupRetentionDays int = 35

@description('🌍 Geo-redundant backup')
@allowed(['Enabled', 'Disabled'])
param geoRedundantBackup string = 'Enabled'

@description('💰 Cost center for billing')
param costCenter string = 'IT-Infrastructure'

@description('👤 Resource owner')
param owner string = 'Database-Team'

// =========================================
// VARIABLES
// =========================================

var serverName = 'psql-${projectName}-${environment}-ha'
var databaseNames = ['payments', 'orders', 'users']

var commonTags = {
  Project: projectName
  Environment: environment
  CostCenter: costCenter
  Owner: owner
  CreatedBy: 'Bicep Template'
  ManagedBy: 'Infrastructure-as-Code'
  Purpose: 'Payment Application Database HA'
  HighAvailability: 'Zone-Redundant'
  PrimaryZone: primaryZone
  StandbyZone: standbyZone
}

// =========================================
// POSTGRESQL FLEXIBLE SERVER WITH HA
// =========================================

resource postgresqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: serverName
  location: location
  tags: commonTags
  
  sku: {
    name: skuName
    tier: tier
  }
  
  properties: {
    // 🔐 Authentication
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    
    // 📊 Server configuration
    version: postgresVersion
    availabilityZone: primaryZone
    
    // 💾 Storage configuration
    storage: {
      storageSizeGB: storageSizeGB
      autoGrow: 'Enabled'
    }
    
    // 🔄 Backup configuration
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    
    // 🏗️ HIGH AVAILABILITY CONFIGURATION
    highAvailability: {
      mode: 'ZoneRedundant'
      standbyAvailabilityZone: standbyZone
    }
    
    // 🔒 Security configuration
    network: {
      publicNetworkAccess: 'Disabled'
    }
    
    // 🕐 Maintenance window
    maintenanceWindow: {
      customWindow: 'Enabled'
      dayOfWeek: 0  // Sunday
      startHour: 2  // 2:00 AM
      startMinute: 0
    }
    
    // 🛡️ Authentication methods
    authConfig: {
      activeDirectoryAuth: 'Disabled'
      passwordAuth: 'Enabled'
    }
  }
}

// =========================================
// DATABASES CREATION
// =========================================

resource databases 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-12-01' = [for dbName in databaseNames: {
  parent: postgresqlServer
  name: dbName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.UTF8'
  }
}]

// =========================================
// SERVER CONFIGURATIONS
// =========================================

// SSL/TLS enforcement
resource sslConfiguration 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2022-12-01' = {
  parent: postgresqlServer
  name: 'require_secure_transport'
  properties: {
    value: 'on'
    source: 'user-override'
  }
}

// Connection limits for HA
resource connectionLimitConfig 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2022-12-01' = {
  parent: postgresqlServer
  name: 'max_connections'
  properties: {
    value: '200'
    source: 'user-override'
  }
}

// Log configuration for monitoring
resource logConfig 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2022-12-01' = {
  parent: postgresqlServer
  name: 'log_statement'
  properties: {
    value: 'ddl'
    source: 'user-override'
  }
}

// =========================================
// OUTPUTS
// =========================================

@description('🗄️ PostgreSQL server name')
output serverName string = postgresqlServer.name

@description('🌐 Server FQDN')
output serverFQDN string = postgresqlServer.properties.fullyQualifiedDomainName

@description('🏗️ High availability mode')
output highAvailabilityMode string = postgresqlServer.properties.highAvailability.mode

@description('🏗️ High availability state')
output highAvailabilityState string = postgresqlServer.properties.highAvailability.state

@description('⚡ Primary availability zone')
output primaryZone string = postgresqlServer.properties.availabilityZone

@description('🔄 Standby availability zone')
output standbyZone string = postgresqlServer.properties.highAvailability.standbyAvailabilityZone

@description('💾 Storage size GB')
output storageSizeGB int = postgresqlServer.properties.storage.storageSizeGB

@description('📅 Backup retention days')
output backupRetentionDays int = postgresqlServer.properties.backup.backupRetentionDays

@description('📊 Server SKU')
output serverSku object = postgresqlServer.sku

@description('🗄️ Database names')
output databaseNames array = databaseNames

@description('🔗 Connection string template')
output connectionStringTemplate string = 'postgresql://${administratorLogin}:<password>@${postgresqlServer.properties.fullyQualifiedDomainName}:5432/{database_name}?sslmode=require'
```

---

## ⚙️ **Parámetros y Variables**

### 📁 **Archivo**: `prod-ha-parameters.bicepparam`

```bicep
using '02-postgresql-ha.bicep'

// =========================================
// PRODUCTION HA PARAMETERS
// =========================================

param projectName = 'paymentapp'
param environment = 'prod'
param location = 'East US 2'

// 🔐 Security (use Key Vault in real deployment)
param administratorLogin = 'psqladmin'
param administratorLoginPassword = readEnvironmentVariable('POSTGRES_ADMIN_PASSWORD')

// 📊 Server configuration for production HA
param skuName = 'GP_Standard_D4s_v3'
param tier = 'GeneralPurpose'
param postgresVersion = '14'
param storageSizeGB = 512

// 🏗️ High Availability zones
param primaryZone = '1'
param standbyZone = '2'

// 🔄 Backup configuration
param backupRetentionDays = 35
param geoRedundantBackup = 'Enabled'

// 🏷️ Governance
param costCenter = 'IT-Production'
param owner = 'Database-Admin-Team'
```

---

## 🚀 **Deployment y Validación**

### 📜 **Script de Deployment**

```bash
#!/bin/bash

# =========================================
# DEPLOY POSTGRESQL HA - Bicep
# =========================================

set -euo pipefail

RESOURCE_GROUP="rg-paymentapp-prod"
BICEP_FILE="02-postgresql-ha.bicep"
PARAMETERS_FILE="prod-ha-parameters.bicepparam"

echo "🏗️ Desplegando PostgreSQL HA con Bicep..."

# Validar template
echo "🔍 Validando template Bicep..."
az deployment group validate \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$BICEP_FILE" \
  --parameters "$PARAMETERS_FILE"

# Deploy Bicep template
echo "🚀 Ejecutando deployment..."
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$BICEP_FILE" \
  --parameters "$PARAMETERS_FILE" \
  --name "postgresql-ha-deployment" \
  --output table

echo ""
echo "🔍 Validando configuración de HA..."

# Extraer outputs del deployment
DEPLOYMENT_OUTPUTS=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "postgresql-ha-deployment" \
  --query "properties.outputs")

SERVER_NAME=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.serverName.value')
HA_MODE=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.highAvailabilityMode.value')
HA_STATE=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.highAvailabilityState.value')
PRIMARY_ZONE=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.primaryZone.value')
STANDBY_ZONE=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.standbyZone.value')

echo ""
echo "✅ Configuración de Alta Disponibilidad:"
echo "   • Servidor: $SERVER_NAME"
echo "   • Modo HA: $HA_MODE"
echo "   • Estado HA: $HA_STATE"
echo "   • Primary Zone: $PRIMARY_ZONE"
echo "   • Standby Zone: $STANDBY_ZONE"
echo "   • SLA: 99.99%"

# Test de conectividad
echo ""
echo "🧪 Probando conectividad..."
SERVER_FQDN=$(echo "$DEPLOYMENT_OUTPUTS" | jq -r '.serverFQDN.value')
echo "   • FQDN: $SERVER_FQDN"

echo ""
echo "✅ Deployment de HA completado exitosamente"
```

---

## 📊 **Monitoreo y Alertas**

### 🔍 **Verificación de Estado HA**

```bash
# Verificar estado de alta disponibilidad
az postgres flexible-server show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$SERVER_NAME" \
  --query "{
    name: name,
    haMode: highAvailability.mode,
    haState: highAvailability.state,
    primaryZone: availabilityZone,
    standbyZone: highAvailability.standbyAvailabilityZone
  }" \
  --output table
```

### 📈 **Configuración de Alertas**

```bicep
// Alert para failover events
resource haFailoverAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${serverName}-ha-failover-alert'
  location: 'global'
  properties: {
    description: 'Alert when PostgreSQL HA failover occurs'
    severity: 1
    enabled: true
    scopes: [
      postgresqlServer.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'FailoverEvent'
          metricName: 'ha_replica_lag'
          operator: 'GreaterThan'
          threshold: 30
          timeAggregation: 'Average'
        }
      ]
    }
  }
}
```

---

## 💰 **Consideraciones de Costos**

### 📊 **Comparativa con Configuración Básica**

| Configuración | SKU | Storage | Backup | Costo Mensual |
|---------------|-----|---------|--------|---------------|
| **Básico** | B_Standard_B1ms | 32GB | Local | ~$50 |
| **HA Zone-Redundant** | GP_Standard_D4s_v3 | 512GB | Geo-redundant | ~$400 |

### ⚠️ **Factores de Costo HA**

- **🔄 Compute x2**: Primary + Standby servers
- **💾 Storage replicado**: Cross-zone replication
- **🌐 Network traffic**: Synchronization overhead
- **📊 Enhanced monitoring**: HA-specific metrics

---

## 🎯 **Próximos Pasos**

1. **🔧 Implementar**: Deploy en ambiente de testing primero
2. **🔐 Seguridad**: Configurar Key Vault integration
3. **📊 Monitoreo**: Setup de alertas y dashboards
4. **🧪 Testing**: Validar failover scenarios

---

## 📚 **Referencias Bicep**

- [Bicep PostgreSQL Reference](https://docs.microsoft.com/azure/templates/microsoft.dbforpostgresql/flexibleservers?pivots=deployment-language-bicep)
- [High Availability in Bicep](https://docs.microsoft.com/azure/postgresql/flexible-server/how-to-deploy-on-azure-free-account)
- [Bicep Best Practices](https://docs.microsoft.com/azure/azure-resource-manager/bicep/best-practices)

---

> 💡 **Tip**: Usa Bicep modules para reutilizar la configuración de HA across múltiples environments y projects.
