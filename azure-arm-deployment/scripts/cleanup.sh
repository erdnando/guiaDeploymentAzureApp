#!/bin/bash

# =============================================================================
# Script de Limpieza - Azure ARM Templates
# =============================================================================
# Este script elimina todos los recursos creados por el despliegue

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Cargar variables
echo -e "${BLUE}🔄 Cargando variables de entorno...${NC}"
source "$SCRIPT_DIR/variables.sh"

# Función para log con timestamp
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Función para confirmar acción
confirm() {
    local message="$1"
    echo -e "${YELLOW}⚠️  $message${NC}"
    read -p "¿Estás seguro? (escriba 'yes' para confirmar): " response
    if [ "$response" != "yes" ]; then
        echo -e "${BLUE}❌ Operación cancelada${NC}"
        exit 0
    fi
}

# Función para mostrar recursos a eliminar
show_resources() {
    log "🔍 Recursos que serán eliminados:"
    
    if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        echo ""
        echo -e "${BLUE}📋 RECURSOS EN EL RESOURCE GROUP '$RESOURCE_GROUP':${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Mostrar recursos principales
        az resource list --resource-group "$RESOURCE_GROUP" --output table
        
        echo ""
        echo -e "${YELLOW}💰 COSTO ESTIMADO MENSUAL:${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "• PostgreSQL Flexible Server (B1ms): ~$30/mes"
        echo "• Application Gateway (WAF_v2): ~$250/mes"
        echo "• Container Apps: ~$0.001/vCPU por segundo (depende del uso)"
        echo "• Log Analytics: ~$2.30/GB ingerido"
        echo "• Application Insights: Gratis hasta 5GB/mes"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    else
        warning "Resource Group '$RESOURCE_GROUP' no existe"
        exit 0
    fi
}

# Función para eliminar recursos específicos (método granular)
cleanup_granular() {
    log "🧹 Iniciando limpieza granular de recursos..."
    
    # 1. Eliminar Container Apps primero (para liberar dependencias)
    log "🗂️ Eliminando Container Apps..."
    for app in "ca-payment-api-$ENVIRONMENT" "ca-payment-frontend-$ENVIRONMENT"; do
        if az containerapp show --name "$app" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
            log "   🗑️ Eliminando: $app"
            az containerapp delete --name "$app" --resource-group "$RESOURCE_GROUP" --yes --no-wait
        fi
    done
    
    # 2. Eliminar Application Gateway
    log "🌐 Eliminando Application Gateway..."
    local appgw_name="appgw-$PROJECT_NAME-$ENVIRONMENT"
    if az network application-gateway show --name "$appgw_name" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        log "   🗑️ Eliminando: $appgw_name"
        az network application-gateway delete --name "$appgw_name" --resource-group "$RESOURCE_GROUP" --no-wait
    fi
    
    # 3. Eliminar PostgreSQL
    log "🗄️ Eliminando PostgreSQL Flexible Server..."
    if az postgres flexible-server show --name "$POSTGRES_SERVER_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        log "   🗑️ Eliminando: $POSTGRES_SERVER_NAME"
        az postgres flexible-server delete --name "$POSTGRES_SERVER_NAME" --resource-group "$RESOURCE_GROUP" --yes --no-wait
    fi
    
    # 4. Eliminar Container Apps Environment
    log "📦 Eliminando Container Apps Environment..."
    if az containerapp env show --name "$CONTAINERAPP_ENV_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        log "   🗑️ Eliminando: $CONTAINERAPP_ENV_NAME"
        az containerapp env delete --name "$CONTAINERAPP_ENV_NAME" --resource-group "$RESOURCE_GROUP" --yes --no-wait
    fi
    
    # 5. Eliminar recursos de monitoreo
    log "📊 Eliminando recursos de monitoreo..."
    for resource in "ai-$PROJECT_NAME-$ENVIRONMENT" "$LOG_ANALYTICS_WORKSPACE"; do
        if az resource show --name "$resource" --resource-group "$RESOURCE_GROUP" --resource-type "Microsoft.Insights/components" &> /dev/null || \
           az monitor log-analytics workspace show --workspace-name "$resource" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
            log "   🗑️ Eliminando: $resource"
            az resource delete --name "$resource" --resource-group "$RESOURCE_GROUP" --resource-type "Microsoft.Insights/components" --no-wait 2>/dev/null || \
            az monitor log-analytics workspace delete --workspace-name "$resource" --resource-group "$RESOURCE_GROUP" --yes --no-wait 2>/dev/null || true
        fi
    done
    
    # 6. Eliminar Public IPs
    log "🌍 Eliminando Public IPs..."
    for pip in "pip-appgw-$PROJECT_NAME-$ENVIRONMENT"; do
        if az network public-ip show --name "$pip" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
            log "   🗑️ Eliminando: $pip"
            az network public-ip delete --name "$pip" --resource-group "$RESOURCE_GROUP" --no-wait
        fi
    done
    
    # 7. Eliminar VNET (esto eliminará subnets y NSGs asociados)
    log "🔗 Eliminando VNET y recursos de red..."
    if az network vnet show --name "$VNET_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
        log "   🗑️ Eliminando: $VNET_NAME"
        az network vnet delete --name "$VNET_NAME" --resource-group "$RESOURCE_GROUP" --no-wait
    fi
    
    log "⏳ Esperando que terminen las operaciones de eliminación..."
    sleep 30
    
    log "✅ Limpieza granular completada"
}

