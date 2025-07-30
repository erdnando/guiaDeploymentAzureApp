#!/bin/bash

# ============================================================================
# 99-cleanup.sh
# Limpieza completa de todos los recursos del sistema de pagos
# ============================================================================

set -e  # Salir si algún comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${RED}============================================================================${NC}"
echo -e "${RED} 99 - LIMPIEZA COMPLETA DE RECURSOS${NC}"
echo -e "${RED}============================================================================${NC}"

# ¿Qué estamos haciendo?
echo -e "\n${YELLOW}¿QUÉ ESTAMOS HACIENDO?${NC}"
echo "Eliminando TODOS los recursos del sistema de pagos:"
echo "• Container Apps y Environment"
echo "• Application Gateway y Public IP"
echo "• Base de datos PostgreSQL"
echo "• Virtual Network y subnets"
echo "• Log Analytics y Application Insights"
echo "• Resource Group completo"

# ¿Por qué?
echo -e "\n${YELLOW}¿POR QUÉ?${NC}"
echo "La limpieza completa es importante para:"
echo "• Evitar costos innecesarios en Azure"
echo "• Limpiar recursos de prueba/desarrollo"
echo "• Preparar entorno para nuevos deployments"
echo "• Mantenimiento de subscripción limpia"

# Validar variables requeridas
if [[ -z "$RESOURCE_GROUP" ]]; then
    echo -e "${RED}❌ Error: RESOURCE_GROUP no está definido${NC}"
    echo "Ejecuta: source parameters/dev.env"
    exit 1
fi

echo -e "\n${BLUE}📋 RECURSOS A ELIMINAR:${NC}"
echo "• Resource Group: $RESOURCE_GROUP"
echo "• Ubicación: $LOCATION"
echo "• Proyecto: $PROJECT_NAME"
echo "• Ambiente: $ENVIRONMENT"

# CHECKPOINT: Verificar que el resource group existe
echo -e "\n${YELLOW}🔍 CHECKPOINT: Verificando Resource Group...${NC}"
RG_EXISTS=$(az group show --name "$RESOURCE_GROUP" --query "name" -o tsv 2>/dev/null || echo "")

if [[ -z "$RG_EXISTS" ]]; then
    echo -e "${YELLOW}⚠️  Resource Group no encontrado: $RESOURCE_GROUP${NC}"
    echo "No hay nada que limpiar."
    exit 0
fi

echo -e "${GREEN}✅ Resource Group encontrado: $RG_EXISTS${NC}"

# Mostrar recursos a eliminar
echo -e "\n${BLUE}🔍 INVENTARIO DE RECURSOS A ELIMINAR:${NC}"
echo "Analizando recursos en el Resource Group..."

# Mostrar Container Apps
echo -e "\n${CYAN}📦 Container Apps:${NC}"
CONTAINER_APPS=$(az containerapp list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null || echo "")
if [[ -n "$CONTAINER_APPS" ]]; then
    echo "$CONTAINER_APPS" | while read -r app; do
        echo "  • $app"
    done
else
    echo "  (ninguna)"
fi

# Mostrar Container Apps Environment
echo -e "\n${CYAN}🌐 Container Apps Environment:${NC}"
CONTAINER_ENVS=$(az containerapp env list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null || echo "")
if [[ -n "$CONTAINER_ENVS" ]]; then
    echo "$CONTAINER_ENVS" | while read -r env; do
        echo "  • $env"
    done
else
    echo "  (ninguno)"
fi

# Mostrar Application Gateway
echo -e "\n${CYAN}🚪 Application Gateway:${NC}"
APP_GATEWAYS=$(az network application-gateway list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null || echo "")
if [[ -n "$APP_GATEWAYS" ]]; then
    echo "$APP_GATEWAYS" | while read -r agw; do
        echo "  • $agw"
    done
else
    echo "  (ninguno)"
fi

# Mostrar Base de datos
echo -e "\n${CYAN}💾 PostgreSQL Servers:${NC}"
DATABASES=$(az postgres flexible-server list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null || echo "")
if [[ -n "$DATABASES" ]]; then
    echo "$DATABASES" | while read -r db; do
        echo "  • $db"
    done
else
    echo "  (ninguna)"
fi

# Mostrar Virtual Networks
echo -e "\n${CYAN}🌐 Virtual Networks:${NC}"
VNETS=$(az network vnet list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null || echo "")
if [[ -n "$VNETS" ]]; then
    echo "$VNETS" | while read -r vnet; do
        echo "  • $vnet"
    done
