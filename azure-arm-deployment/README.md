# 🛡️ ARM Templates - Payment System

## 🎯 Sistema de Pagos Cloud-Native con Azure Policy Compliance

Esta implementación ARM proporciona un sistema de pagos completo en Azure con cumplimiento total de Azure Policies organizacionales.

### ✅ Azure Policies Cumplidas
- ✅ **Required Tag**: `Project` en todos los recursos
- ✅ **Location Restriction**: Solo `canadacentral`
- ✅ **Governance Tags**: Environment, CostCenter, Owner, etc.

---

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────┐
│                    Internet                              │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│              Application Gateway                         │
│           (Load Balancer + WAF)                         │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│              Container Apps Environment                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   Payment   │  │   Order     │  │   User      │     │
│  │   Service   │  │   Service   │  │   Service   │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│              Azure Database for PostgreSQL              │
│                (Flexible Server)                        │
└─────────────────────────────────────────────────────────┘
```

---

## 📚 Documentación Disponible

| **Nivel** | **Documento** | **Cuándo Usar** |
|-----------|---------------|----------------|
| 🎓 **Principiante** | [docs/GUIA-INGENIERO-ARM-PASO-A-PASO.md](./docs/GUIA-INGENIERO-ARM-PASO-A-PASO.md) | ✅ **Primera vez con ARM**<br/>✅ Vienes de otros IaC tools<br/>✅ Necesitas explicaciones detalladas |
| 📖 **Intermedio** | [docs/plantillas_arm_azure.md](./docs/plantillas_arm_azure.md) | ✅ **Ya sabes ARM básico**<br/>✅ Quieres referencia técnica<br/>✅ Buscas troubleshooting avanzado |
| ⚡ **Rápido** | [docs/QUICK-REFERENCE-ARM.md](./docs/QUICK-REFERENCE-ARM.md) | ✅ **Ya desplegaste antes**<br/>✅ Solo necesitas comandos<br/>✅ Referencia rápida |
| 🏗️ **Avanzado** | [docs/AVANZADO-ALTA-DISPONIBILIDAD.md](./docs/AVANZADO-ALTA-DISPONIBILIDAD.md) | ✅ **Alta Disponibilidad PostgreSQL**<br/>✅ Zone-Redundant (99.99% SLA)<br/>✅ Primary Zone 1, Standby Zone 2 |

### � **Documentación Técnica Adicional**
| **Tipo** | **Documento** | **Propósito** |
|----------|---------------|---------------|
| 🏗️ **Arquitectura** | [docs/architecture.md](./docs/architecture.md) | Diseño y componentes del sistema |
| 🚀 **Deploy Rápido** | [docs/deployment-guide.md](./docs/deployment-guide.md) | Guía de despliegue simplificada |
| 📊 **Compliance** | [docs/azure-policy-compliance.md](./docs/azure-policy-compliance.md) | Estado Azure Policy del proyecto |
| 🧹 **Cleanup** | [docs/cleanup-best-practices.md](./docs/cleanup-best-practices.md) | Mejores prácticas de limpieza |

---

## 🚀 Inicio Rápido

### 🎓 **Para Principiantes en ARM**
```bash
# 1. Validar prerequisites
./scripts/validate-guide-arm.sh

# 2. Seguir guía paso a paso
open docs/GUIA-INGENIERO-ARM-PASO-A-PASO.md
```

### ⚡ **Para Desarrolladores Experimentados**
```bash
# 1. Ver comandos esenciales
open docs/QUICK-REFERENCE-ARM.md

# 2. Deploy directo
az group create --name "rg-PaymentSystem-dev" --location "canadacentral"
az deployment group create \
  --resource-group "rg-PaymentSystem-dev" \
  --template-file templates/main.json \
  --parameters @parameters/dev-parameters.json
```

---

## 📁 Estructura del Proyecto

```
azure-arm-deployment/
├── README.md                    # ✅ Este archivo (overview)
├── templates/
│   ├── main.json               # ✅ Template principal orquestador
│   ├── 01-infrastructure.json  # Red y recursos base
│   ├── 02-postgresql.json      # Base de datos
│   ├── 03-containerapp-environment.json # Entorno contenedores
│   ├── 04-application-gateway.json # Load balancer
│   ├── 05-monitoring.json      # Observabilidad
│   └── 06-container-apps.json  # Aplicaciones
├── parameters/
│   ├── dev-parameters.json     # ✅ Parámetros desarrollo
│   └── prod-parameters.json    # ✅ Parámetros producción
├── scripts/
│   ├── validate-guide-arm.sh   # ✅ Validación prerequisites
│   └── deploy.sh               # ✅ Script automatizado
└── docs/                       # ✅ Documentación completa
    ├── GUIA-INGENIERO-ARM-PASO-A-PASO.md # Guía principal
    ├── QUICK-REFERENCE-ARM.md            # Referencia rápida
    ├── plantillas_arm_azure.md          # Documentación técnica
    ├── deployment-guide.md              # Deploy simplificado
    ├── architecture.md                  # Arquitectura del sistema
    └── azure-policy-compliance.md       # Estado compliance
