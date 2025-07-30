// ============================================================================
// BICEP Template: Container Apps Environment
// Equivalent to: 03-containerapps-environment.json
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

@description('Nombre del workspace de Log Analytics')
param logAnalyticsWorkspaceName string

@description('Centro de costos para facturación')
param costCenter string = 'IT-Development'

@description('Responsable del recurso')
param owner string = 'DevOps-Team'

// Variables
var containerAppEnvironmentName = 'cae-${projectName}-${environment}-${uniqueString(resourceGroup().id)}'

var commonTags = {
  Environment: environment
  Project: projectName
  CostCenter: costCenter
  Owner: owner
  CreatedBy: 'BICEP Template'
  ManagedBy: 'Infrastructure-as-Code'
  Purpose: 'Payment Application Container Environment'
}

// Log Analytics Workspace (referenced, not created here)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

// Container Apps Environment
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppEnvironmentName
  location: location
  tags: commonTags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    zoneRedundant: false
    kedaConfiguration: {}
    daprConfiguration: {}
    customDomainConfiguration: {
      dnsSuffix: ''
      certificatePassword: ''
      certificateValue: ''
    }
  }
}

// Outputs
@description('El nombre del Container Apps Environment')
output containerAppEnvironmentName string = containerAppEnvironment.name

@description('El ID del Container Apps Environment')
output containerAppEnvironmentId string = containerAppEnvironment.id

@description('El dominio por defecto del Container Apps Environment')
output defaultDomain string = containerAppEnvironment.properties.defaultDomain
