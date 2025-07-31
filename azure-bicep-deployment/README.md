# 🛡️ BICEP Templates - Payment System

## 🎯 Sistema de Pagos Cloud-Native con Azure Policy Compliance

Esta implementación BICEP proporciona un sistema de pagos completo en Azure con cumplimiento total de Azure Policies organizacionales.

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

## 📚 Documentación - RUTA DE APRENDIZAJE

### 🎓 **Para Ingenieros Principiantes (EMPEZAR AQUÍ)**

| **Nivel** | **Documento** | **Cuándo Usar** |
|-----------|---------------|----------------|
| 🎓 **Principiante** | [docs/GUIA-INGENIERO-BICEP-PASO-A-PASO.md](./docs/GUIA-INGENIERO-BICEP-PASO-A-PASO.md) | ✅ **Primera vez con Bicep**<br/>✅ Vienes de ARM JSON<br/>✅ Necesitas explicaciones detalladas |
| 📖 **Intermedio** | [docs/bicep-guide.md](./docs/bicep-guide.md) | ✅ **Ya sabes Bicep básico**<br/>✅ Quieres referencia técnica<br/>✅ Buscas troubleshooting avanzado |
| ⚡ **Rápido** | [docs/QUICK-REFERENCE-BICEP.md](./docs/QUICK-REFERENCE-BICEP.md) | ✅ **Ya desplegaste antes**<br/>✅ Solo necesitas comandos<br/>✅ Referencia rápida |
| 🏗️ **Avanzado** | [docs/AVANZADO-ALTA-DISPONIBILIDAD.md](./docs/AVANZADO-ALTA-DISPONIBILIDAD.md) | ✅ **Alta Disponibilidad PostgreSQL**<br/>✅ Zone-Redundant (99.99% SLA)<br/>✅ Primary Zone 1, Standby Zone 2 |

### 📋 **Documentación Técnica (Para después)**

| **Documento** | **Propósito** | **Cuándo consultarlo** |
|---------------|---------------|----------------------|
| [docs/README-bicep-azure-policies.md](./docs/README-bicep-azure-policies.md) | 📖 **Documentación técnica completa** | Troubleshooting, arquitectura detallada |
| [docs/azure-policy-compliance-status.md](./docs/azure-policy-compliance-status.md) | 📊 **Estado de compliance** | Verificar cumplimiento de políticas |
| [docs/RESUMEN-COMPLETADO.md](./docs/RESUMEN-COMPLETADO.md) | 🎯 **Status del proyecto** | Ver qué está implementado |
| [docs/INDEX.md](./docs/INDEX.md) | 📚 **Índice de navegación** | Encontrar documentación específica |

### 🆘 **¿Te sientes perdido? Sigue esta ruta:**
```
🎓 Principiante → 📖 docs/GUIA-INGENIERO-BICEP-PASO-A-PASO.md (EMPEZAR AQUÍ)
   ↓ (después de completar)
📚 Profundizar → 📖 docs/bicep-guide.md (ARM vs BICEP)
   ↓ (para uso diario)
⚡ Referencia → 📖 docs/QUICK-REFERENCE-BICEP.md (comandos rápidos)
```

---

## 🚀 Inicio Rápido

### 🎓 **Si eres PRINCIPIANTE (recomendado)**
```bash
# 1. Abrir la guía paso a paso
open docs/GUIA-INGENIERO-BICEP-PASO-A-PASO.md

# 2. Validar prerequisites (el script te guía)
./scripts/validate-guide-bicep.sh
```

### ⚡ **Si ya tienes EXPERIENCIA**
```bash
# 1. Crear resource group
az group create --name "rg-PaymentSystem-dev" --location "canadacentral"

# 2. Deploy directo
az deployment group create \
  --resource-group "rg-PaymentSystem-dev" \
  --template-file main.bicep \
  --parameters @parameters/dev-parameters.json
```

---

## 📞 Soporte y Recursos

### 🆘 **Si necesitas ayuda, sigue este orden:**

| **Problema** | **Solución** | **Archivo** |
|--------------|--------------|-------------|
| **🚀 Primera vez con BICEP** | Lee la guía completa | [docs/GUIA-INGENIERO-BICEP-PASO-A-PASO.md](./docs/GUIA-INGENIERO-BICEP-PASO-A-PASO.md) |
| **⚡ Necesito comandos rápidos** | Referencia de comandos | [docs/QUICK-REFERENCE-BICEP.md](./docs/QUICK-REFERENCE-BICEP.md) |
| **🔧 Errores técnicos** | Troubleshooting avanzado | [docs/README-bicep-azure-policies.md](./docs/README-bicep-azure-policies.md) |
| **📊 Ver compliance** | Estado de políticas | [docs/azure-policy-compliance-status.md](./docs/azure-policy-compliance-status.md) |
| **🗺️ No sé dónde buscar** | Navegación completa | [docs/INDEX.md](./docs/INDEX.md) |

---

## �� Próximos Pasos

### 🎓 **Si eres NUEVO en BICEP**
1. ✅ Lee **[docs/GUIA-INGENIERO-BICEP-PASO-A-PASO.md](./docs/GUIA-INGENIERO-BICEP-PASO-A-PASO.md)** (¡EMPEZAR AQUÍ!)
2. ✅ Ejecuta `./scripts/validate-guide-bicep.sh`
3. ✅ Sigue la guía paso a paso (2-4 horas)
4. ✅ Después lee [docs/bicep-guide.md](./docs/bicep-guide.md) para profundizar

### 🚀 **Si ya CONOCES BICEP**
1. ✅ Revisa [docs/QUICK-REFERENCE-BICEP.md](./docs/QUICK-REFERENCE-BICEP.md)
2. ✅ Deploy con comandos de "Inicio Rápido" arriba
3. ✅ Personaliza según tus necesidades

**¡Happy BICEP coding! 🚀✨**
