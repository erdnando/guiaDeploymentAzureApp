# =========================================
# CONTAINER APPS MODULE - Application Workloads (Simplified)
# =========================================
# 📱 Payment API and Frontend applications (basic configuration)
# 🔐 Managed identity, governance tags

# =========================================
# VARIABLES
# =========================================

variable "project" {
  description = "🏷️ Project name - REQUIRED by Azure Policy"
  type        = string
}

variable "environment" {
  description = "🏗️ Environment (dev, test, prod)"
  type        = string
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

variable "container_app_environment_id" {
  description = "🐳 Container App Environment ID"
  type        = string
}

variable "postgresql_connection_string" {
  description = "🗄️ PostgreSQL connection string"
  type        = string
  sensitive   = true
}

variable "application_insights_connection_string" {
  description = "📊 Application Insights connection string"
  type        = string
  sensitive   = true
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
# LOCALS
# =========================================

locals {
  # 🏷️ Container apps specific tags
  container_apps_tags = merge(var.common_tags, {
    Component = "Container-Apps"
    Purpose   = "Payment-Application-Workloads"
    Service   = "Azure-Container-Apps"
  })
}

# =========================================
# USER ASSIGNED MANAGED IDENTITY
# =========================================

resource "azurerm_user_assigned_identity" "container_apps" {
  name                = "id-${var.resource_prefix}-apps"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = local.container_apps_tags
}

# =========================================
# PAYMENT API CONTAINER APP
# =========================================

resource "azurerm_container_app" "payment_api" {
  name                         = "ca-${var.resource_prefix}-api"
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  # 🔐 Managed Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_apps.id]
  }

  # 📱 Template configuration
  template {
    # 🐳 Container configuration
    container {
      name   = "payment-api"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest" # Placeholder
      cpu    = var.container_cpu
      memory = var.container_memory

      # 🌐 Environment variables
      env {
        name  = "ASPNETCORE_ENVIRONMENT"
        value = var.environment == "prod" ? "Production" : "Development"
      }

      env {
        name        = "ConnectionStrings__DefaultConnection"
        secret_name = "postgresql-connection-string"
      }

      env {
        name        = "ApplicationInsights__ConnectionString"
        secret_name = "appinsights-connection-string"
      }
    }
  }

  # 🔒 Secrets configuration
  secret {
    name  = "postgresql-connection-string"
    value = var.postgresql_connection_string
  }

  secret {
    name  = "appinsights-connection-string"
    value = var.application_insights_connection_string
  }

  # 🌐 Ingress configuration
  ingress {
    external_enabled = false # Internal traffic only
    target_port      = 80

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  # 🔄 Dapr configuration
  dapr {
    app_id   = "payment-api"
    app_port = 80
  }

  # 🏷️ Governance tags
  tags = local.container_apps_tags
}

# =========================================
# FRONTEND CONTAINER APP
# =========================================

resource "azurerm_container_app" "frontend" {
  name                         = "ca-${var.resource_prefix}-frontend"
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  # 🔐 Managed Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_apps.id]
  }

  # 📱 Template configuration
  template {
    # 🐳 Container configuration
    container {
      name   = "frontend"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest" # Placeholder
      cpu    = var.container_cpu
      memory = var.container_memory

      # 🌐 Environment variables
      env {
        name  = "NODE_ENV"
        value = var.environment == "prod" ? "production" : "development"
      }

      env {
        name  = "API_BASE_URL"
        value = "https://${azurerm_container_app.payment_api.latest_revision_fqdn}"
      }

      env {
        name        = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        secret_name = "appinsights-connection-string"
      }
    }
  }

  # 🔒 Secrets configuration
  secret {
    name  = "appinsights-connection-string"
    value = var.application_insights_connection_string
  }

  # 🌐 Ingress configuration
  ingress {
    external_enabled = true # External access for frontend
    target_port      = 80

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  # 🔄 Dapr configuration
  dapr {
    app_id   = "frontend"
    app_port = 80
  }

  # 🏷️ Governance tags
  tags = local.container_apps_tags

  # Dependency to ensure API is created first
  depends_on = [azurerm_container_app.payment_api]
}

# =========================================
# OUTPUTS
# =========================================

output "payment_api_fqdn" {
  description = "📡 Payment API FQDN"
  value       = azurerm_container_app.payment_api.latest_revision_fqdn
}

output "frontend_fqdn" {
  description = "🌐 Frontend FQDN"
  value       = azurerm_container_app.frontend.latest_revision_fqdn
}

output "managed_identity_id" {
  description = "🔐 Managed identity ID"
  value       = azurerm_user_assigned_identity.container_apps.id
}

output "managed_identity_client_id" {
  description = "🔑 Managed identity client ID"
  value       = azurerm_user_assigned_identity.container_apps.client_id
}

output "api_fqdn" {
  description = "📡 API FQDN (alias for payment_api_fqdn)"
  value       = azurerm_container_app.payment_api.latest_revision_fqdn
}
