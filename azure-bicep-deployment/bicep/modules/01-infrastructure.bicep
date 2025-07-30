// ============================================================================
// BICEP Template: Infrastructure (Network, NSG, Subnets)
// Equivalent to: 01-infrastructure.json
// ============================================================================

@description('Nombre base del proyecto para nombrado de recursos')
param projectName string = 'paymentapp'

@description('Ubicación para todos los recursos')
param location string = resourceGroup().location

@description('Entorno de despliegue')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Prefijo de direcciones para la VNET')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Prefijo de subred para Application Gateway')
param appGatewaySubnetPrefix string = '10.0.0.0/24'

@description('Prefijo de subred para Container Apps')
param containerAppSubnetPrefix string = '10.0.8.0/21'

@description('Centro de costos para facturación')
param costCenter string = 'IT-Development'

@description('Responsable del recurso')
param owner string = 'DevOps-Team'

// Variables
var vnetName = 'vnet-${projectName}-${environment}'
var appGatewaySubnetName = 'subnet-appgw'
var containerAppSubnetName = 'subnet-containerapp'
var nsgName = 'nsg-${projectName}-${environment}'
var logAnalyticsWorkspaceName = 'law-${projectName}-${environment}-${uniqueString(resourceGroup().id)}'

var commonTags = {
  Environment: environment
  Project: projectName
  CostCenter: costCenter
  Owner: owner
  CreatedBy: 'BICEP Template'
  ManagedBy: 'Infrastructure-as-Code'
  Purpose: 'Payment Application Infrastructure'
}

// Network Security Group
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: nsgName
  location: location
  tags: commonTags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowHTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAppGwManagement'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Virtual Network
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  tags: commonTags
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    subnets: [
      {
        name: appGatewaySubnetName
        properties: {
          addressPrefix: appGatewaySubnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
      {
        name: containerAppSubnetName
        properties: {
          addressPrefix: containerAppSubnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          delegations: [
            {
              name: 'Microsoft.App.environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
    ]
  }
}

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: commonTags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Outputs
@description('El ID de la VNET creada')
output vnetId string = virtualNetwork.id

@description('El nombre de la VNET')
output vnetName string = virtualNetwork.name

@description('El ID de la subred del Application Gateway')
output appGatewaySubnetId string = virtualNetwork.properties.subnets[0].id

@description('El nombre de la subred del Application Gateway')
output appGatewaySubnetName string = appGatewaySubnetName

@description('El ID de la subred de Container Apps')
output containerAppSubnetId string = virtualNetwork.properties.subnets[1].id

@description('El nombre de la subred de Container Apps')
output containerAppSubnetName string = containerAppSubnetName

@description('El ID del Network Security Group')
output nsgId string = networkSecurityGroup.id

@description('El nombre del Network Security Group')
output nsgName string = networkSecurityGroup.name

@description('El ID de Log Analytics Workspace')
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id

@description('El nombre de Log Analytics Workspace')
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
