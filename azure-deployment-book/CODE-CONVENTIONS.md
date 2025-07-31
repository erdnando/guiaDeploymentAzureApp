# Code Conventions and Standards

This document outlines the coding standards, naming conventions, and best practices used throughout **Azure Deployment Mastery**. Following these conventions ensures consistency, readability, and maintainability across all examples.

## Resource naming conventions

### Standard naming format

All Azure resources follow a consistent naming pattern:
```
<resource-type>-<application>-<environment>-<instance>
```

**Examples:**
```bash
# Resource groups
rg-payment-system-dev-001
rg-payment-system-prod-001

# Storage accounts (no dashes, lowercase)
stpaymentsystemdev001
stpaymentsystemprod001

# Application Gateway
agw-payment-system-dev-001
agw-payment-system-prod-001

# Container Apps
ca-payment-service-dev-001
ca-order-service-dev-001
ca-user-service-dev-001
```

### Environment abbreviations

| Environment | Abbreviation | Usage |
|-------------|--------------|-------|
| Development | `dev` | Development and testing |
| Staging | `stg` | Pre-production validation |
| Production | `prod` | Live production workloads |
| Sandbox | `sbx` | Experimentation and learning |

### Resource type prefixes

| Resource | Prefix | Example |
|----------|--------|---------|
| Resource Group | `rg` | `rg-payment-system-dev` |
| Storage Account | `st` | `stpaymentsystemdev` |
| Application Gateway | `agw` | `agw-payment-system-dev` |
| Container App | `ca` | `ca-payment-service-dev` |
| Container Environment | `cae` | `cae-payment-system-dev` |
| PostgreSQL Server | `psql` | `psql-payment-system-dev` |
| Log Analytics | `law` | `law-payment-system-dev` |
| Application Insights | `ai` | `ai-payment-system-dev` |
| Key Vault | `kv` | `kv-payment-system-dev` |
| Virtual Network | `vnet` | `vnet-payment-system-dev` |
| Subnet | `snet` | `snet-payment-services-dev` |
| Network Security Group | `nsg` | `nsg-payment-services-dev` |

## File organization standards

### Directory structure

```
chapter-XX-name/
├── README.md                    # Chapter overview and instructions
├── TROUBLESHOOTING.md          # Common issues and solutions
├── scripts/
│   ├── deploy.sh               # Main deployment script
│   ├── cleanup.sh              # Resource cleanup script
│   └── validate.sh             # Pre-deployment validation
├── parameters/
│   ├── dev.parameters.json     # Development environment
│   ├── staging.parameters.json # Staging environment
│   └── prod.parameters.json    # Production environment
├── templates/                  # ARM/Bicep templates
├── terraform/                  # Terraform configurations
└── examples/                   # Additional code samples
```

### File naming conventions

| File Type | Pattern | Example |
|-----------|---------|---------|
| ARM Templates | `XX-component.json` | `01-infrastructure.json` |
| Bicep Files | `XX-component.bicep` | `01-infrastructure.bicep` |
| Terraform | `XX-component.tf` | `01-infrastructure.tf` |
| Parameters | `environment.parameters.json` | `dev.parameters.json` |
| Scripts | `action-environment.sh` | `deploy-dev.sh` |

## Code formatting standards

### Azure CLI commands

**Variable assignments:**
```bash
# Use uppercase for environment variables
RESOURCE_GROUP="rg-payment-system-dev"
LOCATION="canadacentral"
APP_NAME="payment-system"

# Use descriptive variable names
POSTGRESQL_SERVER_NAME="psql-${APP_NAME}-${ENVIRONMENT}"
ADMIN_PASSWORD=$(openssl rand -base64 32)
```

**Command formatting:**
```bash
# Break long commands across multiple lines
az containerapp create \
    --name "ca-payment-service-${ENVIRONMENT}" \
    --resource-group $RESOURCE_GROUP \
    --environment $CONTAINER_ENVIRONMENT \
    --image "paymentservice:latest" \
    --target-port 8080 \
    --ingress external \
    --min-replicas 1 \
    --max-replicas 10 \
    --cpu 1.0 \
    --memory 2.0Gi
```

### JSON parameter files

**Structure and formatting:**
```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "environment": {
            "value": "dev"
        },
        "location": {
            "value": "canadacentral"
        },
        "appName": {
            "value": "payment-system"
        },
        "postgresqlConfig": {
            "value": {
                "serverName": "psql-payment-system-dev",
                "administratorLogin": "pgadmin",
                "skuName": "Standard_B1ms",
                "skuTier": "Burstable",
                "storageSizeGB": 32,
                "postgresqlVersion": "15",
                "backupRetentionDays": 7,
                "geoRedundantBackup": "Disabled",
                "highAvailability": "Disabled"
            }
        }
    }
}
```

### Bicep style guidelines

**Resource definitions:**
```bicep
// Use descriptive parameter names with clear types
@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('Primary Azure region for resources')
param location string = resourceGroup().location

@description('Application name for resource naming')
@minLength(3)
@maxLength(24)
param appName string

// Use variables for complex expressions
var resourcePrefix = '${appName}-${environment}'
var postgresqlServerName = 'psql-${resourcePrefix}'
var containerEnvironmentName = 'cae-${resourcePrefix}'

// Group related resources logically
resource containerEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerEnvironmentName
  location: location
  properties: {
    daprAIInstrumentationKey: applicationInsights.properties.InstrumentationKey
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}
```

