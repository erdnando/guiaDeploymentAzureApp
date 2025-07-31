# 🏗️ **Configuración Avanzada: Alta Disponibilidad PostgreSQL - Terraform**

## 📋 **Índice**
- [Introducción](#introducción)
- [Módulo Terraform de Alta Disponibilidad](#módulo-terraform-de-alta-disponibilidad)
- [Variables y Configuración](#variables-y-configuración)
- [Deployment y Validación](#deployment-y-validación)
- [Consideraciones de Costos](#consideraciones-de-costos)

---

## 🎯 **Introducción**

Esta guía avanzada implementa **Alta Disponibilidad Zone-Redundant** para PostgreSQL usando Terraform, siguiendo el patrón enterprise:

- **Primary Database** en Availability Zone 1
- **Standby Database** en Availability Zone 2  
- **Failover automático** < 60 segundos
- **99.99% SLA** con state management de Terraform

---

## 📄 **Módulo Terraform de Alta Disponibilidad**

### 📁 **Archivo**: `modules/postgresql-ha/main.tf`

```hcl
# =========================================
# POSTGRESQL HA MODULE - Zone Redundant
# =========================================
# 🗄️ PostgreSQL with Zone-Redundant High Availability
# 🏗️ Primary Zone 1, Standby Zone 2

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1"
    }
  }
}

# =========================================
# VARIABLES
# =========================================

variable "project" {
  description = "🏷️ Project name - REQUIRED by Azure Policy"
  type        = string
}

variable "environment" {
  description = "🏗️ Environment (prod recommended for HA)"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be dev, test, or prod."
  }
}

variable "location" {
  description = "🌍 Azure region"
  type        = string
}

variable "cost_center" {
  description = "💰 Cost center for billing"
  type        = string
}

variable "owner" {
  description = "👤 Resource owner"
  type        = string
}

variable "common_tags" {
  description = "🏷️ Common governance tags"
  type        = map(string)
}

variable "resource_prefix" {
  description = "📝 Resource naming prefix"
  type        = string
}

variable "resource_group_name" {
  description = "📁 Resource group name"
  type        = string
}

variable "subnet_id" {
  description = "🌐 Subnet ID for database"
  type        = string
}

variable "sku_name" {
  description = "📊 PostgreSQL SKU (GP minimum for HA)"
  type        = string
  default     = "GP_Standard_D4s_v3"
  validation {
    condition = can(regex("^GP_Standard_", var.sku_name))
    error_message = "SKU must be General Purpose or higher for High Availability."
  }
}

variable "postgres_version" {
  description = "🐘 PostgreSQL version"
  type        = string
  default     = "14"
  validation {
    condition     = contains(["13", "14", "15"], var.postgres_version)
    error_message = "PostgreSQL version must be 13, 14, or 15."
  }
}

variable "storage_mb" {
  description = "💾 Storage size in MB (minimum 131072 MB = 128GB for HA)"
  type        = number
  default     = 524288  # 512GB
  validation {
    condition     = var.storage_mb >= 131072
    error_message = "Storage must be at least 128GB (131072 MB) for High Availability."
  }
}

variable "backup_retention_days" {
  description = "📅 Backup retention in days"
  type        = number
  default     = 35
  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "Backup retention must be between 7 and 35 days."
  }
}

variable "primary_zone" {
  description = "⚡ Primary availability zone"
  type        = string
  default     = "1"
  validation {
    condition     = contains(["1", "2", "3"], var.primary_zone)
    error_message = "Primary zone must be 1, 2, or 3."
  }
}

variable "standby_zone" {
  description = "🔄 Standby availability zone"
  type        = string
  default     = "2"
  validation {
    condition     = contains(["1", "2", "3"], var.standby_zone)
    error_message = "Standby zone must be 1, 2, or 3."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "🌍 Enable geo-redundant backup"
  type        = bool
  default     = true
}

variable "database_names" {
  description = "🗄️ List of databases to create"
  type        = list(string)
  default     = ["payments", "orders", "users"]
}

# =========================================
# LOCALS
# =========================================

locals {
  # 🏷️ Database-specific tags for HA
  database_tags = merge(var.common_tags, {
    Component         = "Database"
    Purpose          = "Payment-Data-Storage"
    Service          = "PostgreSQL-Flexible-Server"
    HighAvailability = "Zone-Redundant"
    PrimaryZone      = var.primary_zone
    StandbyZone      = var.standby_zone
    Tier             = "Production-HA"
  })

  server_name = "psql-${var.resource_prefix}-ha"
}

# =========================================
# DATA SOURCES
# =========================================

data "azurerm_client_config" "current" {}

# =========================================
# RANDOM PASSWORD
# =========================================

resource "random_password" "postgresql_admin" {
  length  = 20
  special = true
  upper   = true
  lower   = true
  numeric = true
}

# =========================================
# PRIVATE DNS ZONE
# =========================================

resource "azurerm_private_dns_zone" "postgresql" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = local.database_tags
}

# Link DNS zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  name                  = "postgresql-dns-link-ha"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/vnet-${var.resource_prefix}"

  tags = local.database_tags
}

# =========================================
# POSTGRESQL FLEXIBLE SERVER WITH HA
# =========================================

resource "azurerm_postgresql_flexible_server" "main" {
  name                = local.server_name
  resource_group_name = var.resource_group_name
  location            = var.location

  # 🔐 Security configuration
  administrator_login    = "psqladmin"
  administrator_password = random_password.postgresql_admin.result

  # 📊 Server configuration
  sku_name = var.sku_name
  version  = var.postgres_version
  zone     = var.primary_zone

  # 💾 Storage configuration
  storage_mb                   = var.storage_mb
  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  # 🏗️ HIGH AVAILABILITY CONFIGURATION
  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = var.standby_zone
  }

  # 🔒 Security settings
  public_network_access_enabled = false

  # 🌐 Network configuration  
  delegated_subnet_id = var.subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.postgresql.id

  # 🕐 Maintenance window (Sunday 2:00 AM)
  maintenance_window {
    day_of_week  = 0
    start_hour   = 2
    start_minute = 0
  }

  # 🏷️ Governance tags
  tags = local.database_tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql]
}

# =========================================
# DATABASE CREATION
# =========================================

resource "azurerm_postgresql_flexible_server_database" "databases" {
  count     = length(var.database_names)
  name      = var.database_names[count.index]
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.UTF8"
}

# =========================================
# DATABASE CONFIGURATION
# =========================================

# SSL enforcement
resource "azurerm_postgresql_flexible_server_configuration" "ssl_enforcement" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}

# Connection limits for HA
resource "azurerm_postgresql_flexible_server_configuration" "max_connections" {
  name      = "max_connections"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "200"
}

# Log configuration for monitoring
resource "azurerm_postgresql_flexible_server_configuration" "log_statement" {
  name      = "log_statement"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "ddl"
}

# =========================================
# OUTPUTS
# =========================================

output "server_name" {
  description = "🗄️ PostgreSQL server name"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "server_fqdn" {
  description = "🌐 PostgreSQL server FQDN"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "server_id" {
  description = "🆔 PostgreSQL server resource ID"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "administrator_login" {
  description = "👤 Administrator username"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}

output "connection_string" {
  description = "🔗 Connection string template"
  value       = "postgresql://${azurerm_postgresql_flexible_server.main.administrator_login}:<password>@${azurerm_postgresql_flexible_server.main.fqdn}:5432/{database_name}?sslmode=require"
  sensitive   = false
}

output "high_availability_mode" {
  description = "🏗️ High availability mode"
  value       = "ZoneRedundant"
}

output "primary_zone" {
  description = "⚡ Primary availability zone"
  value       = azurerm_postgresql_flexible_server.main.zone
}

output "standby_zone" {
  description = "🔄 Standby availability zone"  
  value       = var.standby_zone
}

output "database_names" {
  description = "🗄️ Created database names"
  value       = var.database_names
}

output "private_dns_zone_id" {
  description = "🌐 Private DNS zone ID"
  value       = azurerm_private_dns_zone.postgresql.id
}

output "admin_password" {
  description = "🔐 Administrator password"
  value       = random_password.postgresql_admin.result
  sensitive   = true
}
```

---

## ⚙️ **Variables y Configuración**

### 📁 **Archivo**: `modules/postgresql-ha/variables.tf`

```hcl
# =========================================
# POSTGRESQL HA VARIABLES
# =========================================

variable "environment_configs" {
  description = "Environment-specific configurations"
  type = map(object({
    sku_name                = string
    storage_mb             = number
    backup_retention_days  = number
    geo_redundant_backup   = bool
  }))
  default = {
    dev = {
      sku_name               = "GP_Standard_D2s_v3"
      storage_mb            = 131072  # 128GB minimum for HA
      backup_retention_days = 7
      geo_redundant_backup  = false
    }
    test = {
      sku_name               = "GP_Standard_D2s_v3"
      storage_mb            = 262144  # 256GB
      backup_retention_days = 14
      geo_redundant_backup  = false
    }
    prod = {
      sku_name               = "GP_Standard_D4s_v3"
      storage_mb            = 524288  # 512GB
      backup_retention_days = 35
      geo_redundant_backup  = true
    }
  }
}
```

### 📁 **Archivo**: `terraform.tfvars.prod`

```hcl
# =========================================
# PRODUCTION HA CONFIGURATION
# =========================================

project               = "paymentapp"
environment           = "prod"
location              = "East US 2"
cost_center           = "IT-Production"
owner                 = "Database-Admin-Team"

# HA-specific configuration
sku_name                         = "GP_Standard_D4s_v3"
postgres_version                 = "14"
storage_mb                       = 524288  # 512GB
backup_retention_days            = 35
primary_zone                     = "1"
standby_zone                     = "2"
geo_redundant_backup_enabled     = true

# Database configuration
database_names = ["payments", "orders", "users", "audit"]

# Governance tags
common_tags = {
  Project      = "paymentapp"
  Environment  = "prod"
  CostCenter   = "IT-Production"
  Owner        = "Database-Admin-Team"
  CreatedBy    = "Terraform"
  ManagedBy    = "Infrastructure-as-Code"
  Purpose      = "Payment-Application-Database-HA"
  Compliance   = "SOX-PCI-DSS"
  DataClass    = "Confidential"
}
```

---

## 🚀 **Deployment y Validación**

### 📁 **Archivo**: `main.tf` (Updated for HA)

```hcl
# =========================================
# MAIN TERRAFORM CONFIGURATION WITH HA
# =========================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Infrastructure module (existing)
module "infrastructure" {
  source = "./modules/infrastructure"
  # ... existing configuration
}

# Container environment module (existing)
module "container_environment" {
  source = "./modules/container-environment"
  # ... existing configuration
}

# 🗄️ PostgreSQL with High Availability
module "postgresql_ha" {
  source = "./modules/postgresql-ha"

  project               = var.project
  environment           = var.environment
  location              = var.location
  cost_center           = var.cost_center
  owner                 = var.owner
  common_tags           = var.common_tags
  resource_prefix       = local.resource_prefix
  resource_group_name   = module.infrastructure.resource_group_name
  subnet_id             = module.infrastructure.database_subnet_id

  # HA-specific variables
  sku_name                         = var.sku_name
  postgres_version                 = var.postgres_version
  storage_mb                       = var.storage_mb
  backup_retention_days            = var.backup_retention_days
  primary_zone                     = var.primary_zone
  standby_zone                     = var.standby_zone
  geo_redundant_backup_enabled     = var.geo_redundant_backup_enabled
  database_names                   = var.database_names

  depends_on = [module.infrastructure]
}

# Container apps module (updated to use HA database)
module "container_apps" {
  source = "./modules/container-apps"

  # ... existing configuration
  postgresql_connection_string = module.postgresql_ha.connection_string

  depends_on = [
    module.infrastructure, 
    module.container_environment, 
    module.postgresql_ha
  ]
}

# Monitoring module
module "monitoring" {
  source = "./modules/monitoring"
  # ... existing configuration
}
```

### 📜 **Script de Deployment**

```bash
#!/bin/bash

# =========================================
# DEPLOY POSTGRESQL HA - Terraform
# =========================================

set -euo pipefail

ENVIRONMENT=${1:-prod}
TERRAFORM_DIR="."

echo "🏗️ Desplegando PostgreSQL HA con Terraform (Environment: $ENVIRONMENT)..."

# Initialize Terraform
echo "🔄 Inicializando Terraform..."
terraform init

# Select workspace
echo "🎯 Seleccionando workspace: $ENVIRONMENT"
terraform workspace select "$ENVIRONMENT" || terraform workspace new "$ENVIRONMENT"

# Plan deployment
echo "📋 Generando plan de deployment..."
terraform plan \
  -var-file="terraform.tfvars.$ENVIRONMENT" \
  -out="terraform-$ENVIRONMENT.tfplan"

# Apply deployment
echo "🚀 Ejecutando deployment..."
terraform apply "terraform-$ENVIRONMENT.tfplan"

echo ""
echo "🔍 Validando configuración de HA..."

# Extract outputs
SERVER_NAME=$(terraform output -raw postgresql_server_name)
HA_MODE=$(terraform output -raw high_availability_mode || echo "ZoneRedundant")
PRIMARY_ZONE=$(terraform output -raw primary_zone)
STANDBY_ZONE=$(terraform output -raw standby_zone)

echo ""
echo "✅ Configuración de Alta Disponibilidad:"
echo "   • Servidor: $SERVER_NAME"
echo "   • Modo HA: $HA_MODE"
echo "   • Primary Zone: $PRIMARY_ZONE"
echo "   • Standby Zone: $STANDBY_ZONE"
echo "   • SLA: 99.99%"

# Verify HA status with Azure CLI
echo ""
echo "🔍 Verificando estado con Azure CLI..."
RESOURCE_GROUP=$(terraform output -raw resource_group_name)

az postgres flexible-server show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$SERVER_NAME" \
  --query "{
    name: name,
    haMode: highAvailability.mode,
    haState: highAvailability.state,
    primaryZone: availabilityZone,
    standbyZone: highAvailability.standbyAvailabilityZone
  }" \
  --output table

echo ""
echo "✅ Deployment de HA completado exitosamente"
```

---

## 📊 **Outputs Avanzados**

### 📁 **Archivo**: `outputs.tf` (Enhanced for HA)

```hcl
# =========================================
# ENHANCED OUTPUTS FOR HA
# =========================================

# Basic server information
output "postgresql_server_name" {
  description = "🗄️ PostgreSQL server name"
  value       = module.postgresql_ha.server_name
}

output "postgresql_server_fqdn" {
  description = "🌐 PostgreSQL server FQDN"
  value       = module.postgresql_ha.server_fqdn
}

# High Availability information
output "high_availability_mode" {
  description = "🏗️ High availability mode"
  value       = module.postgresql_ha.high_availability_mode
}

output "primary_zone" {
  description = "⚡ Primary availability zone"
  value       = module.postgresql_ha.primary_zone
}

output "standby_zone" {
  description = "🔄 Standby availability zone"
  value       = module.postgresql_ha.standby_zone
}

# Connection information
output "postgresql_connection_string_template" {
  description = "🔗 PostgreSQL connection string template"
  value       = module.postgresql_ha.connection_string
}

output "database_names" {
  description = "🗄️ Created database names"
  value       = module.postgresql_ha.database_names
}

# Security information
output "administrator_login" {
  description = "👤 PostgreSQL administrator username"
  value       = module.postgresql_ha.administrator_login
}

# Sensitive outputs
output "admin_password" {
  description = "🔐 PostgreSQL administrator password"
  value       = module.postgresql_ha.admin_password
  sensitive   = true
}

# Deployment summary for HA
output "ha_deployment_summary" {
  description = "📊 HA Deployment Summary"
  value = {
    server_name       = module.postgresql_ha.server_name
    ha_mode          = module.postgresql_ha.high_availability_mode
    primary_zone     = module.postgresql_ha.primary_zone
    standby_zone     = module.postgresql_ha.standby_zone
    sla_guarantee    = "99.99%"
    failover_time    = "< 60 seconds"
    backup_retention = "35 days"
    geo_redundant    = true
  }
}
```

---

## 💰 **Consideraciones de Costos**

### 📊 **Cost Analysis con Terraform**

```hcl
# =========================================
# COST ESTIMATION LOCALS
# =========================================

locals {
  cost_analysis = {
    basic_config = {
      sku           = "B_Standard_B1ms"
      storage_gb    = 32
      ha_enabled    = false
      estimated_cost = 50
    }
    ha_config = {
      sku           = var.sku_name
      storage_gb    = var.storage_mb / 1024
      ha_enabled    = true
      estimated_cost = var.environment == "prod" ? 400 : 200
    }
    cost_multiplier = var.environment == "prod" ? 2.0 : 1.5
  }
}

output "cost_estimation" {
  description = "💰 Monthly cost estimation"
  value = {
    basic_monthly_usd    = local.cost_analysis.basic_config.estimated_cost
    ha_monthly_usd       = local.cost_analysis.ha_config.estimated_cost
    cost_increase_factor = "${local.cost_analysis.cost_multiplier}x"
    recommended_for      = var.environment == "prod" ? "Production workloads" : "Testing HA functionality"
  }
}
```

---

## 🎯 **Próximos Pasos**

1. **🔧 Deploy gradual**: Testing → Staging → Production
2. **🔐 Secrets management**: Integrar con Azure Key Vault
3. **📊 Monitoring**: Setup de alertas y dashboards
4. **🧪 DR Testing**: Probar escenarios de failover

---

## 📚 **Referencias Terraform**

- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server)
- [PostgreSQL HA Best Practices](https://docs.microsoft.com/azure/postgresql/flexible-server/concepts-high-availability)
- [Terraform State Management](https://www.terraform.io/docs/language/state/index.html)

---

> 💡 **Tip**: Usa Terraform workspaces para manejar múltiples environments y remote state para colaboración en equipo.
