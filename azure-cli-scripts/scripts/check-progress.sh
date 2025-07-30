#!/bin/bash

# ============================================================================
# check-progress.sh
# Checklist automático de progreso para ingenieros junior
# ============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}============================================================================${NC}"
echo -e "${PURPLE} 📋 CHECKLIST DE PROGRESO - SISTEMA DE PAGOS${NC}"
echo -e "${PURPLE}============================================================================${NC}"

# Cargar variables si existen
if [[ -f "parameters/dev.env" ]]; then
    source parameters/dev.env >/dev/null 2>&1
fi

echo -e "\n${BLUE}🎯 VERIFICANDO TU PROGRESO EN LA IMPLEMENTACIÓN...${NC}"

# Función para verificar si un recurso existe
check_resource() {
    local resource_type=$1
    local resource_name=$2
    local display_name=$3
    
    case $resource_type in
        "resource-group")
            if az group show --name "$resource_name" &>/dev/null; then
                echo -e "${GREEN}✅ $display_name${NC}"
                return 0
            else
                echo -e "${RED}❌ $display_name${NC}"
                return 1
            fi
            ;;
        "vnet")
            if az network vnet show --name "$resource_name" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
                echo -e "${GREEN}✅ $display_name${NC}"
                return 0
            else
                echo -e "${RED}❌ $display_name${NC}"
                return 1
            fi
            ;;
        "database")
            if az postgres flexible-server show --name "$resource_name" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
                echo -e "${GREEN}✅ $display_name${NC}"
                return 0
            else
                echo -e "${RED}❌ $display_name${NC}"
                return 1
            fi
            ;;
        "container-env")
            if az containerapp env show --name "$resource_name" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
                echo -e "${GREEN}✅ $display_name${NC}"
                return 0
            else
                echo -e "${RED}❌ $display_name${NC}"
                return 1
            fi
            ;;
        "container-app")
            if az containerapp show --name "$resource_name" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
                echo -e "${GREEN}✅ $display_name${NC}"
                return 0
            else
                echo -e "${RED}❌ $display_name${NC}"
                return 1
            fi
            ;;
        "app-gateway")
            if az network application-gateway show --name "$resource_name" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
                echo -e "${GREEN}✅ $display_name${NC}"
                return 0
            else
                echo -e "${RED}❌ $display_name${NC}"
                return 1
            fi
            ;;
        "log-analytics")
            if az monitor log-analytics workspace show --workspace-name "$resource_name" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
                echo -e "${GREEN}✅ $display_name${NC}"
                return 0
            else
                echo -e "${RED}❌ $display_name${NC}"
                return 1
            fi
            ;;
    esac
}

# Verificar prerrequisitos
echo -e "\n${CYAN}🔧 PRERREQUISITOS:${NC}"
if command -v az &> /dev/null; then
    echo -e "${GREEN}✅ Azure CLI instalado${NC}"
else
    echo -e "${RED}❌ Azure CLI no instalado${NC}"
fi

if az account show &>/dev/null; then
    echo -e "${GREEN}✅ Autenticado en Azure${NC}"
    SUBSCRIPTION_NAME=$(az account show --query "name" -o tsv)
    echo -e "   ${CYAN}Subscription: $SUBSCRIPTION_NAME${NC}"
else
    echo -e "${RED}❌ No autenticado en Azure${NC}"
fi

if [[ -f "parameters/dev.env" ]]; then
    echo -e "${GREEN}✅ Archivo de configuración existe${NC}"
else
    echo -e "${RED}❌ Archivo parameters/dev.env no existe${NC}"
fi

# Si no tenemos variables, no podemos continuar
if [[ -z "$RESOURCE_GROUP" ]]; then
    echo -e "\n${YELLOW}⚠️  No se pudieron cargar las variables de configuración${NC}"
    echo -e "${CYAN}💡 Ejecuta: source parameters/dev.env${NC}"
    exit 1
fi

echo -e "\n${CYAN}📊 CONFIGURACIÓN ACTUAL:${NC}"
echo -e "   Proyecto: ${YELLOW}$PROJECT_NAME${NC}"
echo -e "   Ambiente: ${YELLOW}$ENVIRONMENT${NC}"
echo -e "   Región: ${YELLOW}$LOCATION${NC}"
echo -e "   Resource Group: ${YELLOW}$RESOURCE_GROUP${NC}"

# Verificar progreso por fases
echo -e "\n${CYAN}📋 PROGRESO POR FASES:${NC}"

echo -e "\n${BLUE}FASE 1 - SETUP ENVIRONMENT:${NC}"
check_resource "resource-group" "$RESOURCE_GROUP" "Resource Group creado"

echo -e "\n${BLUE}FASE 2 - NETWORKING:${NC}"
check_resource "vnet" "vnet-${PROJECT_NAME}-${ENVIRONMENT}" "Virtual Network"
check_resource "vnet" "subnet-containerapp" "Subnet para Container Apps" # This is a simplification

echo -e "\n${BLUE}FASE 3 - DATABASE:${NC}"
check_resource "database" "psql-${PROJECT_NAME,,}-${ENVIRONMENT}" "PostgreSQL Server"

echo -e "\n${BLUE}FASE 4 - CONTAINER ENVIRONMENT:${NC}"
check_resource "container-env" "cae-${PROJECT_NAME}-${ENVIRONMENT}" "Container Apps Environment"

