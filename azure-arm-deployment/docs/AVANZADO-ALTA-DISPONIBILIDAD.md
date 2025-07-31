# 🏗️ **Configuración Avanzada: Alta Disponibilidad PostgreSQL - ARM Templates**

## 📋 **Índice**
- [Introducción](#introducción)
- [Template de Alta Disponibilidad](#template-de-alta-disponibilidad)
- [Parámetros Avanzados](#parámetros-avanzados)
- [Deployment y Validación](#deployment-y-validación)
- [Consideraciones de Costos](#consideraciones-de-costos)

---

## 🎯 **Introducción**

Esta guía avanzada implementa **Alta Disponibilidad Zone-Redundant** para PostgreSQL usando ARM Templates, siguiendo el patrón enterprise del diagrama:

- **Primary Database** en Availability Zone 1
- **Standby Database** en Availability Zone 2  
- **Failover automático** < 60 segundos
- **99.99% SLA** garantizado

---

## 📄 **Template de Alta Disponibilidad**

### 📁 **Archivo**: `02-postgresql-ha.json`

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "projectName": {
      "type": "string",
      "defaultValue": "paymentapp",
      "metadata": {
        "description": "Nombre base del proyecto"
      }
    },
    "environment": {
      "type": "string",
      "defaultValue": "prod",
      "allowedValues": ["dev", "test", "prod"],
      "metadata": {
        "description": "Entorno de despliegue (HA recomendado para prod)"
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "Ubicación para todos los recursos"
      }
    },
    "administratorLogin": {
      "type": "string",
      "defaultValue": "psqladmin",
      "metadata": {
        "description": "Usuario administrador de PostgreSQL"
      }
    },
    "administratorLoginPassword": {
      "type": "securestring",
      "metadata": {
        "description": "Contraseña del administrador"
      }
    },
    "skuName": {
      "type": "string",
      "defaultValue": "GP_Standard_D2s_v3",
      "allowedValues": [
        "GP_Standard_D2s_v3",
        "GP_Standard_D4s_v3",
        "GP_Standard_D8s_v3"
      ],
      "metadata": {
        "description": "SKU del servidor (GP mínimo para HA)"
      }
    },
    "tier": {
      "type": "string",
      "defaultValue": "GeneralPurpose",
      "allowedValues": ["GeneralPurpose", "MemoryOptimized"],
      "metadata": {
        "description": "Tier del servidor (GeneralPurpose mínimo para HA)"
      }
    },
    "postgresVersion": {
      "type": "string",
      "defaultValue": "14",
      "allowedValues": ["13", "14", "15"],
      "metadata": {
        "description": "Versión de PostgreSQL"
      }
    },
    "storageSizeGB": {
      "type": "int",
      "defaultValue": 128,
      "minValue": 32,
      "maxValue": 16384,
      "metadata": {
        "description": "Tamaño de storage en GB (mínimo 128GB para HA)"
      }
    },
    "primaryZone": {
      "type": "string",
      "defaultValue": "1",
      "allowedValues": ["1", "2", "3"],
      "metadata": {
        "description": "Zona de disponibilidad para el servidor primario"
      }
    },
    "standbyZone": {
      "type": "string",
      "defaultValue": "2",
      "allowedValues": ["1", "2", "3"],
      "metadata": {
        "description": "Zona de disponibilidad para el servidor standby"
      }
    }
  },
  "variables": {
    "serverName": "[concat('psql-', parameters('projectName'), '-', parameters('environment'), '-ha')]",
    "commonTags": {
      "Project": "[parameters('projectName')]",
      "Environment": "[parameters('environment')]",
      "CreatedBy": "ARM Template",
      "ManagedBy": "Infrastructure-as-Code",
      "Purpose": "Payment Application Database HA",
      "HighAvailability": "Zone-Redundant"
    }
  },
  "resources": [
    {
      "type": "Microsoft.DBforPostgreSQL/flexibleServers",
      "apiVersion": "2022-12-01",
      "name": "[variables('serverName')]",
      "location": "[parameters('location')]",
      "tags": "[variables('commonTags')]",
      "sku": {
        "name": "[parameters('skuName')]",
        "tier": "[parameters('tier')]"
      },
      "properties": {
        "administratorLogin": "[parameters('administratorLogin')]",
        "administratorLoginPassword": "[parameters('administratorLoginPassword')]",
        "version": "[parameters('postgresVersion')]",
        "availabilityZone": "[parameters('primaryZone')]",
        "storage": {
          "storageSizeGB": "[parameters('storageSizeGB')]",
          "autoGrow": "Enabled"
        },
        "backup": {
          "backupRetentionDays": 35,
          "geoRedundantBackup": "Enabled"
        },
        "highAvailability": {
          "mode": "ZoneRedundant",
          "standbyAvailabilityZone": "[parameters('standbyZone')]"
        },
        "network": {
          "publicNetworkAccess": "Disabled"
        },
        "maintenanceWindow": {
          "customWindow": "Enabled",
          "dayOfWeek": 0,
          "startHour": 2,
          "startMinute": 0
        },
        "authConfig": {
          "activeDirectoryAuth": "Disabled",
          "passwordAuth": "Enabled"
        }
      }
    },
    {
      "type": "Microsoft.DBforPostgreSQL/flexibleServers/databases",
      "apiVersion": "2022-12-01",
      "name": "[concat(variables('serverName'), '/payments')]",
      "dependsOn": [
        "[resourceId('Microsoft.DBforPostgreSQL/flexibleServers', variables('serverName'))]"
      ],
      "properties": {
        "charset": "UTF8",
        "collation": "en_US.UTF8"
      }
    },
    {
      "type": "Microsoft.DBforPostgreSQL/flexibleServers/databases",
      "apiVersion": "2022-12-01",
      "name": "[concat(variables('serverName'), '/orders')]",
      "dependsOn": [
        "[resourceId('Microsoft.DBforPostgreSQL/flexibleServers', variables('serverName'))]"
      ],
      "properties": {
        "charset": "UTF8",
        "collation": "en_US.UTF8"
      }
    },
    {
      "type": "Microsoft.DBforPostgreSQL/flexibleServers/databases",
      "apiVersion": "2022-12-01",
      "name": "[concat(variables('serverName'), '/users')]",
      "dependsOn": [
        "[resourceId('Microsoft.DBforPostgreSQL/flexibleServers', variables('serverName'))]"
      ],
      "properties": {
        "charset": "UTF8",
        "collation": "en_US.UTF8"
      }
    }
  ],
  "outputs": {
    "serverName": {
      "type": "string",
      "value": "[variables('serverName')]"
    },
    "serverFQDN": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.DBforPostgreSQL/flexibleServers', variables('serverName'))).fullyQualifiedDomainName]"
    },
    "highAvailabilityMode": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.DBforPostgreSQL/flexibleServers', variables('serverName'))).highAvailability.mode]"
    },
    "primaryZone": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.DBforPostgreSQL/flexibleServers', variables('serverName'))).availabilityZone]"
    },
    "standbyZone": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.DBforPostgreSQL/flexibleServers', variables('serverName'))).highAvailability.standbyAvailabilityZone]"
    }
  }
}
```

---

## ⚙️ **Parámetros Avanzados**

### 📁 **Archivo**: `prod.02-postgresql-ha.parameters.json`

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "projectName": {
      "value": "paymentapp"
    },
    "environment": {
      "value": "prod"
    },
    "location": {
      "value": "East US 2"
    },
    "administratorLogin": {
      "value": "psqladmin"
    },
    "administratorLoginPassword": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{subscription-id}/resourceGroups/{rg-name}/providers/Microsoft.KeyVault/vaults/{vault-name}"
        },
        "secretName": "postgresql-admin-password"
      }
    },
    "skuName": {
      "value": "GP_Standard_D4s_v3"
    },
    "tier": {
      "value": "GeneralPurpose"
    },
    "postgresVersion": {
      "value": "14"
    },
    "storageSizeGB": {
      "value": 256
    },
    "primaryZone": {
      "value": "1"
    },
    "standbyZone": {
      "value": "2"
    }
  }
}
```