```

---

## 🛠️ Comandos Esenciales

### 🧪 **Validación**
```bash
# Validar prerequisites y estructura
./scripts/validate-guide-arm.sh

# Validar template
az deployment group validate \
  --resource-group "rg-PaymentSystem-dev" \
  --template-file templates/main.json \
  --parameters @parameters/dev-parameters.json

# What-if analysis (ver cambios antes de aplicar)
az deployment group what-if \
  --resource-group "rg-PaymentSystem-dev" \
  --template-file templates/main.json \
  --parameters @parameters/dev-parameters.json
```

### 🚀 **Deploy**
```bash
# Crear resource group
az group create --name "rg-PaymentSystem-dev" --location "canadacentral"

# Deploy sistema completo
az deployment group create \
  --resource-group "rg-PaymentSystem-dev" \
  --template-file templates/main.json \
  --parameters @parameters/dev-parameters.json \
  --name "payment-system-deployment"
```

### 🧹 **Cleanup**
```bash
# Eliminar recursos de testing
az group delete --name "rg-PaymentSystem-dev" --yes --no-wait
```

---

## 🌍 Ambientes Disponibles

| **Ambiente** | **Archivo Parámetros** | **Resource Group** | **Uso** |
|--------------|----------------------|-------------------|---------|
| **Development** | `parameters/dev-parameters.json` | `rg-PaymentSystem-dev` | Testing y desarrollo |
| **Production** | `parameters/prod-parameters.json` | `rg-PaymentSystem-prod` | Producción |

### 🔧 **Diferencias entre Ambientes**
| **Recurso** | **Dev** | **Prod** |
|-------------|---------|----------|
| **Container CPU** | 0.25 cores | 1.0 cores |
| **Container Memory** | 0.5Gi | 2Gi |
| **DB SKU** | Basic | General Purpose |
| **Storage** | 32GB | 128GB |

---

## 🏷️ Azure Policy Compliance

### ✅ **Tags Aplicados Automáticamente**
```json
{
  "variables": {
    "commonTags": {
      "Project": "[parameters('projectName')]",
      "Environment": "[parameters('environment')]", 
      "CostCenter": "[parameters('costCenter')]",
      "Owner": "[parameters('owner')]",
      "CreatedBy": "ARM-Template",
      "ManagedBy": "IaC-ARM",
      "Purpose": "Payment-Processing-System",
      "Compliance": "Azure-Policy-Compliant"
    }
  }
}
```

### 🔍 **Validación de Compliance**
```bash
# Verificar que todos los recursos cumplen políticas
./scripts/validate-arm-azure-policies.sh
```

---

## 💰 Estimación de Costos

| **Ambiente** | **Costo Mensual Estimado** | **Componentes Principales** |
|--------------|---------------------------|---------------------------|
| **Development** | ~$50-80/mes | Container Apps Basic + PostgreSQL Basic |
| **Production** | ~$200-300/mes | Container Apps Standard + PostgreSQL General Purpose |

> 💡 **Tip**: Usar `az consumption usage list` para monitoreo real de costos

---

## 🎨 ARM vs Otras Herramientas IaC

### ✅ **Ventajas de ARM Templates**
- **Nativo de Azure**: Integración completa con servicios Azure
- **Sin dependencias**: No requiere herramientas adicionales
- **Policy integration**: Azure Policy nativo
- **Portal integration**: Visualización en Azure Portal
- **Idempotencia garantizada**: Azure Resource Manager maneja el estado

### 📊 **Comparación con Otras Herramientas**

| **Característica** | **ARM** | **Terraform** | **BICEP** |
|-------------------|---------|---------------|-----------|
| **Proveedor** | Microsoft | HashiCorp | Microsoft |
| **Sintaxis** | JSON | HCL | DSL similar a JSON |
| **Multi-cloud** | ❌ Solo Azure | ✅ Multi-cloud | ❌ Solo Azure |
| **Estado** | Azure maneja | Terraform State | Azure maneja |
| **Learning curve** | Media | Alta | Baja |
| **Azure integration** | ✅ Nativo | ✅ Muy bueno | ✅ Nativo |

---

## 🚨 Troubleshooting

### ❌ **Errores Comunes**

#### "Template validation failed"
```bash
# Solución: Verificar sintaxis JSON
az deployment group validate \
  --resource-group "rg-PaymentSystem-dev" \
  --template-file templates/main.json \
  --parameters @parameters/dev-parameters.json
