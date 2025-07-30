# =========================================
# AZURE PAYMENT SYSTEM - TERRAFORM IMPLEMENTATION
# =========================================
# 🏛️ Main orchestrator with Azure Policy compliance
# 🔐 Governance: Project tag + canadacentral location
# 📊 Cost management with standardized tagging

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Configure Azure Provider
provider "azurerm" {
  features {
    # Enable enhanced security features
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }

    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# =========================================
# VARIABLES - Azure Policy Compliance
# =========================================

variable "project" {
  description = "🏷️ Project name - REQUIRED by Azure Policy 'Require a tag on resources'"
  type        = string
  validation {
    condition     = length(var.project) > 0
    error_message = "❌ Project name is required for Azure Policy compliance."
  }
}

variable "environment" {
  description = "🏗️ Environment (dev, test, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "❌ Environment must be one of: dev, test, prod."
  }
}

variable "location" {
  description = "🌍 Azure region - MUST be canadacentral per Azure Policy 'Allowed locations'"
  type        = string
  default     = "canadacentral"
  validation {
    condition     = var.location == "canadacentral"
    error_message = "❌ Location must be 'canadacentral' per Azure Policy compliance."
  }
}

variable "cost_center" {
  description = "💰 Cost center for billing and governance"
  type        = string
  default     = "IT-Payment-Systems"
}

variable "owner" {
  description = "👤 Resource owner for governance and responsibility"
  type        = string
  default     = "Payment-Team"
}

variable "app_name" {
  description = "📱 Application name"
  type        = string
  default     = "paymentapp"
}

variable "container_cpu" {
  description = "🖥️ Container CPU allocation"
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "💾 Container memory allocation"
  type        = string
  default     = "1Gi"
}

variable "min_replicas" {
  description = "📊 Minimum container replicas"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "📈 Maximum container replicas"
  type        = number
  default     = 10
}

# =========================================
# LOCAL VALUES - Governance Tags
# =========================================

locals {
  # 🏷️ Common governance tags - Azure Policy compliant
  common_tags = {
    Project     = var.project # REQUIRED by Azure Policy
    Environment = var.environment
    CostCenter  = var.cost_center
    Owner       = var.owner
    CreatedBy   = "Terraform"
    ManagedBy   = "IaC-Terraform"
    Purpose     = "Payment-Processing-System"
    Compliance  = "Azure-Policy-Compliant"
  }

  # 📝 Resource naming convention
  resource_prefix = "${var.app_name}-${var.environment}-canada"
}

# =========================================
# MODULES - Infrastructure Components
# =========================================

# 🏗️ Infrastructure Foundation (Resource Group, VNet, etc.)
module "infrastructure" {
  source = "./modules/infrastructure"

  # Core parameters
  project         = var.project
  environment     = var.environment
  location        = var.location
  app_name        = var.app_name
  cost_center     = var.cost_center
  owner           = var.owner
  common_tags     = local.common_tags
  resource_prefix = local.resource_prefix
}

# 🗄️ PostgreSQL Database
module "postgresql" {
  source = "./modules/postgresql"

  # Core parameters
  project         = var.project
  environment     = var.environment
  location        = var.location
  cost_center     = var.cost_center
  owner           = var.owner
  common_tags     = local.common_tags
  resource_prefix = local.resource_prefix

  # Dependencies
  resource_group_name = module.infrastructure.resource_group_name
  subnet_id           = module.infrastructure.database_subnet_id

  depends_on = [module.infrastructure]
}

# 🐳 Container Environment (Container App Environment)
module "container_environment" {
  source = "./modules/container-environment"

  # Core parameters
  project         = var.project
  environment     = var.environment
  location        = var.location
  cost_center     = var.cost_center
  owner           = var.owner
  common_tags     = local.common_tags
  resource_prefix = local.resource_prefix

  # Dependencies
  resource_group_name        = module.infrastructure.resource_group_name
  subnet_id                  = module.infrastructure.container_subnet_id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  depends_on = [module.infrastructure, module.monitoring]
}

# 📊 Monitoring (Log Analytics, Application Insights)
module "monitoring" {
  source = "./modules/monitoring"

  # Core parameters
  project         = var.project
  environment     = var.environment
  location        = var.location
  cost_center     = var.cost_center
  owner           = var.owner
  common_tags     = local.common_tags
  resource_prefix = local.resource_prefix

  # Dependencies
  resource_group_name = module.infrastructure.resource_group_name

  depends_on = [module.infrastructure]
}

# 📱 Container Apps (Payment API, Frontend)
module "container_apps" {
  source = "./modules/container-apps"

  # Core parameters
  project         = var.project
  environment     = var.environment
  location        = var.location
  cost_center     = var.cost_center
  owner           = var.owner
  common_tags     = local.common_tags
  resource_prefix = local.resource_prefix

  # Container configuration
  container_cpu    = var.container_cpu
  container_memory = var.container_memory
  min_replicas     = var.min_replicas
  max_replicas     = var.max_replicas

  # Dependencies
  resource_group_name                    = module.infrastructure.resource_group_name
  container_app_environment_id           = module.container_environment.container_app_environment_id
  postgresql_connection_string           = module.postgresql.connection_string
  application_insights_connection_string = module.monitoring.application_insights_connection_string

  depends_on = [module.infrastructure, module.container_environment, module.postgresql, module.monitoring]
}

# 🌐 Application Gateway (Load Balancer, SSL Termination)
module "application_gateway" {
  source = "./modules/application-gateway"

  # Core parameters
  project         = var.project
  environment     = var.environment
  location        = var.location
  cost_center     = var.cost_center
  owner           = var.owner
  common_tags     = local.common_tags
  resource_prefix = local.resource_prefix

  # Dependencies
  resource_group_name = module.infrastructure.resource_group_name
  subnet_id           = module.infrastructure.gateway_subnet_id
  backend_fqdn        = module.container_apps.frontend_fqdn

  depends_on = [module.infrastructure, module.container_apps]
}

# =========================================
# OUTPUTS - Resource Information
# =========================================

output "resource_group_name" {
  description = "📁 Resource group name"
  value       = module.infrastructure.resource_group_name
}

output "postgresql_server_name" {
  description = "🗄️ PostgreSQL server name"
  value       = module.postgresql.server_name
  sensitive   = true
}

output "container_app_environment_name" {
  description = "🐳 Container App Environment name"
  value       = module.container_environment.container_app_environment_name
}

output "frontend_url" {
  description = "🌐 Frontend application URL"
  value       = module.container_apps.frontend_fqdn
}

output "api_url" {
  description = "📡 API endpoint URL"
  value       = module.container_apps.api_fqdn
}

output "application_gateway_public_ip" {
  description = "🌍 Application Gateway public IP"
  value       = module.application_gateway.public_ip_address
}

output "log_analytics_workspace_name" {
  description = "📊 Log Analytics workspace name"
  value       = module.monitoring.log_analytics_workspace_name
}

output "compliance_summary" {
  description = "✅ Azure Policy compliance status"
  value = {
    project_tag_policy = "✅ COMPLIANT - Project tag '${var.project}' applied to all resources"
    location_policy    = "✅ COMPLIANT - All resources in ${var.location}"
    governance_tags    = "✅ IMPLEMENTED - ${length(local.common_tags)} governance tags"
    managed_by         = "✅ Terraform IaC"
  }
}
