# 🌍 **Azure Deployment con Terraform**

Enterprise payment system deployment usando **Infrastructure as Code** con Terraform.

---

## 🎯 **¿Qué vas a aprender?**

- ✅ **Terraform modules** para organización enterprise
- ✅ **State management** y workspaces
- ✅ **PostgreSQL con networking privado** 
- ✅ **Container Apps** multi-servicio
- ✅ **Application Gateway** con WAF
- ✅ **Monitoring completo** con Azure Monitor

---

## 🚀 **Quick Start**

```bash
# 1. Configurar variables
cp terraform.tfvars.example terraform.tfvars.dev
# Editar terraform.tfvars.dev con tus valores

# 2. Inicializar Terraform
terraform init

# 3. Crear workspace
terraform workspace new dev

# 4. Desplegar
terraform plan -var-file="terraform.tfvars.dev"
terraform apply -var-file="terraform.tfvars.dev"
```

---

## 📚 **Documentación por Nivel**

| **Nivel** | **Documento** | **Cuándo Usar** |
|-----------|---------------|----------------|
| 🎓 **Principiante** | [GUIA-INGENIERO-TERRAFORM-PASO-A-PASO.md](./GUIA-INGENIERO-TERRAFORM-PASO-A-PASO.md) | ✅ **Primera vez con Terraform**<br/>✅ Vienes de ARM/Bicep<br/>✅ Necesitas explicaciones detalladas |
| 📖 **Intermedio** | [GUIA-INGENIERO-TERRAFORM.md](./GUIA-INGENIERO-TERRAFORM.md) | ✅ **Ya sabes Terraform básico**<br/>✅ Quieres referencia técnica<br/>✅ Buscas troubleshooting avanzado |
| ⚡ **Rápido** | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | ✅ **Ya desplegaste antes**<br/>✅ Solo necesitas comandos<br/>✅ Referencia rápida |
| 🏗️ **Avanzado** | [docs/AVANZADO-ALTA-DISPONIBILIDAD.md](./docs/AVANZADO-ALTA-DISPONIBILIDAD.md) | ✅ **Alta Disponibilidad PostgreSQL**<br/>✅ Zone-Redundant (99.99% SLA)<br/>✅ Primary Zone 1, Standby Zone 2 |

---

## 📁 **Estructura del Proyecto**

```
azure-terraform-deployment/
├── main.tf                    # 🏗️ Configuración principal
├── variables.tf               # 📝 Variables globales
├── outputs.tf                 # 📤 Outputs del deployment
├── terraform.tfvars.*        # ⚙️ Configuración por ambiente
│
├── modules/                   # 📦 Módulos reutilizables
│   ├── infrastructure/        # 🌐 VNet, subnets, NSGs
│   ├── postgresql/           # 🗄️ Database (básico)
│   ├── postgresql-ha/        # 🏗️ Database con Alta Disponibilidad
│   ├── container-environment/ # 🐳 Container Apps Environment
│   ├── container-apps/       # 📱 Aplicaciones
│   └── monitoring/           # 📊 Azure Monitor, Log Analytics
│
├── environments/             # 🏗️ Configuraciones por ambiente
│   ├── dev/
│   ├── test/
│   └── prod/
│
└── scripts/                  # 🔧 Scripts de automatización
    ├── deploy.sh
    ├── validate.sh
    └── cleanup.sh
```

---

## 🔧 **Comandos Principales**

### 📋 **Setup Inicial**
```bash
# Instalar Terraform (si no lo tienes)
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Login a Azure
az login
az account set --subscription "your-subscription-id"

# Configurar backend remoto (opcional pero recomendado)
terraform init -backend-config="storage_account_name=your-tf-state-storage"
```

### 🚀 **Deployment por Ambiente**
```bash
# Development
terraform workspace select dev || terraform workspace new dev
terraform apply -var-file="terraform.tfvars.dev"

# Production  
terraform workspace select prod || terraform workspace new prod
terraform apply -var-file="terraform.tfvars.prod"
```

