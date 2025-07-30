# 🎯 Referencia Rápida: Terraform Azure

## 🚀 Inicio Rápido (5 minutos)

### ✅ Pre-requisitos Check
```bash
# Verificar herramientas
az --version          # Azure CLI
terraform version     # Terraform CLI >= 1.5

# Login a Azure
az login
az account show

# Validar proyecto
cd azure-terraform-deployment
./scripts/validate-guide.sh
```

### 🎯 Deploy Rápido
```bash
# 1. Inicializar
terraform init

# 2. Validar compliance
./scripts/validate-terraform-azure-policies.sh

# 3. Planificar
terraform plan -var-file="environments/dev/terraform.tfvars"

# 4. Aplicar
terraform apply -var-file="environments/dev/terraform.tfvars"

# 5. Verificar
terraform output
```

### 🧹 Cleanup Rápido
```bash
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

---

## 📚 Guías Disponibles

| **Nivel** | **Guía** | **Cuándo Usar** |
|-----------|----------|----------------|
| 🎓 **Principiante** | [GUIA-INGENIERO-TERRAFORM-PASO-A-PASO.md](./GUIA-INGENIERO-TERRAFORM-PASO-A-PASO.md) | ✅ **Primera vez con Terraform**<br/>✅ Quieres entender cada paso<br/>✅ Necesitas explicaciones detalladas |
| 📖 **Intermedio** | [GUIA-INGENIERO-TERRAFORM.md](./GUIA-INGENIERO-TERRAFORM.md) | ✅ **Ya sabes Terraform básico**<br/>✅ Quieres referencia completa<br/>✅ Buscas troubleshooting avanzado |
| ⚡ **Rápido** | [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | ✅ **Ya desplegaste antes**<br/>✅ Solo necesitas comandos<br/>✅ Referencia rápida |

---

## 🛠️ Comandos Más Usados

### 🔄 Lifecycle
```bash
terraform init                    # Inicializar providers
terraform validate                # Validar sintaxis
terraform plan                    # Previsualizar cambios
terraform apply                   # Aplicar cambios
terraform destroy                 # Eliminar recursos
```

### 📊 Información
```bash
terraform output                  # Ver outputs
terraform state list             # Listar recursos
terraform state show <resource>  # Detalles de recurso
terraform show                   # Estado completo
```

### 🔧 Debugging
```bash
terraform fmt                     # Formatear código
terraform validate                # Validar sintaxis
export TF_LOG=DEBUG              # Logs detallados
terraform refresh                # Actualizar state
```

---

## 🏗️ Módulos del Sistema

| **Orden** | **Módulo** | **Propósito** | **Deploy Individual** |
|-----------|------------|---------------|----------------------|
| 1️⃣ | `infrastructure` | Networking base | `terraform apply -target=module.infrastructure` |
| 2️⃣ | `monitoring` | Observabilidad | `terraform apply -target=module.monitoring` |
| 3️⃣ | `postgresql` | Base de datos | `terraform apply -target=module.postgresql` |
| 4️⃣ | `container-environment` | Plataforma apps | `terraform apply -target=module.container_environment` |
| 5️⃣ | `container-apps` | Aplicaciones | `terraform apply -target=module.container_apps` |
| 6️⃣ | `application-gateway` | Load balancer | `terraform apply -target=module.application_gateway` |

---

## 🏛️ Azure Policy Compliance

### ✅ Políticas Implementadas
| **Policy** | **Requirement** | **Implementation** |
|------------|----------------|-------------------|
| **Required Tag** | Tag `Project` en todos los recursos | `common_tags.Project = var.project` |
| **Location Restriction** | Solo `canadacentral` | `location = "canadacentral"` |

### 🔍 Validación
```bash
# Validar compliance
./scripts/validate-terraform-azure-policies.sh

