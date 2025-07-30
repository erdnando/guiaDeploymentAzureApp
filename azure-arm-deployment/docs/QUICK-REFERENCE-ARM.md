# ⚡ ARM Templates - Referencia Rápida

> **Para desarrolladores con experiencia en ARM que necesitan comandos y sintaxis rápidamente**

## 🚀 Comandos Esenciales

### 📋 **Validación y Deploy**
```bash
# Variables de proyecto
export PROJECT_NAME="PaymentSystem"
export ENVIRONMENT="dev"
export LOCATION="canadacentral"
export RESOURCE_GROUP="rg-${PROJECT_NAME}-${ENVIRONMENT}"

# Crear Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Validar template
az deployment group validate \
  --resource-group $RESOURCE_GROUP \
  --template-file templates/main.json \
  --parameters @parameters/dev-parameters.json

# What-if analysis (preview de cambios)
az deployment group what-if \
  --resource-group $RESOURCE_GROUP \
  --template-file templates/main.json \
  --parameters @parameters/dev-parameters.json

# Deploy
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file templates/main.json \
  --parameters @parameters/dev-parameters.json \
  --name "payment-system-deployment"
```

### 🔍 **Monitoring y Debug**
```bash
# Estado del deployment
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name "payment-system-deployment" \
  --query 'properties.provisioningState'

# Operaciones del deployment
az deployment operation group list \
  --resource-group $RESOURCE_GROUP \
  --name "payment-system-deployment"

# Recursos creados
az resource list --resource-group $RESOURCE_GROUP --output table

# Export de configuración actual
az group export --resource-group $RESOURCE_GROUP > backup-template.json
```

### 🧹 **Cleanup**
```bash
# Eliminar deployment específico (NO elimina recursos)
az deployment group delete \
  --resource-group $RESOURCE_GROUP \
  --name "payment-system-deployment"

# Eliminar Resource Group completo
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

---

## 📝 Sintaxis ARM Esencial

### 🎯 **Template Básico**
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {},
  "variables": {},
  "resources": [],
  "outputs": {}
}
```

### 🔧 **Parámetros**
```json
"parameters": {
  "projectName": {
    "type": "string",
    "defaultValue": "MyProject",
    "allowedValues": ["dev", "test", "prod"],
    "minLength": 3,
    "maxLength": 10,
    "metadata": {
      "description": "Nombre del proyecto"
    }
  },
  "location": {
    "type": "string",
    "defaultValue": "[resourceGroup().location]"
  }
}
```

### 🔄 **Variables**
```json
"variables": {
  "resourceGroupName": "[concat('rg-', parameters('projectName'), '-', parameters('environment'))]",
  "storageAccountName": "[toLower(concat('st', parameters('projectName'), uniqueString(resourceGroup().id)))]",
  "commonTags": {
    "Project": "[parameters('projectName')]",
    "Environment": "[parameters('environment')]",
    "CreatedBy": "ARM-Template"
  }
}
```

### 🏗️ **Recursos**
```json
"resources": [
  {
    "type": "Microsoft.Storage/storageAccounts",
    "apiVersion": "2021-02-01",
    "name": "[variables('storageAccountName')]",
    "location": "[parameters('location')]",
    "tags": "[variables('commonTags')]",
    "sku": {
      "name": "Standard_LRS"
    },
    "kind": "StorageV2",
    "properties": {
      "supportsHttpsTrafficOnly": true
    }
  }
]
```

### 📤 **Outputs**
```json
"outputs": {
  "storageAccountName": {
    "type": "string",
    "value": "[variables('storageAccountName')]"
  },
  "storageAccountId": {
    "type": "string",
    "value": "[resourceId('Microsoft.Storage/storageAccounts', variables('storageAccountName'))]"
  }
}
```

---

## 🧰 Funciones ARM Útiles

### 🔗 **Funciones de String**
```json
"concat('prefix-', parameters('name'), '-suffix')"
"toLower(parameters('name'))"
"toUpper(parameters('name'))"
"substring(parameters('name'), 0, 5)"
"replace(parameters('name'), 'old', 'new')"
```

### 🎲 **Funciones de Generación**
```json
"uniqueString(resourceGroup().id)"                    // ID único por RG
"guid(subscription().subscriptionId, 'string')"       // GUID determinístico
"newGuid()"                                           // GUID aleatorio
```