### 🔍 **Gestión de Estado**
```bash
# Ver workspaces
terraform workspace list

# Ver estado actual
terraform show

# Import recursos existentes
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/rg-name
```

---

## ⚙️ **Configuración por Ambiente**

### 🧪 **Development** (`terraform.tfvars.dev`)
```hcl
environment = "dev"
location    = "East US 2"

# PostgreSQL básico para desarrollo
sku_name     = "B_Standard_B1ms"
storage_mb   = 32768
high_availability_enabled = false

# Container Apps con recursos mínimos
min_replicas = 1
max_replicas = 2
```

### 🏭 **Production** (`terraform.tfvars.prod`)
```hcl
environment = "prod"
location    = "East US 2"

# PostgreSQL con alta disponibilidad
sku_name     = "GP_Standard_D4s_v3"
storage_mb   = 524288
high_availability_enabled = true
primary_zone = "1"
standby_zone = "2"

# Container Apps escalables
min_replicas = 2
max_replicas = 10
```

---

## 🏗️ **Configuración Avanzada: Alta Disponibilidad**

Para implementar **PostgreSQL con Zone-Redundant High Availability**:

📖 **Ver documentación completa**: [docs/AVANZADO-ALTA-DISPONIBILIDAD.md](./docs/AVANZADO-ALTA-DISPONIBILIDAD.md)

**Características incluidas:**
- 🔄 **Primary en Zone 1, Standby en Zone 2**
- ⚡ **Failover automático < 60 segundos**
- 📊 **99.99% SLA garantizado**
- 💾 **Backup geo-redundante**
- 📈 **Monitoreo avanzado de HA**

---

## 🔍 **Troubleshooting**

### ❌ **Errores Comunes**

```bash
# Error: State lock
terraform force-unlock LOCK_ID

# Error: Provider version
terraform init -upgrade

# Error: Plan inconsistencies  
terraform refresh
terraform plan

# Ver logs detallados
TF_LOG=DEBUG terraform apply
```

### 📊 **Validación del Deployment**
```bash
# Verificar recursos creados
terraform state list

# Verificar outputs
terraform output

# Validar configuración con Azure CLI
az resource list --resource-group "$(terraform output -raw resource_group_name)"
```

---

## 🧹 **Cleanup**

```bash
# Destruir recursos de desarrollo
terraform workspace select dev
terraform destroy -var-file="terraform.tfvars.dev"

# Destruir recursos de producción (¡CUIDADO!)
terraform workspace select prod
terraform destroy -var-file="terraform.tfvars.prod"

# Script automatizado
./scripts/cleanup.sh dev
```

---

## 📊 **Costos Estimados**

| **Ambiente** | **Costo Mensual** | **Componentes Principales** |
|--------------|-------------------|----------------------------|
| **Development** | ~$100-150/mes | Basic PostgreSQL, Container Apps mínimo |
| **Production (sin HA)** | ~$300-400/mes | GP PostgreSQL, Container Apps escalable |
| **Production (con HA)** | ~$600-800/mes | Zone-Redundant PostgreSQL, HA completa |

---

## 🎯 **Próximos Pasos**

1. **🔧 Personalizar**: Ajustar variables según necesidades
2. **🔐 Seguridad**: Implementar Key Vault para secrets
3. **📊 Monitoreo**: Configurar alertas personalizadas
4. **🏗️ HA**: Implementar alta disponibilidad para producción

---

## 📚 **Referencias**

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [Azure Container Apps](https://docs.microsoft.com/azure/container-apps/)
- [PostgreSQL Flexible Server](https://docs.microsoft.com/azure/postgresql/flexible-server/)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

---

> 💡 **Tip**: Usa `terraform plan` antes de cada `apply` y mantén el state en un backend remoto para colaboración en equipo.
