# 🚀 Guía para Ingenieros: Terraform Azure Implementation

> **🎓 ¿Eres nuevo en Terraform?** Comienza con la [**Guía Paso a Paso para Principiantes**](./GUIA-INGENIERO-TERRAFORM-PASO-A-PASO.md) ⭐
> 
> **📚 ¿Ya tienes experiencia?** Continúa con esta guía de referencia completa.

## 📋 Índice
1. [Introducción a Terraform](#introducción-a-terraform)
2. [Prerequisitos](#prerequisitos)
3. [Estructura del Proyecto](#estructura-del-proyecto)
4. [Conceptos Clave](#conceptos-clave)
5. [Flujo de Trabajo](#flujo-de-trabajo)
6. [Comandos Esenciales](#comandos-esenciales)
7. [Configuración por Ambientes](#configuración-por-ambientes)
8. [**Guía Detallada de Módulos**](#guía-detallada-de-módulos) ⭐
9. [Azure Policy Compliance](#azure-policy-compliance)
10. [Troubleshooting](#troubleshooting)
11. [Mejores Prácticas](#mejores-prácticas)

---

## 🎯 Introducción a Terraform

### ¿Qué es Terraform?
**Terraform** es una herramienta de **Infrastructure as Code (IaC)** que permite:
- 📝 **Definir infraestructura** usando código declarativo (HCL)
- 🌍 **Multi-cloud** - No solo Azure, también AWS, GCP, etc.
- 🔄 **State Management** - Rastrea el estado actual de la infraestructura
- 🛠️ **Plan & Apply** - Previsualiza cambios antes de aplicarlos

### ¿Por qué Terraform vs ARM/BICEP?
| Aspecto | ARM Templates | BICEP | **Terraform** |
|---------|---------------|-------|----------------|
| Cloud Support | ❌ Solo Azure | ❌ Solo Azure | ✅ **Multi-cloud** |
| Sintaxis | 😓 JSON verboso | 😊 DSL limpio | 😊 **HCL declarativo** |
| State Management | Implicit | Implicit | ✅ **Explicit** |
| Ecosystem | Azure only | Azure only | ✅ **Amplio** |
| Learning Curve | Alta | Media | **Media-Alta** |

---

## ⚡ Prerequisitos

### 1. 🛠️ Herramientas Necesarias
```bash
# Terraform CLI
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verificar instalaciones
terraform version    # >= 1.5.0
az version           # Latest
```

### 2. 🔐 Autenticación Azure
```bash
# Login a Azure
az login

# Verificar subscription
az account show

# Set subscription (si tienes múltiples)
az account set --subscription "YOUR-SUBSCRIPTION-ID"
```

### 3. 📂 VS Code Extensions
- **HashiCorp Terraform** - Syntax highlighting & IntelliSense
- **Azure Terraform** - Azure-specific helpers

---

## 🏗️ Estructura del Proyecto

```
azure-terraform-deployment/
├── main.tf                          # 🎯 Orquestador principal
├── environments/                    # 🌍 Configuración por ambiente
│   ├── dev/
│   │   └── terraform.tfvars        # Variables desarrollo
│   └── prod/
│       └── terraform.tfvars        # Variables producción
├── modules/                         # 📦 Módulos reutilizables
│   ├── infrastructure/             # 🏛️ Networking & RG
│   ├── postgresql/                 # 🗄️ Database layer
│   ├── monitoring/                 # 📊 Observability
│   ├── container-environment/      # 🐳 Container platform
│   ├── container-apps/             # 🚀 Applications
│   └── application-gateway/        # 🌐 Load balancer
├── scripts/                        # 🛠️ Automatización
│   ├── deploy-dev.sh              # Deploy desarrollo
│   ├── deploy-prod.sh             # Deploy producción
│   ├── validate-terraform-azure-policies.sh  # Validación
│   └── cleanup-terraform-test-resources.sh   # Limpieza
└── README-terraform-azure-policies.md        # Documentación
```

---

## 🔑 Conceptos Clave

### 1. 📄 **HCL (HashiCorp Configuration Language)**
```hcl
# Declaración de recurso
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.location
  
  tags = local.common_tags
}

# Variables
variable "project" {
  description = "Project name"
  type        = string
}

# Outputs
output "resource_group_name" {
  value = azurerm_resource_group.main.name
}
```

### 2. 🏗️ **Providers**
```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"   # Donde obtener el provider
      version = "~> 3.80"             # Versión compatible
    }
  }
}

provider "azurerm" {
  features {}  # Configuración específica Azure
}
```

### 3. 📦 **Modules**
```hcl
# Usar un módulo
module "infrastructure" {
  source = "./modules/infrastructure"
  
  # Pasar variables al módulo
  project     = var.project
  environment = var.environment
  location    = var.location
}

# Usar output del módulo
resource "azurerm_postgresql_server" "main" {
  subnet_id = module.infrastructure.database_subnet_id
}
```

### 4. 💾 **State Management**
```hcl
# terraform.tfstate - Archivo que rastrea:
# - Qué recursos existen
# - Sus configuraciones actuales  
# - Relaciones entre recursos
# - Metadata de deployment

# ⚠️ IMPORTANTE: Nunca editar manualmente el state!
```

---

## 🔄 Flujo de Trabajo

### 1. 📝 **Desarrollo**
```bash
# 1. Escribir/modificar archivos .tf
# 2. Definir variables en terraform.tfvars
# 3. Crear/actualizar módulos
```

### 2. 🔍 **Validación**
```bash
# Formato del código
terraform fmt

# Validación sintáctica
terraform validate

# Revisión de security/best practices
terraform plan
```

### 3. 🎯 **Deployment**
```bash
# Inicializar (primera vez)
terraform init

# Planificar cambios
terraform plan -var-file="environments/dev/terraform.tfvars"

# Aplicar cambios
terraform apply -var-file="environments/dev/terraform.tfvars"
```

### 4. 🧹 **Limpieza**
```bash
# Destruir recursos (testing)
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

---

## 🛠️ Comandos Esenciales

### Comandos de Lifecycle
```bash
# 🚀 INICIALIZACIÓN (primera vez o cambios en providers)
terraform init
terraform init -upgrade    # Actualizar providers

# 🔍 PLANIFICACIÓN (preview de cambios)
terraform plan                                    # Plan con variables default
terraform plan -var-file="environments/dev/terraform.tfvars"  # Plan con archivo vars
terraform plan -out=plan.tfplan                  # Guardar plan para apply

# ✅ APLICACIÓN (ejecutar cambios)
terraform apply                                   # Apply interactivo
terraform apply -auto-approve                     # Apply sin confirmación
terraform apply plan.tfplan                      # Apply desde plan guardado
terraform apply -var-file="environments/dev/terraform.tfvars"  # Apply con vars

# 🗑️ DESTRUCCIÓN (eliminar recursos)
terraform destroy                                 # Destroy interactivo
terraform destroy -auto-approve                   # Destroy sin confirmación
terraform destroy -var-file="environments/dev/terraform.tfvars"  # Destroy con vars
```

### Comandos de Gestión
```bash
# 📊 INFORMACIÓN
terraform show                     # Mostrar state actual
terraform output                   # Mostrar outputs
terraform output database_host     # Output específico

# 🔧 VALIDACIÓN Y FORMATO
terraform validate                 # Validar sintaxis
terraform fmt                      # Formatear archivos
terraform fmt -check               # Solo verificar formato

# 📈 STATE MANAGEMENT
terraform state list               # Listar recursos en state
terraform state show azurerm_resource_group.main  # Detalles de recurso
terraform refresh                  # Actualizar state desde Azure

# 🔄 WORKSPACE MANAGEMENT (ambientes)
terraform workspace list          # Listar workspaces
terraform workspace new dev       # Crear workspace
terraform workspace select dev    # Cambiar workspace
```

### Scripts de Automatización
```bash
# 🚀 Deploy Development
./scripts/deploy-dev.sh

# 🏭 Deploy Production  
./scripts/deploy-prod.sh

# ✅ Validar Azure Policy Compliance
./scripts/validate-terraform-azure-policies.sh

# 🧹 Cleanup Test Resources
./scripts/cleanup-terraform-test-resources.sh
```

---

## 🌍 Configuración por Ambientes

### Estructura de Variables
```hcl
# environments/dev/terraform.tfvars
project     = "PaymentSystem"
environment = "dev"
location    = "canadacentral"   # Azure Policy compliance

# Database configuration
db_sku_name     = "B_Standard_B1ms"
db_storage_gb   = 32
db_auto_grow    = true

# Container Apps configuration  
container_cpu_requests    = "0.25"
container_memory_requests = "0.5Gi"
container_min_replicas    = 1
container_max_replicas    = 3

# Monitoring
log_analytics_retention_days = 30
```

```hcl
# environments/prod/terraform.tfvars
project     = "PaymentSystem"
environment = "prod"
location    = "canadacentral"   # Azure Policy compliance

# Database configuration
db_sku_name     = "GP_Standard_D2s_v3"
db_storage_gb   = 128
db_auto_grow    = true

# Container Apps configuration
container_cpu_requests    = "1.0"
container_memory_requests = "2Gi"
container_min_replicas    = 3
container_max_replicas    = 10

# Monitoring
log_analytics_retention_days = 90
```

### Deploy por Ambiente
```bash
# 🧪 DESARROLLO
cd azure-terraform-deployment
terraform init
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"

# 🏭 PRODUCCIÓN
cd azure-terraform-deployment
terraform init
terraform plan -var-file="environments/prod/terraform.tfvars"
terraform apply -var-file="environments/prod/terraform.tfvars"
```

---

## 📦 Guía Detallada de Módulos

Esta sección te explica cada módulo del sistema, qué hace, cómo funciona y cómo ejecutarlo individualmente para testing.

### 🏗️ Módulo 1: Infrastructure (Fundación)

**📍 Ubicación:** `modules/infrastructure/`

**🎯 Propósito:**
- Crear la base de networking para toda la aplicación
- Resource Group con governance tags
- Virtual Network con subnets segmentadas
- Network Security Groups para seguridad

**📋 Recursos Creados:**
```hcl
# Resource Group
azurerm_resource_group.main                    # rg-PaymentSystem-dev
# Networking
azurerm_virtual_network.main                   # vnet-paymentsystem-dev  
azurerm_subnet.container_apps                  # subnet-container-apps
azurerm_subnet.database                        # subnet-database
azurerm_subnet.gateway                         # subnet-gateway
azurerm_network_security_group.container_apps  # nsg-container-apps
azurerm_network_security_group.database        # nsg-database  
azurerm_network_security_group.gateway         # nsg-gateway
```

**🔧 Testing Individual:**
```bash
# 1. Crear archivo test temporal
cat > test-infrastructure.tf << 'EOF'
module "infrastructure" {
  source = "./modules/infrastructure"
  
  project         = "PaymentSystem"
  environment     = "test"
  location        = "canadacentral"
  app_name        = "payment-app"
  cost_center     = "IT-Payment-Systems"
  owner           = "DevOps-Team"
  resource_prefix = "test"
  
  common_tags = {
    Project     = "PaymentSystem"
    Environment = "test"
    CostCenter  = "IT-Payment-Systems"
    Owner       = "DevOps-Team"
    CreatedBy   = "Terraform"
    ManagedBy   = "IaC-Terraform"
    Purpose     = "Payment-Processing-System"
    Compliance  = "Azure-Policy-Compliant"
  }
}

output "resource_group_name" {
  value = module.infrastructure.resource_group_name
}

output "vnet_id" {
  value = module.infrastructure.vnet_id
}
EOF

# 2. Ejecutar test
terraform init
terraform plan
terraform apply -auto-approve

# 3. Verificar en Azure Portal
az resource list --resource-group "rg-PaymentSystem-test" --output table

# 4. Cleanup
terraform destroy -auto-approve
rm test-infrastructure.tf
```

### 🗄️ Módulo 2: PostgreSQL (Base de Datos)

**📍 Ubicación:** `modules/postgresql/`

**🎯 Propósito:**
- PostgreSQL Flexible Server para datos transaccionales
- Private endpoint para conectividad segura
- Private DNS Zone para resolución interna
- Key Vault integration para connection strings

**📋 Recursos Creados:**
```hcl
# Database
azurerm_postgresql_flexible_server.main        # psql-paymentsystem-dev
azurerm_postgresql_flexible_server_database.main  # payment_db
# Private Connectivity
azurerm_private_endpoint.postgresql            # pe-postgresql-dev
azurerm_private_dns_zone.postgresql            # privatelink.postgres.database.azure.com
azurerm_private_dns_zone_virtual_network_link.postgresql
# Secrets Management  
azurerm_key_vault_secret.database_connection_string
```

**🔧 Testing Individual:**
```bash
# 1. Primero necesitas infrastructure
terraform apply -target=module.infrastructure -var-file="environments/dev/terraform.tfvars"

# 2. Crear archivo test para postgresql
cat > test-postgresql.tf << 'EOF'
# Usar infrastructure existente
data "azurerm_resource_group" "main" {
  name = "rg-PaymentSystem-dev"
}

data "azurerm_subnet" "database" {
  name                 = "subnet-database"
  virtual_network_name = "vnet-paymentsystem-dev"
  resource_group_name  = data.azurerm_resource_group.main.name
}

module "postgresql" {
  source = "./modules/postgresql"
  
  project              = "PaymentSystem"
  environment          = "dev"
  location             = "canadacentral"
  cost_center          = "IT-Payment-Systems"
  owner                = "DevOps-Team"
  resource_prefix      = "test"
  resource_group_name  = data.azurerm_resource_group.main.name
  vnet_id              = data.azurerm_subnet.database.virtual_network_id
  database_subnet_id   = data.azurerm_subnet.database.id
  key_vault_id         = "/subscriptions/.../vaults/kv-test"  # Usar KV existente
  
  # Database configuration
  db_sku_name   = "B_Standard_B1ms"
  db_storage_gb = 32
  db_auto_grow  = true
  
  common_tags = {
    Project = "PaymentSystem"
    Environment = "dev"
  }
}

output "database_fqdn" {
  value = module.postgresql.database_fqdn
}
EOF

# 3. Ejecutar test
terraform plan -target=module.postgresql
terraform apply -target=module.postgresql -auto-approve

# 4. Verificar conectividad
az postgres flexible-server list --resource-group "rg-PaymentSystem-dev" --output table
```

### 📊 Módulo 3: Monitoring (Observabilidad)

**📍 Ubicación:** `modules/monitoring/`

**🎯 Propósito:**
- Log Analytics Workspace para logs centralizados
- Application Insights para APM
- Key Vault para secrets management
- Diagnostic settings para recursos

**📋 Recursos Creados:**
```hcl
# Observability
azurerm_log_analytics_workspace.main           # law-paymentsystem-dev
azurerm_application_insights.main              # ai-paymentsystem-dev
# Security
azurerm_key_vault.main                         # kv-paymentsystem-dev
azurerm_key_vault_access_policy.terraform      # Access para Terraform
```

**🔧 Testing Individual:**
```bash
# 1. Test monitoring standalone
cat > test-monitoring.tf << 'EOF'
module "monitoring" {
  source = "./modules/monitoring"
  
  project                      = "PaymentSystem"
  environment                  = "test"
  location                     = "canadacentral"
  cost_center                  = "IT-Payment-Systems"
  owner                        = "DevOps-Team"
  resource_prefix              = "test"
  resource_group_name          = "rg-PaymentSystem-test"  # Debe existir
  log_analytics_retention_days = 30
  
  common_tags = {
    Project = "PaymentSystem"
    Environment = "test"
  }
}

output "log_analytics_workspace_id" {
  value = module.monitoring.log_analytics_workspace_id
}

output "application_insights_key" {
  value = module.monitoring.application_insights_instrumentation_key
  sensitive = true
}
EOF

# 2. Ejecutar
terraform apply -target=module.monitoring -auto-approve

# 3. Verificar workspaces
az monitor log-analytics workspace list --resource-group "rg-PaymentSystem-test"

# 4. Test query en Log Analytics
az monitor log-analytics query --workspace "law-paymentsystem-test" --analytics-query "Usage | limit 10"
```

### 🐳 Módulo 4: Container Environment (Plataforma)

**📍 Ubicación:** `modules/container-environment/`

**🎯 Propósito:**
- Container App Environment para hosting apps
- Storage Account para Dapr state management
- Service Bus para event-driven architecture
- Configuración de auto-scaling y networking

**📋 Recursos Creados:**
```hcl
# Container Platform
azurerm_container_app_environment.main         # cae-paymentsystem-dev
# Dapr Components
azurerm_storage_account.dapr                   # stdaprpaymentdev
azurerm_storage_container.dapr_state           # dapr-state
azurerm_servicebus_namespace.main              # sb-paymentsystem-dev
azurerm_servicebus_queue.payments              # payment-events
```

**🔧 Testing Individual:**
```bash
# 1. Requiere infrastructure + monitoring
terraform apply -target=module.infrastructure -target=module.monitoring \
  -var-file="environments/dev/terraform.tfvars"

# 2. Test container environment
cat > test-container-env.tf << 'EOF'
data "azurerm_resource_group" "main" {
  name = "rg-PaymentSystem-dev"
}

data "azurerm_log_analytics_workspace" "main" {
  name                = "law-paymentsystem-dev"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "container_apps" {
  name                 = "subnet-container-apps"
  virtual_network_name = "vnet-paymentsystem-dev"
  resource_group_name  = data.azurerm_resource_group.main.name
}

module "container_environment" {
  source = "./modules/container-environment"
  
  project                      = "PaymentSystem"
  environment                  = "dev"
  location                     = "canadacentral"
  cost_center                  = "IT-Payment-Systems"
  owner                        = "DevOps-Team"
  resource_prefix              = "test"
  resource_group_name          = data.azurerm_resource_group.main.name
  log_analytics_workspace_id   = data.azurerm_log_analytics_workspace.main.id
  container_apps_subnet_id     = data.azurerm_subnet.container_apps.id
  
  common_tags = {
    Project = "PaymentSystem"
    Environment = "dev"
  }
}

output "container_app_environment_id" {
  value = module.container_environment.container_app_environment_id
}
EOF

# 3. Deploy
terraform apply -target=module.container_environment -auto-approve

# 4. Verificar container environment
az containerapp env list --resource-group "rg-PaymentSystem-dev" --output table
```

### 🚀 Módulo 5: Container Apps (Aplicaciones)

**📍 Ubicación:** `modules/container-apps/`

**🎯 Propósito:**
- Payment API container app
- Frontend web container app
- Auto-scaling configuration
- Managed identity para security

**📋 Recursos Creados:**
```hcl
# Applications
azurerm_user_assigned_identity.container_apps  # id-container-apps-dev
azurerm_container_app.payment_api              # ca-payment-api-dev
azurerm_container_app.frontend                 # ca-frontend-dev
```

**🔧 Testing Individual:**
```bash
# 1. Requiere todos los módulos anteriores
terraform apply \
  -target=module.infrastructure \
  -target=module.monitoring \
  -target=module.container_environment \
  -var-file="environments/dev/terraform.tfvars"

# 2. Test container apps
terraform apply -target=module.container_apps \
  -var-file="environments/dev/terraform.tfvars"

# 3. Verificar apps running
az containerapp list --resource-group "rg-PaymentSystem-dev" --output table

# 4. Test connectivity
az containerapp show --name "ca-payment-api-dev" --resource-group "rg-PaymentSystem-dev" \
  --query "properties.configuration.ingress.fqdn"

# 5. Test API endpoint (si está configurado con ingress)
FQDN=$(az containerapp show --name "ca-payment-api-dev" --resource-group "rg-PaymentSystem-dev" \
  --query "properties.configuration.ingress.fqdn" -o tsv)
curl https://$FQDN/health
```

### 🌐 Módulo 6: Application Gateway (Load Balancer)

**📍 Ubicación:** `modules/application-gateway/`

**🎯 Propósito:**
- Application Gateway con WAF protection
- Public IP para acceso externo
- Backend pool configuration para container apps
- SSL termination y traffic routing

**📋 Recursos Creados:**
```hcl
# Load Balancer
azurerm_public_ip.gateway                      # pip-gateway-dev
azurerm_application_gateway.main               # agw-paymentsystem-dev
azurerm_web_application_firewall_policy.main   # waf-paymentsystem-dev
```

**🔧 Testing Individual:**
```bash
# 1. Requiere todos los módulos (especialmente container-apps para backend)
terraform apply \
  -target=module.infrastructure \
  -target=module.monitoring \
  -target=module.container_environment \
  -target=module.container_apps \
  -var-file="environments/dev/terraform.tfvars"

# 2. Deploy Application Gateway
terraform apply -target=module.application_gateway \
  -var-file="environments/dev/terraform.tfvars"

# 3. Verificar Application Gateway
az network application-gateway list --resource-group "rg-PaymentSystem-dev" --output table

# 4. Obtener IP pública
az network public-ip show --name "pip-gateway-dev" --resource-group "rg-PaymentSystem-dev" \
  --query "ipAddress" -o tsv

# 5. Test de conectividad end-to-end
PUBLIC_IP=$(az network public-ip show --name "pip-gateway-dev" \
  --resource-group "rg-PaymentSystem-dev" --query "ipAddress" -o tsv)
curl http://$PUBLIC_IP/health

# 6. Verificar WAF logs (opcional)
az monitor log-analytics query \
  --workspace "law-paymentsystem-dev" \
  --analytics-query "AzureDiagnostics | where ResourceProvider == 'MICROSOFT.NETWORK' | limit 10"
```

---

## 🔄 Ejecución Completa Paso a Paso

### Opción 1: Deploy Completo Automático
```bash
# 🚀 Deploy todo el stack de una vez
cd azure-terraform-deployment
terraform init
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"
```

### Opción 2: Deploy Incremental por Módulos
```bash
# 🏗️ Paso 1: Foundation
terraform apply -target=module.infrastructure -var-file="environments/dev/terraform.tfvars"

# 📊 Paso 2: Monitoring  
terraform apply -target=module.monitoring -var-file="environments/dev/terraform.tfvars"

# 🗄️ Paso 3: Database
terraform apply -target=module.postgresql -var-file="environments/dev/terraform.tfvars"

# 🐳 Paso 4: Container Platform
terraform apply -target=module.container_environment -var-file="environments/dev/terraform.tfvars"

# 🚀 Paso 5: Applications
terraform apply -target=module.container_apps -var-file="environments/dev/terraform.tfvars"

# 🌐 Paso 6: Load Balancer
terraform apply -target=module.application_gateway -var-file="environments/dev/terraform.tfvars"
```

### Opción 3: Testing Individual de Módulos
```bash
# Para cada módulo usar los ejemplos de testing arriba
# Permite entender cada componente de forma aislada
# Ideal para debugging y learning
```

---

## 🏛️ Azure Policy Compliance

### 1. 🏷️ Required Tag Policy
**Policy:** "Require a tag on resources"
**Tag:** Project

```hcl
# ✅ CORRECTO - main.tf
variable "project" {
  description = "🏷️ Project name - REQUIRED by Azure Policy"
  type        = string
  validation {
    condition     = length(var.project) > 0
    error_message = "❌ Project name is required for Azure Policy compliance."
  }
}

locals {
  common_tags = {
    Project     = var.project          # ✅ REQUERIDO por Azure Policy
    Environment = var.environment
    CostCenter  = var.cost_center
    Owner       = var.owner
    CreatedBy   = "Terraform"
    ManagedBy   = "IaC-Terraform"
    Purpose     = "Payment-Processing-System"
    Compliance  = "Azure-Policy-Compliant"
  }
}

# Aplicar tags a todos los recursos
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  
  tags = local.common_tags  # ✅ Incluye Project tag
}
```

### 2. 🌍 Location Restriction Policy
**Policy:** "Allowed locations"
**Location:** canadacentral

```hcl
# ✅ CORRECTO - main.tf
variable "location" {
  description = "🌍 Azure region - RESTRICTED by Azure Policy to canadacentral"
  type        = string
  default     = "canadacentral"
  
  validation {
    condition     = var.location == "canadacentral"
    error_message = "❌ Location must be 'canadacentral' for Azure Policy compliance."
  }
}

# Todos los recursos usan la location validada
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location  # ✅ Solo acepta canadacentral
  tags     = local.common_tags
}
```

### 3. ✅ Validación Automática
```bash
# Script de validación integrado
./scripts/validate-terraform-azure-policies.sh

# Output esperado:
# ✅ Azure Policy Validation Results:
# ✅ Project tag validation: PASSED
# ✅ Location policy validation: PASSED  
# ✅ All 8 governance tags present: PASSED
# ✅ Terraform syntax validation: PASSED
# ✅ Azure Policy compliance: VERIFIED
```

---

## 🔧 Troubleshooting

### Errores Comunes

#### 1. ❌ **Provider Version Mismatch**
```bash
Error: Failed to query available provider packages
```
**Solución:**
```bash
# Limpiar cache y reinicializar
rm -rf .terraform .terraform.lock.hcl
terraform init
```

#### 2. ❌ **State Lock**
```bash
Error: Error acquiring the state lock
```
**Solución:**
```bash
# Forzar unlock (usar con precaución)
terraform force-unlock LOCK-ID
```

#### 3. ❌ **Resource Already Exists**
```bash
Error: A resource with the ID already exists
```
**Solución:**
```bash
# Importar recurso existente
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/my-rg

# O eliminar del state
terraform state rm azurerm_resource_group.main
```

#### 4. ❌ **Authentication Failed**
```bash
Error: building account: could not acquire access token
```
**Solución:**
```bash
# Re-login a Azure
az logout
az login
az account show
```

#### 5. ❌ **Azure Policy Violation**
```bash
Error: The template deployment failed with policy violation
```
**Solución:**
```bash
# Verificar compliance
./scripts/validate-terraform-azure-policies.sh

# Asegurar Project tag está presente
grep -r "Project.*=" *.tf modules/*/

# Verificar location es canadacentral
grep -r "location.*=" *.tf modules/*/
```

### Debugging Tips

```bash
# 🔍 Logs detallados
export TF_LOG=DEBUG
terraform plan

# 📊 Inspeccionar state
terraform show
terraform state list

# 🔄 Refresh state desde Azure
terraform refresh

# 📋 Verificar configuración actual
terraform output -json

# 🧹 Limpiar cache
rm -rf .terraform
terraform init
```

---

## ⭐ Mejores Prácticas

### 1. 📁 **Organización de Código**
```bash
✅ DO: Usar módulos para componentes reutilizables
✅ DO: Separar variables por archivo (variables.tf)
✅ DO: Usar locals para valores calculados
✅ DO: Comentar código complejo
❌ DON'T: Hardcodear valores en recursos
❌ DON'T: Módulos monolíticos gigantes
```

### 2. 🔐 **Seguridad**
```bash
✅ DO: Usar variables para secrets
✅ DO: Habilitar encryption at rest
✅ DO: Implementar RBAC apropiado
✅ DO: Usar Azure Key Vault para secrets
❌ DON'T: Hardcodear passwords/keys
❌ DON'T: Commitear archivos .tfstate
```

### 3. 💾 **State Management**
```bash
✅ DO: Usar remote state para equipos
✅ DO: Implementar state locking
✅ DO: Backup del state regularmente
❌ DON'T: Editar state manualmente
❌ DON'T: Compartir state files locales
```

### 4. 🌍 **Multi-Environment**
```bash
✅ DO: Usar workspaces o directorios separados
✅ DO: Variables específicas por ambiente
✅ DO: Validar antes de apply en prod
❌ DON'T: Mixing environments en same state
❌ DON'T: Deploy directo a prod sin testing
```

### 5. 📊 **Monitoring & Compliance**
```bash
✅ DO: Implementar governance tags consistentes
✅ DO: Usar Azure Policy para compliance
✅ DO: Monitorear costs con tags
✅ DO: Automatizar validaciones pre-deploy
❌ DON'T: Ignorar policy violations
❌ DON'T: Deploy sin governance tags
```

### 6. 🔄 **CI/CD Integration**
```bash
# Ejemplo Azure DevOps pipeline
stages:
- stage: Validate
  jobs:
  - job: TerraformValidate
    steps:
    - script: terraform init
    - script: terraform validate
    - script: ./scripts/validate-terraform-azure-policies.sh

- stage: Plan
  jobs:
  - job: TerraformPlan
    steps:
    - script: terraform plan -var-file="environments/dev/terraform.tfvars"

- stage: Apply
  jobs:
  - job: TerraformApply
    steps:
    - script: terraform apply -auto-approve -var-file="environments/dev/terraform.tfvars"
```

---

## 🎯 Ejemplo Práctico: Deploy Completo

### Paso a Paso
```bash
# 1. 📂 Clonar y navegar
cd azure-terraform-deployment

# 2. 🔐 Autenticación Azure
az login
az account set --subscription "YOUR-SUBSCRIPTION-ID"

# 3. 🚀 Inicializar Terraform
terraform init

# 4. ✅ Validar Azure Policy compliance
./scripts/validate-terraform-azure-policies.sh

# 5. 🔍 Planificar deployment desarrollo
terraform plan -var-file="environments/dev/terraform.tfvars"

# 6. ✅ Aplicar si todo se ve bien
terraform apply -var-file="environments/dev/terraform.tfvars"

# 7. 📊 Verificar outputs
terraform output

# 8. 🧪 Hacer testing de la aplicación
# ... testing manual/automatizado ...

# 9. 🧹 Cleanup (opcional para testing)
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

### Verificación Post-Deploy
```bash
# 🔍 Verificar recursos en Azure Portal
az resource list --resource-group "rg-PaymentSystem-dev" --output table

# 📊 Verificar tags compliance
az tag list --resource-id "/subscriptions/.../resourceGroups/rg-PaymentSystem-dev"

# 🌐 Verificar connectivity
az network vnet list --resource-group "rg-PaymentSystem-dev"

# 📈 Verificar monitoring
az monitor log-analytics workspace show --resource-group "rg-PaymentSystem-dev" --workspace-name "law-paymentsystem-dev"
```

---

## 📚 Recursos Adicionales

### 📖 Documentación Oficial
- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs
- **Terraform CLI**: https://developer.hashicorp.com/terraform/docs
- **Azure Policy**: https://docs.microsoft.com/azure/governance/policy/

### 🛠️ Herramientas Útiles
- **terraform-docs**: Generar documentación automática
- **tflint**: Linter para Terraform
- **checkov**: Security scanning
- **terraform-compliance**: BDD testing

### 🎓 Learning Path
1. **Básico**: Terraform fundamentals + Azure basics
2. **Intermedio**: Modules + State management
3. **Avanzado**: CI/CD + Multi-cloud + Governance

---

## 🎉 Conclusión

**¡Felicidades!** 🎯 Ahora tienes el conocimiento para:

- ✅ **Entender** la arquitectura Terraform
- ✅ **Navegar** el código con confianza  
- ✅ **Deployer** ambientes de desarrollo/producción
- ✅ **Mantener** compliance con Azure Policies
- ✅ **Troubleshootear** problemas comunes
- ✅ **Aplicar** mejores prácticas

**Siguiente paso**: ¡Practica con deployments en ambiente de desarrollo!

**Recursos de soporte**:
- Documentación en README-terraform-azure-policies.md
- Scripts de automatización en /scripts/
- Configuración de ejemplo en /environments/

---

*🤝 Happy Terraforming! Recuerda: La infraestructura es código, trátala como tal.*