### 📊 **Funciones de Array**
```json
"length(parameters('arrayParam'))"
"first(parameters('arrayParam'))"
"last(parameters('arrayParam'))"
"contains(parameters('arrayParam'), 'value')"
```

### 🏛️ **Funciones de Resource**
```json
"resourceGroup().location"
"resourceGroup().name"
"subscription().subscriptionId"
"resourceId('Microsoft.Storage/storageAccounts', 'mystorageaccount')"
"reference('mystorageaccount').primaryEndpoints.blob"
```

### ❓ **Funciones Condicionales**
```json
"if(equals(parameters('environment'), 'prod'), 'Standard_Premium_LRS', 'Standard_LRS')"
```

---

## 🐳 Container Apps Patterns

### 🌐 **Container App con Environment**
```json
{
  "type": "Microsoft.App/containerApps",
  "apiVersion": "2022-03-01",
  "name": "[variables('containerAppName')]",
  "location": "[parameters('location')]",
  "dependsOn": [
    "[resourceId('Microsoft.App/managedEnvironments', variables('environmentName'))]"
  ],
  "properties": {
    "managedEnvironmentId": "[resourceId('Microsoft.App/managedEnvironments', variables('environmentName'))]",
    "configuration": {
      "ingress": {
        "external": true,
        "targetPort": 80,
        "allowInsecure": false
      }
    },
    "template": {
      "containers": [
        {
          "name": "main",
          "image": "nginx:latest",
          "resources": {
            "cpu": 0.25,
            "memory": "0.5Gi"
          }
        }
      ],
      "scale": {
        "minReplicas": 1,
        "maxReplicas": 10
      }
    }
  }
}
```

### 🗄️ **PostgreSQL Flexible Server**
```json
{
  "type": "Microsoft.DBforPostgreSQL/flexibleServers",
  "apiVersion": "2021-06-01",
  "name": "[variables('postgresServerName')]",
  "location": "[parameters('location')]",
  "sku": {
    "name": "Standard_B1ms",
    "tier": "Burstable"
  },
  "properties": {
    "version": "13",
    "administratorLogin": "[parameters('dbAdminUsername')]",
    "administratorLoginPassword": "[parameters('dbAdminPassword')]",
    "storage": {
      "storageSizeGB": 32
    },
    "backup": {
      "backupRetentionDays": 7,
      "geoRedundantBackup": "Disabled"
    }
  }
}
```

### ⚖️ **Application Gateway v2**
```json
{
  "type": "Microsoft.Network/applicationGateways",
  "apiVersion": "2021-02-01",
  "name": "[variables('appGatewayName')]",
  "location": "[parameters('location')]",
  "dependsOn": [
    "[resourceId('Microsoft.Network/publicIPAddresses', variables('publicIPName'))]",
    "[resourceId('Microsoft.Network/virtualNetworks', variables('vnetName'))]"
  ],
  "properties": {
    "sku": {
      "name": "Standard_v2",
      "tier": "Standard_v2",
      "capacity": 2
    },
    "gatewayIPConfigurations": [
      {
        "name": "appGatewayIpConfig",
        "properties": {
          "subnet": {
            "id": "[resourceId('Microsoft.Network/virtualNetworks/subnets', variables('vnetName'), variables('appGatewaySubnetName'))]"
          }
        }
      }
    ],
    "frontendIPConfigurations": [
      {
        "name": "appGwPublicFrontendIp",
        "properties": {
          "privateIPAllocationMethod": "Dynamic",
          "publicIPAddress": {
            "id": "[resourceId('Microsoft.Network/publicIPAddresses', variables('publicIPName'))]"
          }
        }
      }
    ]
  }
}
```

---

## 🔐 Security & Compliance

### 🏷️ **Tags Obligatorios (Azure Policy)**
```json
"variables": {
  "commonTags": {
    "Project": "[parameters('projectName')]",
    "Environment": "[parameters('environment')]",
    "CostCenter": "[parameters('costCenter')]",
    "Owner": "[parameters('owner')]",
    "CreatedBy": "ARM-Template",
    "ManagedBy": "IaC-ARM"
  }
}
```

