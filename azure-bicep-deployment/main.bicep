// ============================================================================
// BICEP Main Template: Payment System Infrastructure
// Orchestrates all modules for complete deployment
// ============================================================================

// Target Scope
targetScope = 'resourceGroup'

// ============================================================================
// PARÁMETROS GLOBALES
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

// ============================================================================
// PARÁMETROS DE INFRAESTRUCTURA
// ============================================================================

@description('CIDR de la red virtual')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('CIDR de la subnet para Application Gateway')
param appGatewaySubnetPrefix string = '10.0.1.0/24'

@description('CIDR de la subnet para Container Apps')
param containerAppSubnetPrefix string = '10.0.2.0/24'

// ============================================================================
// PARÁMETROS DE GOVERNANCE Y COMPLIANCE
// ============================================================================

@description('Centro de costos para facturación')
param costCenter string = 'IT-Development'

@description('Responsable del recurso')
param owner string = 'DevOps-Team'

// ============================================================================
// PARÁMETROS DE POSTGRESQL
// ============================================================================

@description('Usuario administrador de PostgreSQL')
param postgresAdminLogin string = 'pgadmin'

@description('Contraseña del administrador de PostgreSQL')
@secure()
param postgresAdminPassword string

@description('Versión de PostgreSQL')
@allowed([
  '13'
  '14'
  '15'
])
param postgresVersion string = '14'

@description('SKU del servidor PostgreSQL')
param postgresSkuName string = 'Standard_B1ms'

@description('Nombre de la base de datos principal')
param databaseName string = 'paymentdb'

// ============================================================================
// PARÁMETROS DE CONTAINER APPS
// ============================================================================

@description('URL de la imagen del contenedor')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Puerto del contenedor')
param containerPort int = 80

@description('Número mínimo de réplicas')
param minReplicas int = 1

@description('Número máximo de réplicas')
param maxReplicas int = 3

@description('CPU por contenedor')
param containerCpu string = '0.25'

@description('Memoria por contenedor')
param containerMemory string = '0.5Gi'

// ============================================================================
// PARÁMETROS DE MONITORING
// ============================================================================

@description('Retention en días para Application Insights')
param appInsightsRetentionDays int = 90

// ============================================================================
// VARIABLES
// ============================================================================

var deploymentSuffix = uniqueString(resourceGroup().id)

// ============================================================================
// MÓDULO 1: INFRAESTRUCTURA BASE
// ============================================================================

module infrastructure 'bicep/modules/01-infrastructure.bicep' = {
  name: 'infrastructure-${deploymentSuffix}'
  params: {
    projectName: projectName
    environment: environment
    location: location
    vnetAddressPrefix: vnetAddressPrefix
    appGatewaySubnetPrefix: appGatewaySubnetPrefix
    containerAppSubnetPrefix: containerAppSubnetPrefix
    costCenter: costCenter
    owner: owner
  }
}

// ============================================================================
// MÓDULO 2: POSTGRESQL
// ============================================================================

module postgresql 'bicep/modules/02-postgresql.bicep' = {
  name: 'postgresql-${deploymentSuffix}'
  params: {
    projectName: projectName
    environment: environment
    location: location
    administratorLogin: postgresAdminLogin
    administratorLoginPassword: postgresAdminPassword
    postgresVersion: postgresVersion
    skuName: postgresSkuName
    databaseName: databaseName
    costCenter: costCenter
    owner: owner
  }
  dependsOn: [
    infrastructure
  ]
}

// ============================================================================
// MÓDULO 3: CONTAINER APPS ENVIRONMENT
// ============================================================================

module containerEnvironment 'bicep/modules/03-containerapp-environment.bicep' = {
  name: 'container-env-${deploymentSuffix}'
  params: {
    projectName: projectName
    environment: environment
    location: location
    logAnalyticsWorkspaceName: infrastructure.outputs.logAnalyticsWorkspaceName
    costCenter: costCenter
    owner: owner
  }
  dependsOn: [
    infrastructure
  ]
}

