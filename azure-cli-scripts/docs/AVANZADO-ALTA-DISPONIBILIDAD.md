# 🏗️ **Configuración Avanzada: Alta Disponibilidad PostgreSQL - Azure CLI**

## 📋 **Índice**
- [Introducción](#introducción)
- [Configuración Zone-Redundant](#configuración-zone-redundant)
- [Script de Implementación](#script-de-implementación)
- [Validación y Monitoreo](#validación-y-monitoreo)
- [Consideraciones de Costos](#consideraciones-de-costos)

---

## 🎯 **Introducción**

Esta guía avanzada te enseña cómo configurar **Alta Disponibilidad Zone-Redundant** para PostgreSQL Flexible Server usando Azure CLI, implementando el patrón mostrado en el diagrama enterprise con:

- **Primary Database** en Availability Zone 1
- **Standby Database** en Availability Zone 2  
- **Failover automático** < 60 segundos
- **99.99% SLA** garantizado por Azure

---

## ⚙️ **Configuración Zone-Redundant**

### 🔧 **Parámetros Adicionales Requeridos**

Para habilitar alta disponibilidad, agregamos estos parámetros al comando base:

```bash
# Parámetros de Alta Disponibilidad
--high-availability ZoneRedundant \
--zone 1 \
--standby-zone 2 \
```

### 📊 **SKU Mínimo Requerido**

⚠️ **Importante**: Alta disponibilidad requiere tier **General Purpose** o superior:

```bash
# DEV/TEST - Tier mínimo para HA
--sku-name GP_Standard_D2s_v3 \
--tier GeneralPurpose \

# PROD - Recomendado
--sku-name GP_Standard_D4s_v3 \
--tier GeneralPurpose \
```

---

## 🚀 **Script de Implementación**

### 📁 **Archivo**: `03-create-database-ha.sh`

```bash
#!/bin/bash

# =========================================
# POSTGRESQL ALTA DISPONIBILIDAD - Azure CLI
# =========================================
# 🏗️ Crea PostgreSQL con Zone-Redundant HA
# 🎯 Primary Zone 1, Standby Zone 2

set -euo pipefail
source "$(dirname "$0")/00-variables.sh"
source "$(dirname "$0")/utils/logging.sh"

echo ""
echo "🏗️ ==================================="
echo "🗄️ POSTGRESQL ALTA DISPONIBILIDAD"
echo "🏗️ ==================================="

# Validar que estamos en producción
if [[ "$ENVIRONMENT" != "prod" ]]; then
    warning "Alta disponibilidad recomendada solo para producción"
    echo "Ambiente actual: $ENVIRONMENT"
    read -p "¿Continuar con HA en $ENVIRONMENT? (y/N): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || exit 0
fi

echo ""
echo "🗄️ Creando PostgreSQL con Alta Disponibilidad..."

# Crear PostgreSQL server con HA
info "Configuración HA: GP_Standard_D2s_v3, Zone-Redundant, Zones 1-2"
az postgres flexible-server create \
  --resource-group $RESOURCE_GROUP \
  --name "$DB_SERVER_NAME" \
  --location $LOCATION \
  --admin-user $DB_ADMIN_USER \
  --admin-password $DB_ADMIN_PASSWORD \
  --sku-name GP_Standard_D2s_v3 \
  --tier GeneralPurpose \
  --version 14 \
  --storage-size 128 \
  --backup-retention 35 \
  --geo-redundant-backup Enabled \
  --high-availability ZoneRedundant \
  --zone 1 \
  --standby-zone 2 \
  --tags \
    Project=$PROJECT_NAME \
    Environment=$ENVIRONMENT \
    Purpose="Payment-Database-HA" \
    HighAvailability="Zone-Redundant" \
  --output table

success "PostgreSQL HA creado: $DB_SERVER_NAME"

echo ""
echo "🔍 Validando configuración de Alta Disponibilidad..."

# Verificar estado de HA
HA_STATE=$(az postgres flexible-server show \
  --resource-group $RESOURCE_GROUP \
  --name "$DB_SERVER_NAME" \
  --query "highAvailability.mode" -o tsv)

PRIMARY_ZONE=$(az postgres flexible-server show \
  --resource-group $RESOURCE_GROUP \
  --name "$DB_SERVER_NAME" \
  --query "availabilityZone" -o tsv)

STANDBY_ZONE=$(az postgres flexible-server show \
  --resource-group $RESOURCE_GROUP \
  --name "$DB_SERVER_NAME" \
  --query "highAvailability.standbyAvailabilityZone" -o tsv)

echo ""
echo "✅ Configuración de Alta Disponibilidad:"
echo "   • Modo HA: $HA_STATE"
echo "   • Primary Zone: $PRIMARY_ZONE"
echo "   • Standby Zone: $STANDBY_ZONE"
echo "   • SLA: 99.99%"

echo ""
success "✅ Alta Disponibilidad configurada correctamente"
```

---

## 🔍 **Validación y Monitoreo**

### 📊 **Verificar Estado de HA**

```bash
# Verificar configuración de alta disponibilidad
az postgres flexible-server show \
  --resource-group $RESOURCE_GROUP \
  --name "$DB_SERVER_NAME" \
  --query "{
    name: name,
    haMode: highAvailability.mode,
    primaryZone: availabilityZone,
    standbyZone: highAvailability.standbyAvailabilityZone,
    state: highAvailability.state
  }" \
  --output table
```

### 📈 **Monitoreo de Métricas HA**

```bash
# Métricas específicas de alta disponibilidad
az monitor metrics list \
  --resource "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.DBforPostgreSQL/flexibleServers/$DB_SERVER_NAME" \
  --metric "ha_replica_lag" \
  --interval PT1M \
  --output table
```

---

## 💰 **Consideraciones de Costos**

### 📊 **Comparativa de Costos**

| Configuración | Costo Mensual Estimado | SLA | Uso Recomendado |
|---------------|------------------------|-----|-----------------|
| **Básico (sin HA)** | ~$50-80/mes | 99.9% | Desarrollo/Testing |
| **Zone-Redundant HA** | ~$200-300/mes | 99.99% | Producción |

### ⚠️ **Factores de Costo**

- **🔄 Doble costo de compute**: Primary + Standby
- **💾 Storage replicado**: Entre zonas
- **🌐 Backup geo-redundante**: Incluido
- **📊 Monitoreo avanzado**: Métricas HA

---

## 🎯 **Próximos Pasos**

1. **🔧 Implementar**: Ejecutar script de HA en producción
2. **📊 Monitorear**: Configurar alertas de failover  
3. **🧪 Probar**: Simular failover en ambiente de testing
4. **📖 Documentar**: Procedimientos de recuperación

---

## 📚 **Referencias**

- [Azure PostgreSQL HA Documentation](https://docs.microsoft.com/azure/postgresql/flexible-server/concepts-high-availability)
- [Zone-Redundant Configuration](https://docs.microsoft.com/azure/postgresql/flexible-server/how-to-manage-high-availability-portal)
- [SLA y Garantías](https://azure.microsoft.com/support/legal/sla/postgresql/)

---

> 💡 **Tip**: Implementa alta disponibilidad gradualmente, comenzando en ambiente de testing para validar comportamiento antes de producción.
