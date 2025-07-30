# =========================================
# INFRASTRUCTURE MODULE - Foundation Resources
# =========================================
# 🏗️ Resource Group, Virtual Network, Subnets
# 🏷️ Azure Policy compliant with governance tags

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
  description = "🌍 Azure region - canadacentral per policy"
  type        = string
}

variable "app_name" {
  description = "📱 Application name"
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

# =========================================
# LOCALS
# =========================================

locals {
  # 🏷️ Module-specific tags
  infrastructure_tags = merge(var.common_tags, {
    Component = "Infrastructure"
    Purpose   = "Foundation-Network-Resources"
  })
}

# =========================================
# RESOURCE GROUP
# =========================================

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.resource_prefix}-tf"
  location = var.location

  tags = local.infrastructure_tags

  lifecycle {
    ignore_changes = [tags["CreatedDate"]]
  }
}

# =========================================
# VIRTUAL NETWORK
# =========================================

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.resource_prefix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.infrastructure_tags
}

# =========================================
# SUBNETS
# =========================================

# 🐳 Container Apps subnet
resource "azurerm_subnet" "container_apps" {
  name                 = "snet-container-apps"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "Microsoft.App/environments"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# 🗄️ Database subnet with private endpoint support
resource "azurerm_subnet" "database" {
  name                 = "snet-database"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  # Enable private endpoints
  private_endpoint_network_policies = "Disabled"
} # 🌐 Application Gateway subnet
resource "azurerm_subnet" "gateway" {
  name                 = "snet-gateway"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.3.0/24"]
}

# =========================================
# NETWORK SECURITY GROUPS
# =========================================

# 🔒 Container Apps NSG
resource "azurerm_network_security_group" "container_apps" {
  name                = "nsg-container-apps-${var.resource_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.infrastructure_tags
}

# Allow HTTP/HTTPS traffic to containers
resource "azurerm_network_security_rule" "container_apps_http" {
  name                        = "AllowHTTP"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.container_apps.name
}

# 🔒 Database NSG
resource "azurerm_network_security_group" "database" {
  name                = "nsg-database-${var.resource_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.infrastructure_tags
}

# Allow PostgreSQL traffic from container subnet
resource "azurerm_network_security_rule" "database_postgresql" {
  name                        = "AllowPostgreSQL"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5432"
  source_address_prefix       = "10.0.1.0/24" # Container subnet
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.database.name
}

# 🔒 Gateway NSG
resource "azurerm_network_security_group" "gateway" {
  name                = "nsg-gateway-${var.resource_prefix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.infrastructure_tags
}

# Allow HTTP/HTTPS from internet
resource "azurerm_network_security_rule" "gateway_http" {
  name                        = "AllowHTTPSInternet"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.gateway.name
}

# Gateway management ports
resource "azurerm_network_security_rule" "gateway_management" {
  name                        = "AllowGatewayManager"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "65200-65535"
  source_address_prefix       = "GatewayManager"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.gateway.name
}

# =========================================
# SUBNET-NSG ASSOCIATIONS
# =========================================

resource "azurerm_subnet_network_security_group_association" "container_apps" {
  subnet_id                 = azurerm_subnet.container_apps.id
  network_security_group_id = azurerm_network_security_group.container_apps.id
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database.id
}

resource "azurerm_subnet_network_security_group_association" "gateway" {
  subnet_id                 = azurerm_subnet.gateway.id
  network_security_group_id = azurerm_network_security_group.gateway.id
}

# =========================================
# OUTPUTS
# =========================================

output "resource_group_name" {
  description = "📁 Resource group name"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "🌍 Resource group location"
  value       = azurerm_resource_group.main.location
}

output "virtual_network_id" {
  description = "🌐 Virtual network ID"
  value       = azurerm_virtual_network.main.id
}

output "virtual_network_name" {
  description = "🌐 Virtual network name"
  value       = azurerm_virtual_network.main.name
}

output "container_subnet_id" {
  description = "🐳 Container Apps subnet ID"
  value       = azurerm_subnet.container_apps.id
}

output "database_subnet_id" {
  description = "🗄️ Database subnet ID"
  value       = azurerm_subnet.database.id
}

output "gateway_subnet_id" {
  description = "🌐 Gateway subnet ID"
  value       = azurerm_subnet.gateway.id
}
