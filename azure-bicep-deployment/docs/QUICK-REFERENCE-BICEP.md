# 🎯 Referencia Rápida: BICEP Azure

## 🚀 Inicio Rápido (3 minutos)

### ✅ Pre-requisitos Check
```bash
# Verificar herramientas
az --version          # Azure CLI
az bicep version      # BICEP CLI (viene con Azure CLI)

# Login a Azure
az login
az account show

# Validar proyecto
cd azure-bicep-deployment
./scripts/validate-guide-bicep.sh
```

### 🎯 Deploy Rápido
```bash
# 1. Compilar y validar
az bicep build --file main.bicep

# 2. Validar compliance
./scripts/validate-bicep-azure-policies.sh

# 3. Crear Resource Group
az group create --name "rg-PaymentSystem-dev" --location "canadacentral"

# 4. Validar template
az deployment group validate \
  --resource-group "rg-PaymentSystem-dev" \
  --template-file main.bicep \
  --parameters @parameters/parameters-dev.json

# 5. Deploy completo
az deployment group create \
  --resource-group "rg-PaymentSystem-dev" \
  --template-file main.bicep \
  --parameters @parameters/parameters-dev.json \
  --name "payment-system-deployment"

# 6. Verificar outputs
az deployment group show \
  --resource-group "rg-PaymentSystem-dev" \
  --name "payment-system-deployment" \
  --query "properties.outputs"
```

### 🧹 Cleanup Rápido
```bash
az group delete --name "rg-PaymentSystem-dev" --yes --no-wait
```

---

## 📚 Guías Disponibles

| **Nivel** | **Guía** | **Cuándo Usar** |
|-----------|----------|----------------|
| 🎓 **Principiante** | [GUIA-INGENIERO-BICEP-PASO-A-PASO.md](./GUIA-INGENIERO-BICEP-PASO-A-PASO.md) | ✅ **Primera vez con BICEP**<br/>✅ Vienes de ARM Templates<br/>✅ Necesitas explicaciones detalladas |
| 📖 **Intermedio** | [README-bicep-azure-policies.md](./README-bicep-azure-policies.md) | ✅ **Ya sabes BICEP básico**<br/>✅ Quieres referencia técnica<br/>✅ Buscas troubleshooting avanzado |
| ⚡ **Rápido** | [QUICK-REFERENCE-BICEP.md](./QUICK-REFERENCE-BICEP.md) | ✅ **Ya desplegaste antes**<br/>✅ Solo necesitas comandos<br/>✅ Referencia rápida |

---

## 🛠️ Comandos Más Usados

### 🔄 Lifecycle BICEP
```bash
az bicep build --file main.bicep     # Compilar BICEP → ARM
az bicep validate --file main.bicep  # Validar sintaxis
az deployment group validate         # Validar template
az deployment group create           # Deploy recursos
az group delete                      # Eliminar recursos
```

### 📊 Información
```bash
az deployment group list             # Listar deployments
az deployment group show             # Detalles de deployment
az resource list                     # Listar recursos creados
az bicep version                     # Versión BICEP
```

### 🔧 Debugging
```bash
az bicep build --file main.bicep     # Compilar y ver errores
az deployment group validate         # Validar antes de deploy
az deployment operation list         # Ver operaciones de deployment
az activity-log list                 # Ver activity log
```

---

## 🎨 Sintaxis BICEP vs ARM

### ✅ **BICEP (Limpio)**
```bicep
// Parámetro con validación
@description('Nombre del proyecto')
@minLength(3)
@maxLength(15)
param projectName string

// Variable computada
var resourceGroupName = 'rg-${projectName}-${environment}'

// Resource con sintaxis clara
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: 'st${projectName}${environment}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  tags: commonTags
}

// Output
output storageAccountId string = storageAccount.id
```

### ❌ **ARM Equivalent (Verboso)**
```json
{
  "parameters": {
    "projectName": {
      "type": "string",
      "metadata": {
        "description": "Nombre del proyecto"
      },
      "minLength": 3,
      "maxLength": 15
    }
  },
  "variables": {
    "resourceGroupName": "[concat('rg-', parameters('projectName'), '-', parameters('environment'))]"
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2021-02-01",
      "name": "[concat('st', parameters('projectName'), parameters('environment'))]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "Standard_LRS"
      },
      "tags": "[variables('commonTags')]"
    }
  ],
  "outputs": {
    "storageAccountId": {
      "type": "string",
      "value": "[resourceId('Microsoft.Storage/storageAccounts', concat('st', parameters('projectName'), parameters('environment')))]"
    }
  }
}
```