### Terraform conventions

**Resource naming and organization:**
```hcl
# Use locals for computed values
locals {
  resource_prefix    = "${var.app_name}-${var.environment}"
  common_tags = {
    Environment = var.environment
    Application = var.app_name
    ManagedBy   = "Terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  }
}

# Use consistent variable definitions
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# Group resources by functionality
resource "azurerm_container_app_environment" "payment_system" {
  name                       = "cae-${local.resource_prefix}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.payment_system.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.payment_system.id

  tags = local.common_tags
}
```

## Documentation standards

### README structure

Each chapter's README follows this template:

```markdown
# Chapter X: Title

Brief description of chapter objectives and what readers will accomplish.

## Prerequisites

- List of required tools and knowledge
- Azure subscription requirements
- Previous chapter dependencies

## Architecture overview

Description of what will be built, including diagrams when helpful.

## Implementation steps

1. **Step name:** Description of what this step accomplishes
2. **Next step:** Clear progression through the example

## Verification

How to validate the deployment was successful.

## Cleanup

Instructions for removing all created resources.

## Troubleshooting

Common issues and their solutions.

## Next steps

What the reader should do next or references to related chapters.
```

### Code comments

**Shell scripts:**
```bash
#!/bin/bash

# Azure CLI deployment script for Payment System
# Chapter X: ARM Template Enterprise Implementation
# 
# This script demonstrates enterprise deployment patterns including:
# - Environment-specific parameter files
# - Validation before deployment  
# - Error handling and rollback procedures
# - Output capture for downstream processes

set -euo pipefail  # Exit on any error, undefined variable, or pipe failure

# Configuration variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVIRONMENT="${1:-dev}"
RESOURCE_GROUP="rg-payment-system-${ENVIRONMENT}"
```

**ARM Templates:**
```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "metadata": {
        "description": "Payment System - PostgreSQL Database Infrastructure",
        "author": "Azure Deployment Mastery",
        "version": "1.0.0"
    },
    "parameters": {
        "environment": {
            "type": "string",
            "allowedValues": ["dev", "staging", "prod"],
            "metadata": {
                "description": "Target environment for deployment"
            }
        }
    }
}
```

## Error handling patterns

### Azure CLI error handling

```bash
# Function for error handling
handle_error() {
    local exit_code=$1
    local line_number=$2
    echo "Error on line $line_number: Command exited with status $exit_code"
    echo "Cleaning up partial deployment..."
    cleanup_resources
    exit $exit_code
}

# Set error trap
trap 'handle_error $? $LINENO' ERR

# Validate Azure CLI login
if ! az account show &>/dev/null; then
    echo "Error: Not logged into Azure CLI. Run 'az login' first."
    exit 1
fi

# Check resource group exists before deployment
if ! az group show --name $RESOURCE_GROUP &>/dev/null; then
    echo "Creating resource group: $RESOURCE_GROUP"
    az group create --name $RESOURCE_GROUP --location $LOCATION
fi
```

### Terraform error handling

```hcl
# Use validation blocks for input validation
variable "postgresql_sku_name" {
  description = "PostgreSQL SKU name"
  type        = string
  default     = "Standard_B1ms"
  
  validation {
    condition = can(regex("^(Standard_B[124]ms|Standard_D[248]s_v3)$", var.postgresql_sku_name))
    error_message = "PostgreSQL SKU must be a supported burstable or general purpose SKU."
  }
}

# Use lifecycle rules to prevent accidental deletion
resource "azurerm_postgresql_flexible_server" "payment_system" {
  # ... other configuration ...
  
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}
```

## Testing conventions

### Validation scripts

```bash
#!/bin/bash
# validate-deployment.sh - Post-deployment validation

echo "Validating Payment System deployment..."

# Test database connectivity
echo "Testing PostgreSQL connectivity..."
if pg_isready -h $POSTGRESQL_FQDN -p 5432 -U $ADMIN_USERNAME; then
    echo "✓ PostgreSQL server is ready"
else
    echo "✗ PostgreSQL server is not responding"
    exit 1
fi

# Test application endpoints
echo "Testing application endpoints..."
PAYMENT_URL=$(az containerapp show --name $PAYMENT_APP_NAME --resource-group $RESOURCE_GROUP --query properties.configuration.ingress.fqdn -o tsv)

if curl -f -s "https://$PAYMENT_URL/health" > /dev/null; then
    echo "✓ Payment service is healthy"
else
    echo "✗ Payment service health check failed"
    exit 1
fi

echo "All validation checks passed!"
```

These conventions ensure consistency across all examples and make the code easier to understand, maintain, and extend for real-world scenarios.

---

## 🧭 Navegación del Libro

**📍 Estás en:** 📋 Convenciones de Código (CODE-CONVENTIONS.md)  
**📖 Libro completo:** [LIBRO-COMPLETO.md](LIBRO-COMPLETO.md)  

### ⬅️➡️ **Navegación:**
← **Anterior:** [📜 Prefacio](PREFACE.md)  
**Siguiente:** [🎯 Introducción Técnica](03-introduction/introduccion.md) →

### 🎯 **Rutas Alternativas:**
- 🚀 **Directo a la acción:** [🎭 ACTO I - Azure CLI](04-act-1-cli/README.md)
- 📖 **Lectura completa:** [📖 Libro Consolidado](LIBRO-COMPLETO.md)

---