else
    echo "  (ninguna)"
fi

# Mostrar Public IPs
echo -e "\n${CYAN}🌍 Public IPs:${NC}"
PUBLIC_IPS=$(az network public-ip list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null || echo "")
if [[ -n "$PUBLIC_IPS" ]]; then
    echo "$PUBLIC_IPS" | while read -r pip; do
        echo "  • $pip"
    done
else
    echo "  (ninguna)"
fi

# Mostrar Log Analytics y App Insights
echo -e "\n${CYAN}📊 Monitoring:${NC}"
LOG_WORKSPACES=$(az monitor log-analytics workspace list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null || echo "")
APP_INSIGHTS=$(az monitor app-insights component list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null || echo "")

if [[ -n "$LOG_WORKSPACES" ]]; then
    echo "$LOG_WORKSPACES" | while read -r workspace; do
        echo "  • Log Analytics: $workspace"
    done
fi

if [[ -n "$APP_INSIGHTS" ]]; then
    echo "$APP_INSIGHTS" | while read -r ai; do
        echo "  • App Insights: $ai"
    done
fi

if [[ -z "$LOG_WORKSPACES" && -z "$APP_INSIGHTS" ]]; then
    echo "  (ninguno)"
fi

# Calcular costos aproximados
echo -e "\n${YELLOW}💰 ESTIMACIÓN DE COSTOS ELIMINADOS:${NC}"
echo "Los siguientes recursos generan costos continuos:"
if [[ -n "$DATABASES" ]]; then
    echo "  • PostgreSQL Flexible Server: ~\$50-200/mes"
fi
if [[ -n "$APP_GATEWAYS" ]]; then
    echo "  • Application Gateway: ~\$20-100/mes"
fi
if [[ -n "$CONTAINER_APPS" ]]; then
    echo "  • Container Apps: ~\$10-50/mes (según uso)"
fi
if [[ -n "$LOG_WORKSPACES" ]]; then
    echo "  • Log Analytics: ~\$5-20/mes (según ingesta)"
fi

# CONFIRMACIÓN CRÍTICA
echo -e "\n${RED}⚠️  CONFIRMACIÓN CRÍTICA ⚠️${NC}"
echo -e "${RED}===============================${NC}"
echo ""
echo -e "${YELLOW}Esta operación eliminará PERMANENTEMENTE todos los recursos.${NC}"
echo -e "${YELLOW}NO se puede deshacer.${NC}"
echo ""
echo -e "${RED}¿Estás ABSOLUTAMENTE SEGURO de eliminar todos los recursos?${NC}"
echo -e "Escribe '${CYAN}ELIMINAR TODO${NC}' para confirmar:"
read -r confirmation

if [[ "$confirmation" != "ELIMINAR TODO" ]]; then
    echo -e "\n${GREEN}✅ Operación cancelada. Recursos preservados.${NC}"
    exit 0
fi

echo -e "\n${RED}🚨 CONFIRMACIÓN FINAL${NC}"
echo -e "Resource Group a eliminar: ${YELLOW}$RESOURCE_GROUP${NC}"
echo -e "¿Proceder con la eliminación? (escribir 'SI'): "
read -r final_confirmation

if [[ "$final_confirmation" != "SI" ]]; then
    echo -e "\n${GREEN}✅ Operación cancelada. Recursos preservados.${NC}"
    exit 0
fi

# Función para eliminar con retry
delete_with_retry() {
    local resource_type=$1
    local resource_name=$2
    local delete_command=$3
    local max_attempts=3
    local attempt=1

    echo -e "\n${BLUE}🗑️  Eliminando $resource_type: $resource_name${NC}"
    
    while [[ $attempt -le $max_attempts ]]; do
        echo "Intento $attempt/$max_attempts..."
        
        if eval "$delete_command" 2>/dev/null; then
            echo -e "${GREEN}✅ $resource_name eliminado exitosamente${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  Intento $attempt fallido${NC}"
            if [[ $attempt -lt $max_attempts ]]; then
                echo "Esperando 30 segundos antes del siguiente intento..."
                sleep 30
            fi
        fi
        
        ((attempt++))
    done
    
    echo -e "${RED}❌ Error eliminando $resource_name después de $max_attempts intentos${NC}"
    return 1
}