**🎉 BICEP es ~70% menos código!**

---

## 🏗️ Módulos del Sistema

| **Orden** | **Módulo** | **Propósito** | **Archivo** |
|-----------|------------|---------------|-------------|
| 1️⃣ | `infrastructure` | Networking base | `modules/infrastructure/main.bicep` |
| 2️⃣ | `monitoring` | Observabilidad | `modules/monitoring/main.bicep` |
| 3️⃣ | `database` | PostgreSQL | `modules/database/main.bicep` |
| 4️⃣ | `containerApps` | Aplicaciones | `modules/containerApps/main.bicep` |
| 5️⃣ | `applicationGateway` | Load balancer | `modules/applicationGateway/main.bicep` |

### 🔄 Deploy Individual de Módulos
```bicep
// En main.bicep, comentar módulos que no quieres desplegar
module infrastructure 'modules/infrastructure/main.bicep' = {
  name: 'infrastructure-deployment'
  params: {
    projectName: projectName
    environment: environment
    location: location
  }
}

// module database 'modules/database/main.bicep' = { ... }  // Comentado
```

---

## 🏛️ Azure Policy Compliance

### ✅ Políticas Implementadas
| **Policy** | **Requirement** | **Implementation** |
|------------|----------------|-------------------|
| **Required Tag** | Tag `Project` en todos los recursos | `commonTags.Project = projectName` |
| **Location Restriction** | Solo `canadacentral` | `@allowed(['canadacentral'])` |

### 🔍 Validación
```bash
# Validar compliance
./scripts/validate-bicep-azure-policies.sh

# ¿Qué buscar?
# ✅ Project tag validation: PASSED
# ✅ Location policy validation: PASSED
# ✅ All governance tags present: PASSED
```

### 📝 Tags en BICEP
```bicep
// Definir tags comunes
var commonTags = {
  Project: projectName              // REQUERIDO por Azure Policy
  Environment: environment
  CostCenter: costCenter
  Owner: owner
  CreatedBy: 'BICEP-Template'
  ManagedBy: 'IaC-BICEP'
  Purpose: 'Payment-Processing-System'
  Compliance: 'Azure-Policy-Compliant'
}

// Aplicar a recursos
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: commonTags                  // ✅ Tags aplicados
}
```

---

## 🌍 Ambientes

### 📁 Configuración
```bash
# Desarrollo
az deployment group create \
  --resource-group "rg-PaymentSystem-dev" \
  --template-file main.bicep \
  --parameters @parameters/parameters-dev.json

# Producción  
az deployment group create \
  --resource-group "rg-PaymentSystem-prod" \
  --template-file main.bicep \
  --parameters @parameters/parameters-prod.json
```

### 🔧 Diferencias Clave
| **Aspecto** | **Dev** | **Prod** |
|-------------|---------|----------|
| **Container CPU** | 0.25 cores | 1.0 cores |
| **Container Memory** | 0.5Gi | 2Gi |
| **Replicas** | 1-3 | 3-10 |
| **DB SKU** | Basic | General Purpose |
| **Storage** | 32GB | 128GB |

---

## 🚨 Troubleshooting Rápido

### ❌ Errores Comunes

#### Error: "BICEP compilation failed"
```bash
# Solución: Ver errores específicos
az bicep build --file main.bicep
# Revisar línea y columna del error
```

#### Error: "Template validation failed"
```bash
# Solución: Validar con detalles
az deployment group validate \
  --resource-group "rg-PaymentSystem-dev" \
  --template-file main.bicep \
  --parameters @parameters/parameters-dev.json
```

#### Error: "Parameter file not found"
```bash
# Solución: Verificar ruta
ls -la parameters/
# Usar ruta relativa correcta: @parameters/parameters-dev.json
```

#### Error: "Azure Policy violation"
```bash
# Solución: Verificar compliance
./scripts/validate-bicep-azure-policies.sh
# Asegurar Project tag y location canadacentral
```

#### Error: "Resource already exists"
```bash
# Solución: Cambiar nombre o usar existing
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' existing = {
  name: 'existingStorageAccount'
}
```