# Función para eliminar todo el resource group
cleanup_full() {
    log "🧹 Eliminando Resource Group completo: $RESOURCE_GROUP"
    
    az group delete \
        --name "$RESOURCE_GROUP" \
        --yes \
        --no-wait
    
    log "✅ Resource Group marcado para eliminación"
    log "ℹ️  La eliminación continuará en segundo plano"
}

# Función para monitorear el progreso de eliminación
monitor_cleanup() {
    log "👀 Monitoreando progreso de limpieza..."
    local timeout=600  # 10 minutos
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
            log "✅ Resource Group eliminado completamente"
            return 0
        fi
        
        local remaining_resources=$(az resource list --resource-group "$RESOURCE_GROUP" --query "length([])" --output tsv 2>/dev/null || echo "0")
        log "   📊 Recursos restantes: $remaining_resources"
        
        sleep 30
        elapsed=$((elapsed + 30))
    done
    
    warning "⚠️  El monitoreo expiró después de 10 minutos"
    warning "   La eliminación puede estar aún en progreso"
}

# Banner inicial
echo -e "${RED}"
echo " ██████╗██╗     ███████╗ █████╗ ███╗   ██╗██╗   ██╗██████╗ "
echo "██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║██║   ██║██╔══██╗"
echo "██║     ██║     █████╗  ███████║██╔██╗ ██║██║   ██║██████╔╝"
echo "██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║██║   ██║██╔═══╝ "
echo "╚██████╗███████╗███████╗██║  ██║██║ ╚████║╚██████╔╝██║     "
echo " ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝     "
echo ""
echo "🧹 Limpieza de Recursos Azure - Sistema de Pagos"
echo "📦 Proyecto: $PROJECT_NAME"
echo "🌍 Entorno: $ENVIRONMENT"
echo "🗑️ Resource Group: $RESOURCE_GROUP"
echo -e "${NC}"
echo ""

# Verificar prerequisitos
if ! command -v az &> /dev/null; then
    error "Azure CLI no está instalado"
    exit 1
fi

if ! az account show &> /dev/null; then
    error "No estás autenticado en Azure. Ejecuta 'az login'"
    exit 1
fi

# Mostrar recursos
show_resources

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🗑️ OPCIONES DE LIMPIEZA${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. 🎯 Limpieza granular (eliminar recursos uno por uno)"
echo "2. 💥 Limpieza completa (eliminar todo el Resource Group)"
echo "3. ❌ Cancelar"
echo ""

read -p "Selecciona una opción (1-3): " choice

case $choice in
    1)
        echo ""
        confirm "Esto eliminará todos los recursos del proyecto '${PROJECT_NAME}' en el entorno '${ENVIRONMENT}' de forma granular."
        cleanup_granular
        
        echo ""
        log "🏁 Limpieza granular completada"
        log "💡 Verifica que no queden recursos huérfanos en el portal de Azure"
        ;;
    2)
        echo ""
        confirm "Esto eliminará COMPLETAMENTE el Resource Group '${RESOURCE_GROUP}' y TODOS sus recursos."
        cleanup_full
        
        echo ""
        read -p "¿Quieres monitorear el progreso de eliminación? (y/n): " monitor_choice
        if [ "$monitor_choice" = "y" ] || [ "$monitor_choice" = "Y" ]; then
            monitor_cleanup
        fi
        
        echo ""
        log "🏁 Limpieza completa iniciada"
        log "💡 La eliminación continuará en segundo plano"
        ;;
    3)
        echo -e "${BLUE}❌ Operación cancelada${NC}"
        exit 0
        ;;
    *)
        error "Opción inválida"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ ¡LIMPIEZA COMPLETADA!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📝 NOTAS IMPORTANTES:${NC}"
echo "• Los backups de PostgreSQL se retienen por defecto durante 7 días"
echo "• Los logs de Application Insights se retienen según la configuración"
echo "• Las imágenes en GitHub Container Registry NO se eliminan automáticamente"
echo "• Revisa tu facturación de Azure en las próximas horas para confirmar"
echo ""
echo -e "${GREEN}💰 Los costos de los recursos eliminados dejarán de acumularse${NC}"
echo ""

# Guardar log de limpieza
CLEANUP_LOG="$PROJECT_ROOT/cleanup-log-$(date +%Y%m%d-%H%M%S).txt"
cat > "$CLEANUP_LOG" << EOF
AZURE ARM CLEANUP - LOG DE LIMPIEZA
====================================
Fecha de limpieza: $(date)
Proyecto: $PROJECT_NAME
Entorno: $ENVIRONMENT
Resource Group eliminado: $RESOURCE_GROUP
Región: $LOCATION
Método de limpieza: $choice

RECURSOS QUE FUERON ELIMINADOS:
- Resource Group: $RESOURCE_GROUP
- PostgreSQL Server: $POSTGRES_SERVER_NAME
- Container Apps Environment: $CONTAINERAPP_ENV_NAME
- Application Gateway: appgw-$PROJECT_NAME-$ENVIRONMENT
- VNET: $VNET_NAME
- Log Analytics Workspace: $LOG_ANALYTICS_WORKSPACE
- Application Insights: ai-$PROJECT_NAME-$ENVIRONMENT
- Container Apps: ca-payment-api-$ENVIRONMENT, ca-payment-frontend-$ENVIRONMENT

VERIFICACIONES RECOMENDADAS:
1. Revisa el portal de Azure para confirmar eliminación completa
2. Verifica tu facturación en las próximas 24 horas
3. Confirma que no hay recursos huérfanos en otros Resource Groups
4. Elimina manualmente las imágenes de GitHub Container Registry si es necesario

NOTA: Este log se genera automáticamente para auditoría.
EOF

log "💾 Log de limpieza guardado en: $CLEANUP_LOG"