# INICIO DE ELIMINACIÓN
echo -e "\n${RED}🚀 INICIANDO ELIMINACIÓN COMPLETA...${NC}"
echo "Esto puede tomar 10-20 minutos..."

# Paso 1: Eliminar Container Apps (son rápidas)
if [[ -n "$CONTAINER_APPS" ]]; then
    echo -e "\n${BLUE}📦 ELIMINANDO CONTAINER APPS...${NC}"
    echo "$CONTAINER_APPS" | while read -r app; do
        delete_with_retry "Container App" "$app" "az containerapp delete --name '$app' --resource-group '$RESOURCE_GROUP' --yes"
    done
fi

# Paso 2: Eliminar Container Apps Environment (depende de Container Apps)
if [[ -n "$CONTAINER_ENVS" ]]; then
    echo -e "\n${BLUE}🌐 ELIMINANDO CONTAINER APPS ENVIRONMENT...${NC}"
    echo "$CONTAINER_ENVS" | while read -r env; do
        delete_with_retry "Container Apps Environment" "$env" "az containerapp env delete --name '$env' --resource-group '$RESOURCE_GROUP' --yes"
    done
fi

# Paso 3: Eliminar Application Gateway (puede ser lento)
if [[ -n "$APP_GATEWAYS" ]]; then
    echo -e "\n${BLUE}🚪 ELIMINANDO APPLICATION GATEWAY...${NC}"
    echo "$APP_GATEWAYS" | while read -r agw; do
        delete_with_retry "Application Gateway" "$agw" "az network application-gateway delete --name '$agw' --resource-group '$RESOURCE_GROUP'"
    done
fi

# Paso 4: Eliminar bases de datos (pueden ser lentas)
if [[ -n "$DATABASES" ]]; then
    echo -e "\n${BLUE}💾 ELIMINANDO BASES DE DATOS...${NC}"
    echo "$DATABASES" | while read -r db; do
        delete_with_retry "PostgreSQL Server" "$db" "az postgres flexible-server delete --name '$db' --resource-group '$RESOURCE_GROUP' --yes"
    done
fi

# Paso 5: Mostrar progreso
echo -e "\n${YELLOW}📊 PROGRESO DE ELIMINACIÓN...${NC}"
echo "Verificando estado de recursos..."

REMAINING_RESOURCES=$(az resource list --resource-group "$RESOURCE_GROUP" --query "length([])" -o tsv 2>/dev/null || echo "0")
echo "Recursos restantes: $REMAINING_RESOURCES"

# Paso 6: Eliminación del Resource Group completo
echo -e "\n${RED}💥 ELIMINACIÓN FINAL DEL RESOURCE GROUP...${NC}"
echo "Esto eliminará cualquier recurso restante..."

echo "Comando a ejecutar:"
echo "az group delete --name $RESOURCE_GROUP --yes --no-wait"

az group delete --name "$RESOURCE_GROUP" --yes --no-wait

echo -e "\n${YELLOW}⏳ ELIMINACIÓN EN PROGRESO...${NC}"
echo "La eliminación del Resource Group se está ejecutando en background."
echo "Puedes verificar el progreso con:"
echo "az group show --name $RESOURCE_GROUP"

# Limpiar archivos locales de parámetros
echo -e "\n${BLUE}🧹 LIMPIANDO ARCHIVOS LOCALES...${NC}"
if [[ -d "parameters" ]]; then
    echo "Eliminando archivos de parámetros locales..."
    rm -f parameters/monitoring.env
    rm -f parameters/applications.env
    rm -f parameters/appgateway.env
    echo -e "${GREEN}✅ Archivos locales limpiados${NC}"
fi

# LOGRO FINAL
echo -e "\n${GREEN}🎉 LIMPIEZA COMPLETADA${NC}"
echo "=============================="
echo "✅ Comando de eliminación ejecutado"
echo "✅ Eliminación en progreso en background"
echo "✅ Archivos locales limpiados"
echo ""
echo -e "${BLUE}📍 VERIFICACIÓN:${NC}"
echo "Para verificar que todo se eliminó correctamente:"
echo "az group show --name $RESOURCE_GROUP"
echo ""
echo -e "${YELLOW}💡 NOTA:${NC}"
echo "La eliminación completa puede tomar 10-20 minutos."
echo "Si algunos recursos persisten, puedes eliminarlos manualmente desde Azure Portal."
echo ""
echo -e "${CYAN}👋 ¡Recursos limpiados! El ambiente está listo para nuevos deployments.${NC}"
