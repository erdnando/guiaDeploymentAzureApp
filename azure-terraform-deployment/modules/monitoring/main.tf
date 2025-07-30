# =========================================
# MONITORING MODULE - Observability & Security
# =========================================
# 📊 Log Analytics, Application Insights, Key Vault
# 🔐 Centralized monitoring with governance tags

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

# =========================================
# LOCALS
# =========================================

locals {
  # 🏷️ Monitoring-specific tags
  monitoring_tags = merge(var.common_tags, {
    Component = "Monitoring"
    Purpose   = "Observability-Security-Logging"
    Service   = "Log-Analytics-Application-Insights"
  })

  # 🔐 Key Vault naming (must be globally unique, max 24 chars)
  key_vault_name = "kv-${substr(replace(var.resource_prefix, "-", ""), 0, 18)}"
}

# =========================================
# DATA SOURCES
# =========================================

data "azurerm_client_config" "current" {}

# =========================================
# LOG ANALYTICS WORKSPACE
# =========================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # 📊 Configuration
  sku               = "PerGB2018"
  retention_in_days = var.environment == "prod" ? 90 : 30
  daily_quota_gb    = var.environment == "prod" ? 10 : 5

  # 🏷️ Governance tags
  tags = local.monitoring_tags
}

# =========================================
# APPLICATION INSIGHTS
# =========================================

resource "azurerm_application_insights" "main" {
  name                = "appi-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.main.id

  # 📱 Application configuration
  application_type  = "web"
  retention_in_days = var.environment == "prod" ? 90 : 30

  # 🔒 Disable IP masking for better debugging (dev only)
  disable_ip_masking = var.environment == "dev" ? true : false

  # 🏷️ Governance tags
  tags = local.monitoring_tags
}

# =========================================
# KEY VAULT
# =========================================

resource "azurerm_key_vault" "main" {
  name                = local.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  # 🔐 Security configuration
  sku_name                        = "standard"
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true

  # 🔒 Network security
  public_network_access_enabled = var.environment == "prod" ? false : true

  # 🗑️ Soft delete configuration
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.environment == "prod" ? true : false

  # 🏷️ Governance tags
  tags = local.monitoring_tags
}

# =========================================
# KEY VAULT ACCESS POLICIES
# =========================================

# Grant current user/service principal full access
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Create", "Delete", "Get", "List", "Update", "Import", "Backup", "Restore", "Recover"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Backup", "Restore", "Recover"
  ]

  certificate_permissions = [
    "Create", "Delete", "Get", "List", "Update", "Import", "Backup", "Restore", "Recover"
  ]
}

# =========================================
# KEY VAULT SECRETS
# =========================================

# Application Insights connection string
resource "azurerm_key_vault_secret" "application_insights_connection_string" {
  name         = "application-insights-connection-string"
  value        = azurerm_application_insights.main.connection_string
  key_vault_id = azurerm_key_vault.main.id

  tags = local.monitoring_tags

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

# Application Insights instrumentation key
resource "azurerm_key_vault_secret" "application_insights_instrumentation_key" {
  name         = "application-insights-instrumentation-key"
  value        = azurerm_application_insights.main.instrumentation_key
  key_vault_id = azurerm_key_vault.main.id

  tags = local.monitoring_tags

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

# Log Analytics workspace ID
resource "azurerm_key_vault_secret" "log_analytics_workspace_id" {
  name         = "log-analytics-workspace-id"
  value        = azurerm_log_analytics_workspace.main.workspace_id
  key_vault_id = azurerm_key_vault.main.id

  tags = local.monitoring_tags

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

# Log Analytics primary shared key
resource "azurerm_key_vault_secret" "log_analytics_primary_key" {
  name         = "log-analytics-primary-key"
  value        = azurerm_log_analytics_workspace.main.primary_shared_key
  key_vault_id = azurerm_key_vault.main.id

  tags = local.monitoring_tags

  depends_on = [azurerm_key_vault_access_policy.current_user]
}

# =========================================
# LOG ANALYTICS SOLUTIONS
# =========================================

# Container Insights solution
resource "azurerm_log_analytics_solution" "container_insights" {
  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = local.monitoring_tags
}

# Security Center solution
resource "azurerm_log_analytics_solution" "security" {
  solution_name         = "Security"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Security"
  }

  tags = local.monitoring_tags
}

# =========================================
# DIAGNOSTIC SETTINGS (for Key Vault)
# =========================================

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag-keyvault-${var.resource_prefix}"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AuditEvent"

    retention_policy {
      enabled = true
      days    = var.environment == "prod" ? 365 : 30
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = var.environment == "prod" ? 365 : 30
    }
  }
}

# =========================================
# OUTPUTS
# =========================================

output "log_analytics_workspace_id" {
  description = "📊 Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "📊 Log Analytics workspace name"
  value       = azurerm_log_analytics_workspace.main.name
}

output "application_insights_id" {
  description = "📱 Application Insights ID"
  value       = azurerm_application_insights.main.id
}

output "application_insights_name" {
  description = "📱 Application Insights name"
  value       = azurerm_application_insights.main.name
}

output "application_insights_connection_string" {
  description = "🔗 Application Insights connection string"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "application_insights_instrumentation_key" {
  description = "🔑 Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "key_vault_id" {
  description = "🔐 Key Vault ID"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "🔐 Key Vault name"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "🔗 Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}
