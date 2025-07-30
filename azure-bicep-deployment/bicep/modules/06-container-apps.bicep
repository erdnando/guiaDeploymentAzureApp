// ============================================================================
// BICEP Template: Container Apps
// Equivalent to: 06-containerapps.json
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

@description('Nombre del Container Apps Environment')
param containerAppEnvironmentName string

@description('URL de la imagen del contenedor')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Puerto del contenedor')
param containerPort int = 80

@description('String de conexión de PostgreSQL')
@secure()
param postgresConnectionString string

@description('Cadena de conexión de Application Insights')
@secure()
param applicationInsightsConnectionString string

@description('Número mínimo de réplicas')
param minReplicas int = 1

@description('Número máximo de réplicas')
param maxReplicas int = 3

@description('CPU por contenedor')
param cpu string = '0.25'

@description('Memoria por contenedor')
param memory string = '0.5Gi'

@description('Centro de costos para facturación')
param costCenter string = 'IT-Development'

@description('Responsable del recurso')
param owner string = 'DevOps-Team'

// Variables
var containerAppName = 'ca-${projectName}-${environment}-${uniqueString(resourceGroup().id)}'

var commonTags = {
  Environment: environment
  Project: projectName
  CostCenter: costCenter
  Owner: owner
  CreatedBy: 'BICEP Template'
  ManagedBy: 'Infrastructure-as-Code'
  Purpose: 'Payment Application Runtime'
}

// Container Apps Environment (referenced, not created here)
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' existing = {
  name: containerAppEnvironmentName
}

// Container App
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  tags: commonTags
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: containerPort
        allowInsecure: false
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
      secrets: [
        {
          name: 'postgres-connection-string'
          value: postgresConnectionString
        }
        {
          name: 'appinsights-connection-string'
          value: applicationInsightsConnectionString
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'payment-api'
          image: containerImage
          resources: {
            cpu: json(cpu)
            memory: memory
          }
          env: [
            {
              name: 'DATABASE_CONNECTION_STRING'
              secretRef: 'postgres-connection-string'
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              secretRef: 'appinsights-connection-string'
            }
            {
              name: 'ASPNETCORE_ENVIRONMENT'
              value: environment
            }
            {
              name: 'ASPNETCORE_URLS'
              value: 'http://+:${containerPort}'
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: containerPort
                scheme: 'HTTP'
              }
              initialDelaySeconds: 30
              periodSeconds: 30
              timeoutSeconds: 10
              failureThreshold: 3
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/health/ready'
                port: containerPort
                scheme: 'HTTP'
              }
              initialDelaySeconds: 5
              periodSeconds: 10
              timeoutSeconds: 5
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scale-rule'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
          {
            name: 'cpu-scale-rule'
            custom: {
              type: 'cpu'
              metadata: {
                type: 'Utilization'
                value: '70'
              }
            }
          }
        ]
      }
    }
  }
}

// Outputs
@description('El nombre del Container App')
output containerAppName string = containerApp.name

@description('El ID del Container App')
output containerAppId string = containerApp.id

@description('El FQDN del Container App')
output containerAppFQDN string = containerApp.properties.configuration.ingress.fqdn

@description('La URL completa del Container App')
output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