echo -e "\n${BLUE}FASE 5 - MONITORING:${NC}"
check_resource "log-analytics" "log-${PROJECT_NAME}-${ENVIRONMENT}" "Log Analytics Workspace"

echo -e "\n${BLUE}FASE 6 - APPLICATIONS:${NC}"
check_resource "container-app" "ca-gateway-${ENVIRONMENT}" "API Gateway"
check_resource "container-app" "ca-payment-${ENVIRONMENT}" "Payment API"
check_resource "container-app" "ca-user-${ENVIRONMENT}" "User API"
check_resource "container-app" "ca-notification-${ENVIRONMENT}" "Notification Service"

echo -e "\n${BLUE}FASE 7 - APPLICATION GATEWAY:${NC}"
check_resource "app-gateway" "agw-${PROJECT_NAME}-${ENVIRONMENT}" "Application Gateway"

# Calcular progreso general
echo -e "\n${PURPLE}============================================================================${NC}"
echo -e "\n${CYAN}📊 RESUMEN DE PROGRESO:${NC}"

# Obtener count de recursos
TOTAL_RESOURCES=$(az resource list --resource-group "$RESOURCE_GROUP" --query "length([])" -o tsv 2>/dev/null || echo "0")
echo -e "   Total de recursos creados: ${YELLOW}$TOTAL_RESOURCES${NC}"

# Verificar si Container Apps están funcionando
CONTAINER_APPS=$(az containerapp list --resource-group "$RESOURCE_GROUP" --query "length([])" -o tsv 2>/dev/null || echo "0")
echo -e "   Container Apps desplegadas: ${YELLOW}$CONTAINER_APPS${NC}"

# Verificar URLs disponibles
if [[ $CONTAINER_APPS -gt 0 ]]; then
    echo -e "\n${CYAN}🌐 URLs DE APLICACIONES:${NC}"
    APPS=$(az containerapp list --resource-group "$RESOURCE_GROUP" --query "[].{name:name,fqdn:properties.configuration.ingress.fqdn}" -o tsv 2>/dev/null)
    
    while IFS=$'\t' read -r app_name app_fqdn; do
        if [[ -n "$app_fqdn" && "$app_fqdn" != "null" ]]; then
            echo -e "   ${GREEN}✅ $app_name: https://$app_fqdn${NC}"
        fi
    done <<< "$APPS"
fi

# Verificar Application Gateway
APPGW_IP=$(az network public-ip show --name "pip-agw-${PROJECT_NAME}-${ENVIRONMENT}" --resource-group "$RESOURCE_GROUP" --query "ipAddress" -o tsv 2>/dev/null || echo "")
if [[ -n "$APPGW_IP" ]]; then
    echo -e "\n${CYAN}🚪 APPLICATION GATEWAY:${NC}"
    echo -e "   ${GREEN}✅ URL Principal: http://$APPGW_IP${NC}"
fi

# Próximos pasos recomendados
echo -e "\n${CYAN}🎯 PRÓXIMOS PASOS RECOMENDADOS:${NC}"

if [[ $TOTAL_RESOURCES -eq 0 ]]; then
    echo -e "   ${YELLOW}1. Ejecuta: ./scripts/01-setup-environment.sh${NC}"
elif [[ $CONTAINER_APPS -eq 0 ]]; then
    echo -e "   ${YELLOW}1. Continúa con el siguiente script en orden${NC}"
    echo -e "   ${YELLOW}2. Consulta: docs/GUIA-CLI-PASO-A-PASO.md${NC}"
elif [[ -z "$APPGW_IP" ]]; then
    echo -e "   ${YELLOW}1. Ejecuta: ./scripts/07-create-app-gateway.sh${NC}"
else
    echo -e "   ${GREEN}🎉 ¡Implementación completa!${NC}"
    echo -e "   ${CYAN}• Prueba tus aplicaciones en las URLs mostradas${NC}"
    echo -e "   ${CYAN}• Usa ./scripts/98-troubleshoot.sh para debugging${NC}"
    echo -e "   ${CYAN}• Cuando termines, limpia con ./scripts/99-cleanup.sh${NC}"
fi

# Mostrar costos estimados
echo -e "\n${CYAN}💰 COSTOS ESTIMADOS ACTUALES:${NC}"
if [[ $TOTAL_RESOURCES -gt 0 ]]; then
    echo -e "   ${YELLOW}⚠️  Recursos activos generando costos${NC}"
    echo -e "   ${CYAN}• PostgreSQL: ~$5-15/día${NC}"
    echo -e "   ${CYAN}• Application Gateway: ~$3-8/día${NC}"
    echo -e "   ${CYAN}• Container Apps: ~$1-5/día${NC}"
    echo -e "   ${CYAN}• Monitoring: ~$0.50-2/día${NC}"
    echo -e "\n   ${YELLOW}💡 Recuerda limpiar recursos cuando termines${NC}"
else
    echo -e "   ${GREEN}✅ Sin recursos activos - sin costos${NC}"
fi

echo -e "\n${PURPLE}============================================================================${NC}"
echo -e "${CYAN}¡Sigue adelante! Cada paso te acerca al dominio de Azure CLI 🚀${NC}"