# ¿Qué buscar?
# ✅ Project tag validation: PASSED
# ✅ Location policy validation: PASSED
# ✅ All 8 governance tags present: PASSED
```

---

## 🌍 Ambientes

### 📁 Configuración
```bash
# Desarrollo
terraform apply -var-file="environments/dev/terraform.tfvars"

# Producción  
terraform apply -var-file="environments/prod/terraform.tfvars"
```

### 🔧 Diferencias Clave
| **Aspecto** | **Dev** | **Prod** |
|-------------|---------|----------|
| **DB SKU** | B_Standard_B1ms | GP_Standard_D2s_v3 |
| **Storage** | 32GB | 128GB |
| **Replicas** | 1-3 | 3-10 |
| **CPU** | 0.25 cores | 1.0 cores |
| **Memory** | 0.5Gi | 2Gi |

---

## 🚨 Troubleshooting Rápido

### ❌ Errores Comunes

#### Error: "Resource already exists"
```bash
# Solución: Importar recurso
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/rg-name
```

#### Error: "State lock"
```bash
# Solución: Forzar unlock (cuidado!)
terraform force-unlock LOCK-ID
```

#### Error: "Provider version conflict"
```bash
# Solución: Limpiar y reinicializar
rm -rf .terraform .terraform.lock.hcl
terraform init
```

#### Error: "Azure Policy violation"
```bash
# Solución: Verificar compliance
./scripts/validate-terraform-azure-policies.sh
# Asegurar Project tag y location canadacentral
```

---

## 📊 Outputs Importantes

### 🔍 Información del Sistema
```bash
terraform output                           # Todos los outputs
terraform output resource_group_name      # Nombre del RG
terraform output application_gateway_public_ip  # IP pública
terraform output database_fqdn            # FQDN de la BD
```

### 📋 Verificación Post-Deploy
```bash
# Listar recursos creados
az resource list --resource-group "$(terraform output -raw resource_group_name)" --output table

# IP pública del sistema
curl http://$(terraform output -raw application_gateway_public_ip)/health
```

---

## 💰 Gestión de Costos

### 🧹 Cleanup Testing
```bash
# Eliminar recursos de testing
terraform destroy -var-file="environments/dev/terraform.tfvars"

# Script automatizado
./scripts/cleanup-terraform-test-resources.sh
```

### 📊 Monitoring de Costos
```bash
# Ver costos por tag
az consumption usage list --start-date 2024-01-01 --end-date 2024-01-31 --include-meter-details
```

---

## 🎯 Próximos Pasos

### 🚀 Para Principiantes
1. ✅ Completa [GUIA-INGENIERO-TERRAFORM-PASO-A-PASO.md](./GUIA-INGENIERO-TERRAFORM-PASO-A-PASO.md)
2. 🧪 Practica deploy/destroy varias veces
3. 🔧 Modifica configuraciones y observa cambios

### 📈 Para Intermedios
1. 🏭 Deploy a ambiente producción
2. 🔄 Implementa CI/CD pipeline
3. 📊 Configura remote state backend
4. 🔐 Agrega módulos adicionales (Redis, etc.)

### 🏆 Para Avanzados
1. 🌍 Multi-region deployment
2. 🔐 Advanced security with Azure Security Center
3. 📊 Custom monitoring dashboards
4. 💰 Advanced cost optimization

---

## 📞 Soporte

### 🔍 Si tienes problemas:
1. **Ejecuta**: `./scripts/validate-guide.sh`
2. **Revisa**: Logs de Terraform con `TF_LOG=DEBUG`
3. **Consulta**: [GUIA-INGENIERO-TERRAFORM.md](./GUIA-INGENIERO-TERRAFORM.md) sección Troubleshooting
4. **Verifica**: Azure Portal para estado de recursos

### 📚 Documentación Adicional:
- **Terraform Azure Provider**: https://registry.terraform.io/providers/hashicorp/azurerm
- **Azure Policy**: https://docs.microsoft.com/azure/governance/policy/
- **Container Apps**: https://docs.microsoft.com/azure/container-apps/
