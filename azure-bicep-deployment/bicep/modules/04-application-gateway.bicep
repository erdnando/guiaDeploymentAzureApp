// ============================================================================
// BICEP Template: Application Gateway
// Equivalent to: 04-application-gateway.json
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

@description('Nombre de la red virtual')
param virtualNetworkName string

@description('Nombre de la subnet para Application Gateway')
param subnetName string

@description('FQDN del Container App (backend)')
param containerAppFQDN string

@description('Centro de costos para facturación')
param costCenter string = 'IT-Development'

@description('Responsable del recurso')
param owner string = 'DevOps-Team'

// Variables
var applicationGatewayName = 'agw-${projectName}-${environment}-${uniqueString(resourceGroup().id)}'
var publicIpName = 'pip-${applicationGatewayName}'

var commonTags = {
  Environment: environment
  Project: projectName
  CostCenter: costCenter
  Owner: owner
  CreatedBy: 'BICEP Template'
  ManagedBy: 'Infrastructure-as-Code'
  Purpose: 'Payment Application Gateway'
}

// Virtual Network (referenced, not created here)
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' existing = {
  name: virtualNetworkName
}

// Subnet (referenced, not created here)
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-05-01' existing = {
  parent: virtualNetwork
  name: subnetName
}

// Public IP for Application Gateway
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: publicIpName
  location: location
  tags: commonTags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: '${projectName}-${environment}-${uniqueString(resourceGroup().id)}'
    }
  }
}

// Application Gateway
resource applicationGateway 'Microsoft.Network/applicationGateways@2023-05-01' = {
  name: applicationGatewayName
  location: location
  tags: commonTags
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 1
    }
    gatewayIPConfigurations: [
      {
        name: 'appGwIpConfig'
        properties: {
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'containerAppBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: containerAppFQDN
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGwBackendHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 20
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'containerAppProbe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGwHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              applicationGatewayName,
              'appGwPublicFrontendIp'
            )
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'port_80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              applicationGatewayName,
              'appGwHttpListener'
            )
          }
          backendAddressPool: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendAddressPools',
              applicationGatewayName,
              'containerAppBackendPool'
            )
          }
          backendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              applicationGatewayName,
              'appGwBackendHttpSettings'
            )
          }
        }
      }
    ]
    probes: [
      {
        name: 'containerAppProbe'
        properties: {
          protocol: 'Https'
          path: '/health'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
    enableHttp2: true
    autoscaleConfiguration: {
      minCapacity: 1
      maxCapacity: 3
    }
  }
}

// Outputs
@description('El nombre del Application Gateway')
output applicationGatewayName string = applicationGateway.name

@description('El ID del Application Gateway')
output applicationGatewayId string = applicationGateway.id

@description('La IP pública del Application Gateway')
output publicIPAddress string = publicIp.properties.ipAddress

@description('El FQDN público del Application Gateway')
output publicFQDN string = publicIp.properties.dnsSettings.fqdn