### 🌐 **NSG Rules**
```json
{
  "type": "Microsoft.Network/networkSecurityGroups",
  "apiVersion": "2021-02-01",
  "name": "[variables('nsgName')]",
  "location": "[parameters('location')]",
  "properties": {
    "securityRules": [
      {
        "name": "AllowHTTPS",
        "properties": {
          "protocol": "Tcp",
          "sourcePortRange": "*",
          "destinationPortRange": "443",
          "sourceAddressPrefix": "*",
          "destinationAddressPrefix": "*",
          "access": "Allow",
          "priority": 100,
          "direction": "Inbound"
        }
      },
      {
        "name": "DenyAll",
        "properties": {
          "protocol": "*",
          "sourcePortRange": "*",
          "destinationPortRange": "*",
          "sourceAddressPrefix": "*",
          "destinationAddressPrefix": "*",
          "access": "Deny",
          "priority": 4000,
          "direction": "Inbound"
        }
      }
    ]
  }
}
```

---

## 📊 Monitoring Templates

### 📈 **Log Analytics Workspace**
```json
{
  "type": "Microsoft.OperationalInsights/workspaces",
  "apiVersion": "2021-06-01",
  "name": "[variables('workspaceName')]",
  "location": "[parameters('location')]",
  "properties": {
    "sku": {
      "name": "PerGB2018"
    },
    "retentionInDays": 30,
    "features": {
      "searchVersion": 1
    }
  }
}
```

### 📱 **Application Insights**
```json
{
  "type": "Microsoft.Insights/components",
  "apiVersion": "2020-02-02",
  "name": "[variables('appInsightsName')]",
  "location": "[parameters('location')]",
  "kind": "web",
  "properties": {
    "Application_Type": "web",
    "WorkspaceResourceId": "[resourceId('Microsoft.OperationalInsights/workspaces', variables('workspaceName'))]"
  }
}
```

---

## ❌ Troubleshooting Rápido

### 🔍 **Errores Comunes**

| **Error** | **Causa** | **Solución** |
|-----------|-----------|--------------|
| `InvalidTemplate` | JSON malformado | Validar con `az deployment group validate` |
| `ResourceQuotaExceeded` | Límites de suscripción | `az vm list-usage --location <location>` |
| `InvalidResourceReference` | Dependencia faltante | Verificar `dependsOn` o usar funciones `reference()` |
| `SkuNotAvailable` | SKU no disponible en región | `az vm list-skus --location <location>` |
| `PolicyViolation` | Azure Policy bloqueando | Verificar tags y locations permitidas |

### 🛠️ **Comandos Debug**
```bash
# Ver últimos deployments fallidos
az deployment group list --resource-group $RESOURCE_GROUP \
  --query '[?properties.provisioningState==`Failed`].{Name:name, Error:properties.error.message}'

# Detalles de operación específica
az deployment operation group list --resource-group $RESOURCE_GROUP \
  --name "deployment-name" \
  --query '[?properties.provisioningState==`Failed`]'

# Logs de Container Apps
az containerapp logs show --name "app-name" --resource-group $RESOURCE_GROUP

# Estado de Application Gateway backends
az network application-gateway show-backend-health \
  --resource-group $RESOURCE_GROUP --name "appgw-name"
```

---

## 💡 Tips Pro

### ⚡ **Performance**
- Usar `--no-wait` para deployments no críticos
- Modularizar templates para deployments paralelos
- Usar `copy` loops para múltiples recursos similares

### 🎯 **Best Practices**
- Siempre usar `what-if` antes de deploy en prod
- Parametrizar diferencias entre ambientes
- Usar naming conventions consistentes
- Tags obligatorios para governance y costos

### 🔧 **Automation**
```bash
# Script de deploy completo
#!/bin/bash
set -e

# Validar
az deployment group validate --resource-group $RG --template-file main.json --parameters @params.json

# What-if
az deployment group what-if --resource-group $RG --template-file main.json --parameters @params.json

# Deploy
az deployment group create --resource-group $RG --template-file main.json --parameters @params.json --name "automated-$(date +%Y%m%d-%H%M%S)"
```

---

**⚡ Para guía completa paso a paso**: Ver [`GUIA-INGENIERO-ARM-PASO-A-PASO.md`](GUIA-INGENIERO-ARM-PASO-A-PASO.md)

**📚 Para documentación completa**: Ver [`INDEX.md`](INDEX.md)