```

#### "Azure Policy violation"
```bash
# Solución: Verificar compliance
./scripts/validate-arm-azure-policies.sh
```

#### "Resource already exists"
```bash
# Solución: ARM templates son idempotentes, verificar naming
az resource list --resource-group "rg-PaymentSystem-dev"
```

#### "SKU not available in location"
```bash
# Solución: Verificar SKUs disponibles
az vm list-skus --location "canadacentral" --query '[?contains(name, `Standard`)]'
```

> 📚 **Para troubleshooting completo**: Ver [docs/GUIA-INGENIERO-ARM-PASO-A-PASO.md](./docs/GUIA-INGENIERO-ARM-PASO-A-PASO.md) sección "FASE 6: Troubleshooting"

---

## 🎯 ¿Te sientes perdido?

### 🆘 **Si no sabes por dónde empezar**

| **Tu Situación** | **Documento Recomendado** | **Tiempo Estimado** |
|------------------|---------------------------|-------------------|
| **"Nunca he usado ARM"** | [GUIA-INGENIERO-ARM-PASO-A-PASO.md](./docs/GUIA-INGENIERO-ARM-PASO-A-PASO.md) | 2-4 horas |
| **"Conozco Azure pero no ARM"** | [plantillas_arm_azure.md](./docs/plantillas_arm_azure.md) | 1-2 horas |
| **"Solo quiero comandos"** | [QUICK-REFERENCE-ARM.md](./docs/QUICK-REFERENCE-ARM.md) | 15 minutos |
| **"Quiero deploy ahora"** | [deployment-guide.md](./docs/deployment-guide.md) | 30 minutos |
| **"Necesito entender arquitectura"** | [architecture.md](./docs/architecture.md) | 15 minutos |

### 🎓 **Ruta de Aprendizaje Recomendada**

```
🎯 EMPEZAR AQUÍ → docs/GUIA-INGENIERO-ARM-PASO-A-PASO.md
     ↓ (después de completar Fases 1-3)
📚 Profundizar → docs/plantillas_arm_azure.md  
     ↓ (para uso diario)
⚡ Referencia → docs/QUICK-REFERENCE-ARM.md
     ↓ (para automatización)
🚀 Deploy → docs/deployment-guide.md + scripts/deploy.sh
```

---

## 📞 Soporte y Recursos

### 🆘 **Si necesitas ayuda**
1. **Ejecuta validación**: `./scripts/validate-guide-arm.sh`
2. **Consulta troubleshooting**: [docs/GUIA-INGENIERO-ARM-PASO-A-PASO.md](./docs/GUIA-INGENIERO-ARM-PASO-A-PASO.md) Fase 6
3. **Ver documentación técnica**: [docs/plantillas_arm_azure.md](./docs/plantillas_arm_azure.md)

### 🌍 **Enlaces Útiles**
- **ARM Template Reference**: https://docs.microsoft.com/azure/templates/
- **ARM Template Best Practices**: https://docs.microsoft.com/azure/azure-resource-manager/templates/best-practices
- **Azure Quick Start Templates**: https://github.com/Azure/azure-quickstart-templates
- **Container Apps Documentation**: https://docs.microsoft.com/azure/container-apps/

---

## 🎯 Próximos Pasos

### 🎓 **Si eres nuevo en ARM**
1. Lee [docs/GUIA-INGENIERO-ARM-PASO-A-PASO.md](./docs/GUIA-INGENIERO-ARM-PASO-A-PASO.md)
2. Ejecuta `./scripts/validate-guide-arm.sh`
3. Sigue la guía paso a paso (Fases 0-7)

### 🚀 **Si ya conoces ARM**
1. Revisa [docs/QUICK-REFERENCE-ARM.md](./docs/QUICK-REFERENCE-ARM.md)
2. Deploy con los comandos esenciales de arriba
3. Personaliza según tus necesidades

### 🏛️ **Para análisis técnico**
1. Lee [docs/architecture.md](./docs/architecture.md)
2. Revisa [docs/plantillas_arm_azure.md](./docs/plantillas_arm_azure.md)
3. Consulta compliance en [docs/azure-policy-compliance.md](./docs/azure-policy-compliance.md)

---

## 🎉 ¡Disfruta ARM Templates!

**ARM Templates son el foundation de Azure:**
- 🎯 **Nativo**: Integración completa con Azure
- 🚀 **Confiable**: Microsoft maneja el estado por ti
- 🔧 **Idempotente**: Deploy seguro múltiples veces
- ✅ **Compliance**: Azure Policy integration nativa

**¡Happy ARM coding! 🚀**

---

## �🏗️ Arquitectura

```
Internet → Application Gateway (WAF) → Container Apps → PostgreSQL
                    ↓
              Log Analytics ← Application Insights