---

## 🚀 **Deployment y Validación**

### 📜 **Script de Deployment**

```bash
#!/bin/bash

# =========================================
# DEPLOY POSTGRESQL HA - ARM Template
# =========================================

set -euo pipefail

RESOURCE_GROUP="rg-paymentapp-prod"
TEMPLATE_FILE="02-postgresql-ha.json"
PARAMETERS_FILE="prod.02-postgresql-ha.parameters.json"

echo "🏗️ Desplegando PostgreSQL con Alta Disponibilidad..."

# Deploy ARM template
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$TEMPLATE_FILE" \
  --parameters "@$PARAMETERS_FILE" \
  --output table

echo ""
echo "🔍 Validando configuración de HA..."

# Obtener outputs del deployment
SERVER_NAME=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "02-postgresql-ha" \
  --query "properties.outputs.serverName.value" -o tsv)

HA_MODE=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "02-postgresql-ha" \
  --query "properties.outputs.highAvailabilityMode.value" -o tsv)

PRIMARY_ZONE=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "02-postgresql-ha" \
  --query "properties.outputs.primaryZone.value" -o tsv)

STANDBY_ZONE=$(az deployment group show \
  --resource-group "$RESOURCE_GROUP" \
  --name "02-postgresql-ha" \
  --query "properties.outputs.standbyZone.value" -o tsv)

echo ""
echo "✅ Configuración de Alta Disponibilidad:"
echo "   • Servidor: $SERVER_NAME"
echo "   • Modo HA: $HA_MODE"
echo "   • Primary Zone: $PRIMARY_ZONE"
echo "   • Standby Zone: $STANDBY_ZONE"
echo "   • SLA: 99.99%"

echo ""
echo "✅ Deployment completado exitosamente"
```

