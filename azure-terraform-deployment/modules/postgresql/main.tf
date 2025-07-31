# =========================================
# POSTGRESQL MODULE - Database Services
# =========================================
# 🗄️ Azure Database for PostgreSQL Flexible Server
# 🔐 Private endpoint, SSL enforcement, governance tags

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
  description = "🌐 Subnet ID for database"
  type        = string
}

# =========================================
# LOCALS
# =========================================

locals {
  # 🏷️ Database-specific tags
  database_tags = merge(var.common_tags, {
    Component = "Database"
    Purpose   = "Payment-Data-Storage"
    Service   = "PostgreSQL-Flexible-Server"
  })
}

# =========================================
# RANDOM PASSWORD
# =========================================

resource "random_password" "postgresql_admin" {
  length  = 16
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
  name                  = "postgresql-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgresql.name
  virtual_network_id    = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/vnet-${var.resource_prefix}"

  tags = local.database_tags
} # =========================================
# DATA SOURCES
# =========================================

data "azurerm_client_config" "current" {}

# =========================================
# POSTGRESQL FLEXIBLE SERVER
# =========================================

resource "azurerm_postgresql_flexible_server" "main" {
  name                = "psql-${var.resource_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  # 🔐 Security configuration
  administrator_login    = "psqladmin"
  administrator_password = random_password.postgresql_admin.result

  # 📊 Server configuration
  sku_name = "Standard_B1ms"
  version  = "14"

  # 💾 Storage configuration
  storage_mb            = 32768 # 32GB consistente
  backup_retention_days = var.environment == "prod" ? 35 : 7

  # 🔒 Security settings
  public_network_access_enabled = false # Private access only

  # 🌐 Network configuration  
  delegated_subnet_id = var.subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.postgresql.id

  # 🏷️ Governance tags
  tags = local.database_tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgresql]
}

# =========================================
# DATABASE CONFIGURATION
# =========================================

# Configure PostgreSQL parameters
resource "azurerm_postgresql_flexible_server_configuration" "ssl_enforcement" {
  name      = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_connections" {
  name      = "log_connections"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}

resource "azurerm_postgresql_flexible_server_configuration" "log_disconnections" {
  name      = "log_disconnections"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "on"
}

# =========================================
# DATABASES
# =========================================

# Payment application database
resource "azurerm_postgresql_flexible_server_database" "payment_app" {
  name      = "paymentdb"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Monitoring database
resource "azurerm_postgresql_flexible_server_database" "monitoring" {
  name      = "monitoringdb"
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# =========================================
# FIREWALL RULES (For maintenance only)
# =========================================

# Allow Azure services (disabled by default for security)
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  count            = var.environment == "dev" ? 1 : 0 # Only in dev
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# =========================================
# KEY VAULT SECRET (Connection String)
# =========================================

# Store connection string securely
resource "azurerm_key_vault_secret" "postgresql_connection_string" {
  name         = "postgresql-connection-string"
  value        = "Server=${azurerm_postgresql_flexible_server.main.fqdn};Database=paymentdb;Port=5432;User Id=${azurerm_postgresql_flexible_server.main.administrator_login};Password=${random_password.postgresql_admin.result};Ssl Mode=Require;"
  key_vault_id = data.azurerm_key_vault.main.id

  tags = local.database_tags

  depends_on = [azurerm_postgresql_flexible_server.main]
}

# Data source for existing Key Vault (created in infrastructure or monitoring module)
data "azurerm_key_vault" "main" {
  name                = "kv-${replace(var.resource_prefix, "-", "")}"
  resource_group_name = var.resource_group_name
}

# =========================================
# OUTPUTS
# =========================================

output "server_name" {
  description = "🗄️ PostgreSQL server name"
  value       = azurerm_postgresql_flexible_server.main.name
  sensitive   = true
}

output "server_fqdn" {
  description = "🌐 PostgreSQL server FQDN"
  value       = azurerm_postgresql_flexible_server.main.fqdn
  sensitive   = true
}

output "database_name" {
  description = "📊 Main database name"
  value       = azurerm_postgresql_flexible_server_database.payment_app.name
}

output "administrator_login" {
  description = "👤 Administrator login"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
  sensitive   = true
}

output "connection_string" {
  description = "🔗 PostgreSQL connection string"
  value       = azurerm_key_vault_secret.postgresql_connection_string.value
  sensitive   = true
}

output "private_dns_zone_id" {
  description = "🌐 Private DNS zone ID"
  value       = azurerm_private_dns_zone.postgresql.id
}