```

### Componentes Principales

- **🌐 Application Gateway**: Load balancer con WAF integrado
- **📦 Container Apps**: Hosting serverless para aplicaciones en contenedores
- **🗄️ PostgreSQL Flexible Server**: Base de datos managed con alta disponibilidad
- **📊 Monitoring**: Log Analytics + Application Insights para observabilidad completa

## 🚀 Quick Start

> ⚠️ **IMPORTANTE**: Este Quick Start usa el enfoque automatizado (`deploy.sh`). Si eres principiante en ARM Templates, considera usar primero la [guía educativa completa](docs/plantillas_arm_azure.md) para entender los conceptos.

### 1. Pre-requisitos

- Azure CLI instalado y configurado
- Cuenta de GitHub con Container Registry
- Suscripción de Azure activa

### 2. Configuración

```bash
# Clonar proyecto
git clone <este-repositorio>
cd azure-arm-deployment

# Configurar variables (REQUERIDO)
nano scripts/variables.sh

# Cambiar estos valores:
export REGISTRY_USERNAME="tu-usuario-github"
export REGISTRY_PASSWORD="tu-github-token"
export ALERT_EMAIL="tu-email@empresa.com"
```

### 3. Despliegue

```bash
# Validar configuración
./scripts/validate.sh

# Desplegar infraestructura
./scripts/deploy.sh
```

## 📁 Estructura del Proyecto

```
azure-arm-deployment/
├── templates/                 # Templates ARM (Infrastructure as Code)
│   ├── 01-infrastructure.json # VNET, NSG, Subnets
│   ├── 02-postgresql.json     # Base de datos PostgreSQL
│   ├── 03-containerenv.json   # Container Apps Environment
│   ├── 04-appgateway.json     # Application Gateway + WAF
│   ├── 05-monitoring.json     # Log Analytics + App Insights
│   └── 06-containerapps.json  # Container Apps (Frontend + Backend)
├── parameters/                # Parámetros por ambiente
│   ├── *.dev.json            # Configuración desarrollo
│   └── *.prod.json           # Configuración producción
├── scripts/                   # Scripts de automatización
│   ├── variables.sh          # Configuración de variables
│   ├── deploy.sh             # Script de despliegue
│   ├── validate.sh           # Validación de templates
│   └── cleanup.sh            # Limpieza de recursos
└── docs/                     # Documentación
    ├── architecture.md       # Arquitectura detallada
    └── deployment-guide.md   # Guía de despliegue