---

## 💰 **Consideraciones de Costos**

### 📊 **Estimación de Costos HA**

| Componente | Costo Base | Factor HA | Costo Total |
|------------|------------|-----------|-------------|
| **Compute (D4s_v3)** | ~$140/mes | x2 (Primary + Standby) | ~$280/mes |
| **Storage (256GB)** | ~$30/mes | x2 (Replicado) | ~$60/mes |
| **Backup Geo-redundante** | ~$15/mes | Incluido | ~$15/mes |
| **Networking** | ~$10/mes | HA Traffic | ~$15/mes |
| **TOTAL ESTIMADO** | | | **~$370/mes** |

### ⚠️ **Factores Importantes**

- **🔄 Compute duplicado**: Primary + Standby activos
- **💾 Storage replicado**: Entre availability zones
- **🌐 Cross-zone traffic**: Para sincronización
- **📊 Enhanced monitoring**: Métricas de HA

---

## 🎯 **Próximos Pasos**

1. **🔧 Customizar**: Ajustar parámetros según necesidades
2. **🔐 Seguridad**: Configurar Key Vault para passwords
3. **📊 Monitoreo**: Implementar alertas de failover
4. **🧪 Testing**: Probar failover scenarios

---

## 📚 **Referencias ARM**

- [ARM Template Reference](https://docs.microsoft.com/azure/templates/microsoft.dbforpostgresql/flexibleservers)
- [High Availability Properties](https://docs.microsoft.com/azure/postgresql/flexible-server/concepts-high-availability)
- [ARM Best Practices](https://docs.microsoft.com/azure/azure-resource-manager/templates/best-practices)

---

> 💡 **Tip**: Usa Key Vault references para passwords y considera implementar Private Endpoints para máxima seguridad.
