// ============================================================================
// BICEP Template: Monitoring (Application Insights)
// Equivalent to: 05-monitoring.json
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

@description('Retention en días para Application Insights')
param retentionInDays int = 90

@description('Centro de costos para facturación')
param costCenter string = 'IT-Development'

@description('Responsable del recurso')
param owner string = 'DevOps-Team'

// Variables
var applicationInsightsName = 'ai-${projectName}-${environment}-${uniqueString(resourceGroup().id)}'

var commonTags = {
  Environment: environment
  Project: projectName
  CostCenter: costCenter
  Owner: owner
  CreatedBy: 'BICEP Template'
  ManagedBy: 'Infrastructure-as-Code'
  Purpose: 'Payment Application Monitoring'
}

// Log Analytics Workspace (referenced, not created here)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

// Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: commonTags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'rest'
    RetentionInDays: retentionInDays
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Action Group for Alerts
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-${projectName}-${environment}'
  location: 'Global'
  tags: commonTags
  properties: {
    groupShortName: '${projectName}${environment}'
    enabled: true
    emailReceivers: []
    smsReceivers: []
    webhookReceivers: []
    azureAppPushReceivers: []
    itsmReceivers: []
    azureFunctionReceivers: []
    eventHubReceivers: []
    armRoleReceivers: []
    logicAppReceivers: []
    automationRunbookReceivers: []
    voiceReceivers: []
  }
}

// Metric Alert - High Response Time
resource alertResponseTime 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${projectName}-${environment}-response-time'
  location: 'Global'
  tags: commonTags
  properties: {
    description: 'Alert when response time is greater than 5 seconds'
    severity: 2
    enabled: true
    scopes: [
      applicationInsights.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'ResponseTime'
          metricName: 'requests/duration'
          operator: 'GreaterThan'
          threshold: 5000
          timeAggregation: 'Average'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Metric Alert - High Error Rate
resource alertErrorRate 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${projectName}-${environment}-error-rate'
  location: 'Global'
  tags: commonTags
  properties: {
    description: 'Alert when error rate is greater than 5%'
    severity: 1
    enabled: true
    scopes: [
      applicationInsights.id
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          name: 'ErrorRate'
          metricName: 'requests/failed'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Percent'
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

// Outputs
@description('El nombre de Application Insights')
output applicationInsightsName string = applicationInsights.name

@description('El ID de Application Insights')
output applicationInsightsId string = applicationInsights.id

@description('La clave de instrumentación de Application Insights')
output instrumentationKey string = applicationInsights.properties.InstrumentationKey

@description('La cadena de conexión de Application Insights')
output connectionString string = applicationInsights.properties.ConnectionString

@description('El nombre del Action Group')
output actionGroupName string = actionGroup.name

@description('El ID del Action Group')
output actionGroupId string = actionGroup.id