// ============================================================================
// MÓDULO 4: MONITORING
// ============================================================================

module monitoring 'bicep/modules/05-monitoring.bicep' = {
  name: 'monitoring-${deploymentSuffix}'
  params: {
    projectName: projectName
    environment: environment
    location: location
    logAnalyticsWorkspaceName: infrastructure.outputs.logAnalyticsWorkspaceName
    retentionInDays: appInsightsRetentionDays
    costCenter: costCenter
    owner: owner
  }
  dependsOn: [
    infrastructure
  ]
}

// ============================================================================
// MÓDULO 5: CONTAINER APPS
// ============================================================================

module containerApps 'bicep/modules/06-container-apps.bicep' = {
  name: 'container-apps-${deploymentSuffix}'
  params: {
    projectName: projectName
    environment: environment
    location: location
    containerAppEnvironmentName: containerEnvironment.outputs.containerAppEnvironmentName
    containerImage: containerImage
    containerPort: containerPort
    postgresConnectionString: 'Server=${postgresql.outputs.serverFQDN};Database=${postgresql.outputs.databaseName};Port=5432;User Id=${postgresAdminLogin};Password=${postgresAdminPassword};Ssl Mode=Require;'
    applicationInsightsConnectionString: monitoring.outputs.connectionString
    minReplicas: minReplicas
    maxReplicas: maxReplicas
    cpu: containerCpu
    memory: containerMemory
    costCenter: costCenter
    owner: owner
  }
  dependsOn: [
    containerEnvironment
    postgresql
    monitoring
  ]
}

// ============================================================================
// MÓDULO 6: APPLICATION GATEWAY
// ============================================================================

module applicationGateway 'bicep/modules/04-application-gateway.bicep' = {
  name: 'app-gateway-${deploymentSuffix}'
  params: {
    projectName: projectName
    environment: environment
    location: location
    virtualNetworkName: infrastructure.outputs.vnetName
    subnetName: infrastructure.outputs.appGatewaySubnetName
    containerAppFQDN: containerApps.outputs.containerAppFQDN
    costCenter: costCenter
    owner: owner
  }
  dependsOn: [
    infrastructure
    containerApps
  ]
}

// ============================================================================
// OUTPUTS PRINCIPALES
// ============================================================================

@description('Información de la infraestructura')
output infrastructure object = {
  virtualNetworkName: infrastructure.outputs.vnetName
  logAnalyticsWorkspaceName: infrastructure.outputs.logAnalyticsWorkspaceName
}

@description('Información de PostgreSQL')
output database object = {
  serverName: postgresql.outputs.serverName
  serverFQDN: postgresql.outputs.serverFQDN
  databaseName: postgresql.outputs.databaseName
}

@description('Información del Container App Environment')
output containerEnvironment object = {
  name: containerEnvironment.outputs.containerAppEnvironmentName
  id: containerEnvironment.outputs.containerAppEnvironmentId
  defaultDomain: containerEnvironment.outputs.defaultDomain
}

@description('Información de Monitoring')
output monitoring object = {
  applicationInsightsName: monitoring.outputs.applicationInsightsName
  instrumentationKey: monitoring.outputs.instrumentationKey
  connectionString: monitoring.outputs.connectionString
}

@description('Información del Container App')
output containerApp object = {
  name: containerApps.outputs.containerAppName
  fqdn: containerApps.outputs.containerAppFQDN
  url: containerApps.outputs.containerAppUrl
}

@description('Información del Application Gateway')
output applicationGateway object = {
  name: applicationGateway.outputs.applicationGatewayName
  publicIPAddress: applicationGateway.outputs.publicIPAddress
  publicFQDN: applicationGateway.outputs.publicFQDN
}

@description('URLs de acceso de la aplicación')
output accessUrls object = {
  applicationGateway: 'http://${applicationGateway.outputs.publicFQDN}'
  containerAppDirect: containerApps.outputs.containerAppUrl
}
