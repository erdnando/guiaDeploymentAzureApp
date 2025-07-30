// ============================================================================
// BICEP Template: PostgreSQL Flexible Server
// Equivalent to: 02-postgresql.json
// ============================================================================

@description('Nombre base del proyecto')
param projectName string = 'paymentapp'

@description('Entorno de despliegue')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Ubicación para todos los recursos')
param location string = resourceGroup().location

@description('Usuario administrador de PostgreSQL')
param administratorLogin string = 'pgadmin'

@description('Contraseña del administrador de PostgreSQL')
@secure()
param administratorLoginPassword string

@description('Versión de PostgreSQL')
@allowed([
  '13'
  '14'
  '15'
])
param postgresVersion string = '14'

@description('SKU del servidor PostgreSQL')
param skuName string = 'Standard_B1ms'

@description('Tier de PostgreSQL')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param tier string = 'Burstable'

@description('Tamaño de almacenamiento en GB')
param storageSizeGB int = 32

@description('Nombre de la base de datos principal')
param databaseName string = 'paymentdb'

@description('Backup retention en días')
param backupRetentionDays int = 7

@description('Habilitar backup geo-redundante')
param geoRedundantBackup string = 'Disabled'

@description('Centro de costos para facturación')
param costCenter string = 'IT-Development'

@description('Responsable del recurso')
param owner string = 'DevOps-Team'

// Variables
var serverName = 'pg-${projectName}-${environment}-${uniqueString(resourceGroup().id)}'

var commonTags = {
  Environment: environment
  Project: projectName
  CostCenter: costCenter
  Owner: owner
  CreatedBy: 'BICEP Template'
  ManagedBy: 'Infrastructure-as-Code'
  Purpose: 'Payment Application Database'
}

// PostgreSQL Flexible Server
resource postgresqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-03-01-preview' = {
  name: serverName
  location: location
  tags: commonTags
  sku: {
    name: skuName
    tier: tier
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    version: postgresVersion
    storage: {
      storageSizeGB: storageSizeGB
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    highAvailability: {
      mode: 'Disabled'
    }
    maintenanceWindow: {
      customWindow: 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Disabled'
      passwordAuth: 'Enabled'
    }
  }
}

// Database
resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-03-01-preview' = {
  parent: postgresqlServer
  name: databaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.UTF8'
  }
}

// Firewall Rule for Azure Services
resource firewallRuleAzure 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-03-01-preview' = {
  parent: postgresqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Configuration for logging
resource configuration 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2023-03-01-preview' = {
  parent: postgresqlServer
  name: 'log_statement'
  properties: {
    value: 'all'
    source: 'user-override'
  }
}

// Outputs
@description('El nombre del servidor PostgreSQL')
output serverName string = postgresqlServer.name

@description('El FQDN del servidor PostgreSQL')
output serverFQDN string = postgresqlServer.properties.fullyQualifiedDomainName

@description('El nombre de la base de datos')
output databaseName string = database.name

@description('String de conexión para aplicaciones (sin contraseña)')
output connectionStringTemplate string = 'Server=${postgresqlServer.properties.fullyQualifiedDomainName};Database=${database.name};Port=5432;User Id=${administratorLogin};Ssl Mode=Require;'

@description('El ID del servidor PostgreSQL')
output serverId string = postgresqlServer.id