---

## 📊 Outputs Importantes

### 🔍 Ver Outputs
```bash
# Todos los outputs
az deployment group show \
  --resource-group "rg-PaymentSystem-dev" \
  --name "payment-system-deployment" \
  --query "properties.outputs"

# Output específico
az deployment group show \
  --resource-group "rg-PaymentSystem-dev" \
  --name "payment-system-deployment" \
  --query "properties.outputs.applicationGatewayPublicIP.value"
```

### 📋 Verificación Post-Deploy
```bash
# Listar recursos creados
az resource list --resource-group "rg-PaymentSystem-dev" --output table

# IP pública del sistema
PUBLIC_IP=$(az deployment group show \
  --resource-group "rg-PaymentSystem-dev" \
  --name "payment-system-deployment" \
  --query "properties.outputs.applicationGatewayPublicIP.value" -o tsv)

# Test conectividad
curl http://$PUBLIC_IP/
```

---

## 💰 Gestión de Costos

### 🧹 Cleanup Testing
```bash
# Eliminar resource group completo
az group delete --name "rg-PaymentSystem-dev" --yes --no-wait

# Ver progreso de eliminación
az group show --name "rg-PaymentSystem-dev" --query "properties.provisioningState"
```

### 📊 Monitoring de Costos
```bash
# Ver costos por resource group
az consumption usage list \
  --start-date 2024-01-01 \
  --end-date 2024-01-31 \
  --include-meter-details
```

---

## 🎯 Próximos Pasos

### 🚀 Para Principiantes
1. ✅ Completa [GUIA-INGENIERO-BICEP-PASO-A-PASO.md](./GUIA-INGENIERO-BICEP-PASO-A-PASO.md)
2. 🧪 Practica compilar BICEP a ARM
3. 🔧 Modifica parámetros y observa cambios

### 📈 Para Intermedios
1. 🏭 Deploy a ambiente producción
2. 🔄 Implementa CI/CD pipeline
3. 📦 Crea BICEP Registry para módulos compartidos
4. 🔐 Agrega módulos adicionales (Redis, etc.)

### 🏆 Para Avanzados
1. 🌍 Multi-region deployment con BICEP
2. 🔐 Advanced security con Azure Security Center
3. 📊 Custom monitoring dashboards
4. 💰 Advanced cost optimization

---

## 🎨 BICEP vs Alternativas

### 🔷 **Cuándo Usar BICEP**
✅ **Proyectos Azure-only**  
✅ **Equipos enfocados en Azure**  
✅ **Migración desde ARM Templates**  
✅ **Desarrollo rápido con IntelliSense**  
✅ **Sintaxis limpia y legible**  

### 🌍 **Cuándo Usar Terraform**
✅ **Estrategia multi-cloud**  
✅ **State management explícito**  
✅ **Amplio ecosistema de providers**  

### 📋 **Cuándo Usar ARM Templates**
✅ **Proyectos legacy existentes**  
✅ **Control granular máximo**  
✅ **Casos muy específicos**  

---

## 📞 Soporte

### 🔍 Si tienes problemas:
1. **Ejecuta**: `./scripts/validate-guide-bicep.sh`
2. **Compila**: `az bicep build --file main.bicep` para ver errores
3. **Consulta**: [GUIA-INGENIERO-BICEP-PASO-A-PASO.md](./GUIA-INGENIERO-BICEP-PASO-A-PASO.md) sección Troubleshooting
4. **Verifica**: Azure Portal para estado de recursos

### 📚 Documentación Adicional:
- **BICEP Documentation**: https://docs.microsoft.com/azure/azure-resource-manager/bicep/
- **BICEP Examples**: https://github.com/Azure/bicep
- **Azure Policy**: https://docs.microsoft.com/azure/governance/policy/
- **Container Apps**: https://docs.microsoft.com/azure/container-apps/

---

## 🎉 ¡Disfruta BICEP!

**BICEP hace que Infrastructure as Code sea:**
- 🎨 **Más limpio** (70% menos código)
- 🚀 **Más rápido** (IntelliSense completo)
- 🔧 **Más fácil** (sintaxis intuitiva)
- ✅ **Más confiable** (compilación a ARM nativo)

**¡Happy BICEP coding! 🚀**
