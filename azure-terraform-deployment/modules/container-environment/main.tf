# =========================================
# CONTAINER ENVIRONMENT MODULE - Container App Environment
# =========================================
# 🐳 Azure Container App Environment with monitoring
# 🔐 Private networking and governance tags

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

variable "subnet_id" {
  description = "🌐 Subnet ID for container environment"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "📊 Log Analytics workspace ID"
  type        = string
}

# =========================================
# LOCALS
# =========================================

locals {
  # 🏷️ Container environment specific tags
  container_tags = merge(var.common_tags, {
    Component = "Container-Environment"
    Purpose   = "Container-Orchestration-Platform"
    Service   = "Azure-Container-Apps"
  })
}

# =========================================
# CONTAINER APP ENVIRONMENT
# =========================================

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.resource_prefix}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # 🌐 Network configuration - Internal (private) environment
  infrastructure_subnet_id       = var.subnet_id
  internal_load_balancer_enabled = true

  # 🔒 Zone redundancy for production
  zone_redundancy_enabled = var.environment == "prod" ? true : false

  # 🏷️ Governance tags
  tags = local.container_tags
}

# =========================================
# CONTAINER APP ENVIRONMENT DAPR COMPONENT
# =========================================

# Dapr State Store (using Azure Storage Account)
resource "azurerm_container_app_environment_dapr_component" "state_store" {
  name                         = "statestore"
  container_app_environment_id = azurerm_container_app_environment.main.id
  component_type               = "state.azure.blobstorage"
  version                      = "v1"

  # Ignore changes to avoid drift
  ignore_errors = true

  metadata {
    name  = "accountName"
    value = azurerm_storage_account.dapr.name
  }

  metadata {
    name  = "containerName"
    value = azurerm_storage_container.dapr_state.name
  }

  metadata {
    name  = "accountKey"
    value = azurerm_storage_account.dapr.primary_access_key
  }

  depends_on = [azurerm_storage_account.dapr, azurerm_storage_container.dapr_state]
}

# Dapr Pub/Sub (using Azure Service Bus)
resource "azurerm_container_app_environment_dapr_component" "pubsub" {
  name                         = "pubsub"
  container_app_environment_id = azurerm_container_app_environment.main.id
  component_type               = "pubsub.azure.servicebus"
  version                      = "v1"

  # Ignore changes to avoid drift
  ignore_errors = true

  metadata {
    name  = "connectionString"
    value = azurerm_servicebus_namespace.main.default_primary_connection_string
  }

  depends_on = [azurerm_servicebus_namespace.main]
}

# =========================================
# STORAGE ACCOUNT FOR DAPR STATE
# =========================================

resource "azurerm_storage_account" "dapr" {
  name                     = "st${substr(replace(var.resource_prefix, "-", ""), 0, 15)}dapr"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = var.environment == "prod" ? "GRS" : "LRS"

  # 🔒 Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  # 🌐 Network access
  public_network_access_enabled = false

  # 🔐 Identity configuration
  identity {
    type = "SystemAssigned"
  }

  # 🏷️ Governance tags
  tags = local.container_tags
}

# Storage container for Dapr state
resource "azurerm_storage_container" "dapr_state" {
  name                  = "dapr-state"
  storage_account_name  = azurerm_storage_account.dapr.name
  container_access_type = "private"
}

# =========================================
# SERVICE BUS FOR DAPR PUB/SUB
# =========================================

resource "azurerm_servicebus_namespace" "main" {
  name                = "sb-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"

  # 🔒 Security settings
  public_network_access_enabled = false
  minimum_tls_version           = "1.2"

  # 🔐 Identity configuration
  identity {
    type = "SystemAssigned"
  }

  # 🏷️ Governance tags
  tags = local.container_tags
}

# Service Bus topic for payment events
resource "azurerm_servicebus_topic" "payment_events" {
  name         = "payment-events"
  namespace_id = azurerm_servicebus_namespace.main.id

  # 📊 Topic configuration
  max_size_in_megabytes = 1024
  default_message_ttl   = "P14D" # 14 days

  # 🔄 Duplicate detection
  duplicate_detection_history_time_window = "PT10M" # 10 minutes
}

# Service Bus subscription for payment processing
resource "azurerm_servicebus_subscription" "payment_processing" {
  name     = "payment-processing"
  topic_id = azurerm_servicebus_topic.payment_events.id

  max_delivery_count  = 3
  default_message_ttl = "P14D"

  # 🔄 Dead letter configuration
  dead_lettering_on_message_expiration      = true
  dead_lettering_on_filter_evaluation_error = true
}

# =========================================
# PRIVATE ENDPOINTS
# =========================================

# Private endpoint for Storage Account
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-storage-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "psc-storage-${var.resource_prefix}"
    private_connection_resource_id = azurerm_storage_account.dapr.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = local.container_tags
}

# Private endpoint for Service Bus
resource "azurerm_private_endpoint" "servicebus" {
  name                = "pe-servicebus-${var.resource_prefix}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "psc-servicebus-${var.resource_prefix}"
    private_connection_resource_id = azurerm_servicebus_namespace.main.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }

  tags = local.container_tags
}

# =========================================
# DIAGNOSTIC SETTINGS
# =========================================

# Container App Environment diagnostics
resource "azurerm_monitor_diagnostic_setting" "container_environment" {
  name                       = "diag-cae-${var.resource_prefix}"
  target_resource_id         = azurerm_container_app_environment.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "ContainerAppConsoleLogs"

    retention_policy {
      enabled = true
      days    = var.environment == "prod" ? 90 : 30
    }
  }

  enabled_log {
    category = "ContainerAppSystemLogs"

    retention_policy {
      enabled = true
      days    = var.environment == "prod" ? 90 : 30
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = var.environment == "prod" ? 90 : 30
    }
  }
}

# =========================================
# OUTPUTS
# =========================================

output "container_app_environment_id" {
  description = "🐳 Container App Environment ID"
  value       = azurerm_container_app_environment.main.id
}

output "container_app_environment_name" {
  description = "🐳 Container App Environment name"
  value       = azurerm_container_app_environment.main.name
}

output "container_app_environment_default_domain" {
  description = "🌐 Container App Environment default domain"
  value       = azurerm_container_app_environment.main.default_domain
}

output "storage_account_name" {
  description = "💾 Dapr storage account name"
  value       = azurerm_storage_account.dapr.name
}

output "servicebus_namespace_name" {
  description = "📬 Service Bus namespace name"
  value       = azurerm_servicebus_namespace.main.name
}

output "servicebus_connection_string" {
  description = "🔗 Service Bus connection string"
  value       = azurerm_servicebus_namespace.main.default_primary_connection_string
  sensitive   = true
}
