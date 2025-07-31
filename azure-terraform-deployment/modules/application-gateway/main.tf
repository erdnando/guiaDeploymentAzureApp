# =========================================
# APPLICATION GATEWAY MODULE - Load Balancer
# =========================================
# 🌐 Azure Application Gateway with SSL termination
# 🔒 WAF protection and governance tags

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
  description = "🌐 Subnet ID for Application Gateway"
  type        = string
}

variable "backend_fqdn" {
  description = "🎯 Backend FQDN (Container App Frontend)"
  type        = string
}

# =========================================
# LOCALS
# =========================================

locals {
  # 🏷️ Application Gateway specific tags
  gateway_tags = merge(var.common_tags, {
    Component = "Application-Gateway"
    Purpose   = "Load-Balancer-SSL-Termination-WAF"
    Service   = "Azure-Application-Gateway"
  })

  # 📝 Backend and frontend names
  backend_address_pool_name      = "${var.resource_prefix}-beap"
  frontend_port_name             = "${var.resource_prefix}-feport"
  frontend_ip_configuration_name = "${var.resource_prefix}-feip"
  http_setting_name              = "${var.resource_prefix}-be-htst"
  listener_name                  = "${var.resource_prefix}-httplstn"
  request_routing_rule_name      = "${var.resource_prefix}-rqrt"

  # 🔒 SSL and security settings
  ssl_certificate_name = "${var.resource_prefix}-ssl-cert"
  waf_policy_name      = "${var.resource_prefix}-waf-policy"
}

# =========================================
# PUBLIC IP
# =========================================

resource "azurerm_public_ip" "gateway" {
  name                = "pip-${var.resource_prefix}-gateway"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  # 🌐 DNS configuration
  domain_name_label = "${var.resource_prefix}-payment-app"

  # 🏷️ Governance tags
  tags = local.gateway_tags
}

# =========================================
# WAF POLICY
# =========================================

resource "azurerm_web_application_firewall_policy" "main" {
  name                = "wafpol-${var.resource_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  # 🔒 Policy settings
  policy_settings {
    enabled                     = true
    mode                        = var.environment == "prod" ? "Prevention" : "Detection"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  # 🛡️ Managed rules
  managed_rules {
    exclusion {
      match_variable          = "RequestHeaderNames"
      selector                = "x-company-secret-header"
      selector_match_operator = "Equals"
    }

    exclusion {
      match_variable          = "RequestCookieNames"
      selector                = "too-tasty"
      selector_match_operator = "EndsWith"
    }

    managed_rule_set {
      type    = "OWASP"
      version = "3.2"

      rule_group_override {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"

        rule {
          id      = "920300"
          enabled = true
          action  = "Log"
        }

        rule {
          id      = "920440"
          enabled = true
          action  = "Block"
        }
      }
    }
  }

  # 🏷️ Governance tags
  tags = local.gateway_tags
}

# =========================================
# APPLICATION GATEWAY
# =========================================

resource "azurerm_application_gateway" "main" {
  name                = "agw-${var.resource_prefix}"
  resource_group_name = var.resource_group_name
  location            = var.location

  # 📊 SKU configuration
  sku {
    name     = "WAF_v2" # Usar WAF en todos los environments para consistencia
    tier     = "WAF_v2"
    capacity = var.environment == "prod" ? 2 : 1
  }

  # 🌐 Gateway IP configuration
  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = var.subnet_id
  }

  # 🎯 Frontend port
  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  # 🔒 HTTPS Frontend port
  frontend_port {
    name = "${local.frontend_port_name}-https"
    port = 443
  }

  # 🌐 Frontend IP configuration
  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.gateway.id
  }

  # 🎯 Backend address pool
  backend_address_pool {
    name  = local.backend_address_pool_name
    fqdns = [var.backend_fqdn]
  }

  # ⚙️ Backend HTTP settings
  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60

    # 🔍 Health probe
    probe_name = "health-probe"

    # 🏥 Connection draining
    connection_draining {
      enabled           = true
      drain_timeout_sec = 30
    }
  }

  # 🔍 Health probe
  probe {
    name                                      = "health-probe"
    protocol                                  = "Https"
    path                                      = "/"
    host                                      = var.backend_fqdn
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = false

    match {
      status_code = ["200-399"]
    }
  }

  # 👂 HTTP Listener
  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  # 📋 Request routing rule
  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
    priority                   = 1
  }

  # 🔒 WAF Configuration (for production)
  dynamic "waf_configuration" {
    for_each = var.environment == "prod" ? [1] : []
    content {
      enabled          = true
      firewall_mode    = "Prevention"
      rule_set_type    = "OWASP"
      rule_set_version = "3.2"

      disabled_rule_group {
        rule_group_name = "REQUEST-920-PROTOCOL-ENFORCEMENT"
        rules           = [920300, 920440]
      }
    }
  }

  # 🛡️ Associate WAF policy
  firewall_policy_id = azurerm_web_application_firewall_policy.main.id

  # 🔄 Enable HTTP/2
  enable_http2 = true

  # 🏷️ Governance tags
  tags = local.gateway_tags

  # Lifecycle management
  lifecycle {
    create_before_destroy = true
  }
}

# =========================================
# DIAGNOSTIC SETTINGS
# =========================================

resource "azurerm_monitor_diagnostic_setting" "application_gateway" {
  name                       = "diag-agw-${var.resource_prefix}"
  target_resource_id         = azurerm_application_gateway.main.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"

    retention_policy {
      enabled = true
      days    = var.environment == "prod" ? 90 : 30
    }
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"

    retention_policy {
      enabled = true
      days    = var.environment == "prod" ? 90 : 30
    }
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"

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
# DATA SOURCES
# =========================================

data "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.resource_prefix}"
  resource_group_name = var.resource_group_name
}

# =========================================
# OUTPUTS
# =========================================

output "public_ip_address" {
  description = "🌍 Application Gateway public IP address"
  value       = azurerm_public_ip.gateway.ip_address
}

output "public_ip_fqdn" {
  description = "🌐 Application Gateway public IP FQDN"
  value       = azurerm_public_ip.gateway.fqdn
}

output "application_gateway_id" {
  description = "🌐 Application Gateway ID"
  value       = azurerm_application_gateway.main.id
}

output "application_gateway_name" {
  description = "🌐 Application Gateway name"
  value       = azurerm_application_gateway.main.name
}

output "waf_policy_id" {
  description = "🛡️ WAF Policy ID"
  value       = azurerm_web_application_firewall_policy.main.id
}

output "frontend_url" {
  description = "🌐 Frontend URL through Application Gateway"
  value       = "http://${azurerm_public_ip.gateway.fqdn}"
}