```

## 🎯 Características

### ✅ Listo para Producción
- Templates ARM validados y probados
- Configuración de seguridad siguiendo best practices
- Monitoreo y alertas automáticas
- Backup automático de PostgreSQL

### 🔒 Seguridad Integrada
- WAF (Web Application Firewall) habilitado
- Network Security Groups configurados
- Private networking para PostgreSQL
- Managed Identity para autenticación

### 📈 Escalabilidad Automática
- Container Apps con auto-scaling
- Application Gateway con escalado automático
- PostgreSQL con storage auto-growth

### 💰 Optimizado para Costos
- **Desarrollo**: ~$310/mes
- **Producción**: ~$650/mes
- Pay-per-use para Container Apps
- Solo pagas por recursos activos

## 🛠️ Scripts Disponibles

| Script | Descripción | Uso |
|--------|-------------|-----|
| `validate.sh` | Valida templates y configuración | `./scripts/validate.sh` |
| `deploy.sh` | Despliega toda la infraestructura | `./scripts/deploy.sh` |
| `cleanup.sh` | Elimina todos los recursos | `./scripts/cleanup.sh` |
| `variables.sh` | Configuración centralizada | `source scripts/variables.sh` |

## 📊 Recursos Desplegados

Después del despliegue tendrás:

- **1 Application Gateway** con WAF habilitado
- **1 PostgreSQL Flexible Server** con backup automático
- **2 Container Apps** (frontend + backend)
- **1 Container Apps Environment** con VNET integration
- **1 Log Analytics Workspace** para logs centralizados
- **1 Application Insights** para application monitoring
- **1 VNET** con subnets y NSGs configurados

## 🔍 Monitoreo Incluido

### Métricas Automáticas
- Request rate y response time
- Error rate y status codes
- CPU y memoria de Container Apps
- Conexiones y performance de PostgreSQL

### Alertas Configuradas
- High CPU usage (>80%)
- High error rate (>5%)
- Database connection limits
- Failed requests spike

## 🌍 Ambientes Soportados

### Desarrollo (`dev`)
- SKUs básicos para ahorro de costos
- Configuración permisiva para testing
- Logs detallados habilitados

### Producción (`prod`)
- SKUs optimizados para performance
- Configuración de seguridad estricta
- Backup y retention configurados

## 📝 Configuración Personalizable

### Variables Principales
```bash
PROJECT_NAME="paymentapp"           # Nombre del proyecto
ENVIRONMENT="dev"                   # dev, test, prod
LOCATION="eastus"                   # Región de Azure
POSTGRES_ADMIN_USER="pgadmin"       # Usuario admin PostgreSQL
BACKEND_IMAGE="ghcr.io/user/api"    # Imagen del backend
FRONTEND_IMAGE="ghcr.io/user/web"   # Imagen del frontend
```

### Personalización Avanzada
- Editar archivos en `parameters/` para configuración específica
- Modificar templates en `templates/` para cambios estructurales
- Ajustar scripts en `scripts/` para workflows personalizados

## 🚦 Estado del Proyecto

- ✅ **Templates ARM**: Completos y validados
- ✅ **Scripts de automatización**: Funcionales
- ✅ **Documentación**: Completa
- ✅ **Configuración multi-ambiente**: Dev y Prod
- ✅ **Monitoreo**: Log Analytics + App Insights
- ✅ **Seguridad**: WAF + NSGs + Private networking

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una branch para tu feature (`git checkout -b feature/amazing-feature`)
3. Commit tus cambios (`git commit -m 'Add amazing feature'`)
4. Push a la branch (`git push origin feature/amazing-feature`)
5. Abre un Pull Request

## 📖 Documentación Adicional

### � **Matriz de Decisión de Documentos**

| Criterio | plantillas_arm_azure.md | deployment-guide.md | scripts/deploy.sh | architecture.md |
|----------|-------------------------|--------------------|--------------------|-----------------|
| **🎓 Aprendizaje** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐ | ⭐⭐ |
| **⚡ Velocidad** | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | N/A |
| **🎛️ Control** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | N/A |
| **👶 Principiantes** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ |
| **🏭 Producción** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | N/A |
| **🔧 Troubleshooting** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐ |

### 📚 **Enlaces a Documentación:**

- [📘 **Guía Educativa Completa**](docs/plantillas_arm_azure.md) - ARM Templates desde cero con explicaciones detalladas
- [� **Guía de Despliegue Rápido**](docs/deployment-guide.md) - Instrucciones paso a paso para despliegue directo
- [📐 **Arquitectura Detallada**](docs/architecture.md) - Diseño y componentes de la solución
- [🔧 **Troubleshooting**](docs/deployment-guide.md#troubleshooting) - Solución de problemas comunes

### ⚠️ **Notas Importantes:**

- **Si eres nuevo en ARM Templates**: Comienza con `plantillas_arm_azure.md`
- **Si ya tienes experiencia**: Usa directamente `deployment-guide.md` o `deploy.sh`
- **Si solo necesitas entender la arquitectura**: Lee `architecture.md`
- **No ejecutes múltiples guías al mismo tiempo** - elige una según tu objetivo

## 📞 Soporte

Si encuentras problemas:

1. Revisa la [Guía de Despliegue](docs/deployment-guide.md)
2. Ejecuta `./scripts/validate.sh` para diagnosticar
3. Consulta los logs en Azure Portal
4. Abre un issue en GitHub con detalles del error

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver [LICENSE](LICENSE) para más detalles.

---

**⭐ Si este proyecto te resulta útil, dale una estrella en GitHub!**
