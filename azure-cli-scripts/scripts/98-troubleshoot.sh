#!/bin/bash

# ============================================================================
# 98-troubleshoot.sh
# Scripts de debugging y troubleshooting para el sistema de pagos
# ============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE} 98 - TROUBLESHOOTING & DEBUGGING TOOLS${NC}"
echo -e "${BLUE}============================================================================${NC}"

# ¿Qué estamos haciendo?
echo -e "\n${YELLOW}¿QUÉ ESTAMOS HACIENDO?${NC}"
echo "Conjunto de herramientas para diagnosticar problemas en el sistema:"
echo "• Verificación de estado de recursos"
echo "• Análisis de logs en tiempo real"
echo "• Tests de conectividad"
echo "• Métricas de performance"

# Validar variables requeridas
if [[ -z "$RESOURCE_GROUP" ]]; then
    echo -e "${RED}❌ Error: RESOURCE_GROUP no está definido${NC}"
    echo "Ejecuta: source parameters/dev.env"
    exit 1
fi

# Función para mostrar menú
show_menu() {
    echo -e "\n${CYAN}🔧 SELECCIONA UNA OPCIÓN DE TROUBLESHOOTING:${NC}"
    echo "1. 🔍 Estado general de recursos"
    echo "2. 📊 Información de Container Apps"
    echo "3. 📝 Logs en tiempo real"
    echo "4. 🌐 Test de conectividad"
    echo "5. 💾 Información de base de datos"
    echo "6. 🚨 Application Gateway diagnostics"
    echo "7. 📈 Métricas de performance"
    echo "8. 🔄 Restart de aplicaciones"
    echo "9. 🧹 Limpiar logs antiguos"
    echo "0. ❌ Salir"
    echo ""
    echo -n "Opción: "
}

# Función 1: Estado general de recursos
check_resources_status() {
    echo -e "\n${BLUE}🔍 ESTADO GENERAL DE RECURSOS${NC}"
    echo "========================================"
    
    echo -e "\n${YELLOW}Resource Group:${NC}"
    az group show --name "$RESOURCE_GROUP" --query "{name:name,location:location,provisioningState:properties.provisioningState}" -o table 2>/dev/null || echo "❌ No encontrado"
    
    echo -e "\n${YELLOW}Virtual Network:${NC}"
    az network vnet list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name,AddressSpace:addressSpace.addressPrefixes[0],ProvisioningState:provisioningState}" -o table 2>/dev/null || echo "❌ No encontrado"
    
    echo -e "\n${YELLOW}Database:${NC}"
    az postgres flexible-server list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name,State:state,Version:version,Location:location}" -o table 2>/dev/null || echo "❌ No encontrado"
    
    echo -e "\n${YELLOW}Container Apps Environment:${NC}"
    az containerapp env list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name,Location:location,ProvisioningState:properties.provisioningState}" -o table 2>/dev/null || echo "❌ No encontrado"
    
    echo -e "\n${YELLOW}Application Gateway:${NC}"
    az network application-gateway list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name,Location:location,ProvisioningState:provisioningState,SKU:sku.name}" -o table 2>/dev/null || echo "❌ No encontrado"
}

# Función 2: Información de Container Apps
check_container_apps() {
    echo -e "\n${BLUE}📊 INFORMACIÓN DE CONTAINER APPS${NC}"
    echo "============================================="
    
    echo -e "\n${YELLOW}Container Apps:${NC}"
    az containerapp list --resource-group "$RESOURCE_GROUP" --query "[].{Name:name,ProvisioningState:properties.provisioningState,ExternalIngress:properties.configuration.ingress.external,FQDN:properties.configuration.ingress.fqdn}" -o table 2>/dev/null || echo "❌ No encontradas"
    
    echo -e "\n${YELLOW}Selecciona una Container App para ver detalles (o presiona Enter para continuar):${NC}"
    read -r app_name
    
    if [[ -n "$app_name" ]]; then
        echo -e "\n${BLUE}📋 Detalles de $app_name:${NC}"
        az containerapp show --name "$app_name" --resource-group "$RESOURCE_GROUP" --query "{
            name: name,
            provisioningState: properties.provisioningState,
            activeRevisionsCount: properties.runningStatus,
            cpu: properties.template.containers[0].resources.cpu,
            memory: properties.template.containers[0].resources.memory,
            minReplicas: properties.template.scale.minReplicas,
            maxReplicas: properties.template.scale.maxReplicas,
            image: properties.template.containers[0].image
        }" -o table 2>/dev/null || echo "❌ App no encontrada"
        
        echo -e "\n${BLUE}🔄 Revisiones activas:${NC}"
        az containerapp revision list --name "$app_name" --resource-group "$RESOURCE_GROUP" --query "[].{Name:name,Active:properties.active,CreatedTime:properties.createdTime,Replicas:properties.replicas}" -o table 2>/dev/null
    fi
}

# Función 3: Logs en tiempo real
show_realtime_logs() {
    echo -e "\n${BLUE}📝 LOGS EN TIEMPO REAL${NC}"
    echo "=============================="
    
    echo -e "\n${YELLOW}Container Apps disponibles:${NC}"
    APPS=$(az containerapp list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null)
    
    if [[ -z "$APPS" ]]; then
        echo "❌ No se encontraron Container Apps"
        return
    fi
    
    echo "$APPS" | nl
    echo ""
    echo -n "Selecciona el número de la app para ver logs: "
    read -r app_number
    
    APP_NAME=$(echo "$APPS" | sed -n "${app_number}p")
    
    if [[ -n "$APP_NAME" ]]; then
        echo -e "\n${BLUE}📋 Logs de $APP_NAME (presiona Ctrl+C para salir):${NC}"
        az containerapp logs show --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --follow
    else
        echo "❌ Selección inválida"
    fi
}

# Función 4: Test de conectividad
test_connectivity() {
    echo -e "\n${BLUE}🌐 TEST DE CONECTIVIDAD${NC}"
    echo "================================"
    
    # Test Application Gateway
    echo -e "\n${YELLOW}Testing Application Gateway:${NC}"
    APPGW_IP=$(az network public-ip show --name "pip-agw-${PROJECT_NAME}-${ENVIRONMENT}" --resource-group "$RESOURCE_GROUP" --query "ipAddress" -o tsv 2>/dev/null)
    
    if [[ -n "$APPGW_IP" ]]; then
        echo "Application Gateway IP: $APPGW_IP"
        HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$APPGW_IP" --connect-timeout 10 || echo "000")
        if [[ "$HTTP_STATUS" -ge 200 && "$HTTP_STATUS" -lt 400 ]]; then
            echo -e "${GREEN}✅ Application Gateway responde (HTTP $HTTP_STATUS)${NC}"
        else
            echo -e "${RED}❌ Application Gateway no responde (HTTP $HTTP_STATUS)${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Application Gateway no encontrado${NC}"
    fi
    
    # Test Container Apps
    echo -e "\n${YELLOW}Testing Container Apps:${NC}"
    APPS_FQDNS=$(az containerapp list --resource-group "$RESOURCE_GROUP" --query "[].{name:name,fqdn:properties.configuration.ingress.fqdn}" -o tsv 2>/dev/null)
    
    while IFS=$'\t' read -r app_name app_fqdn; do
        if [[ -n "$app_fqdn" && "$app_fqdn" != "null" ]]; then
            echo -n "Testing $app_name ($app_fqdn): "
            HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$app_fqdn" --connect-timeout 10 || echo "000")
            if [[ "$HTTP_STATUS" -ge 200 && "$HTTP_STATUS" -lt 400 ]]; then
                echo -e "${GREEN}✅ OK (HTTP $HTTP_STATUS)${NC}"
            else
                echo -e "${RED}❌ Error (HTTP $HTTP_STATUS)${NC}"
            fi
        fi
    done <<< "$APPS_FQDNS"
    
    # Test Database connectivity
    echo -e "\n${YELLOW}Testing Database connectivity:${NC}"
    DB_SERVER=$(az postgres flexible-server list --resource-group "$RESOURCE_GROUP" --query "[0].fullyQualifiedDomainName" -o tsv 2>/dev/null)
    
    if [[ -n "$DB_SERVER" && "$DB_SERVER" != "null" ]]; then
        echo -n "Testing database ($DB_SERVER:5432): "
        if nc -z "$DB_SERVER" 5432 2>/dev/null; then
            echo -e "${GREEN}✅ Port 5432 reachable${NC}"
        else
            echo -e "${RED}❌ Port 5432 not reachable${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Database not found${NC}"
    fi
}

# Función 5: Información de base de datos
check_database_info() {
    echo -e "\n${BLUE}💾 INFORMACIÓN DE BASE DE DATOS${NC}"
    echo "======================================="
    
    DB_SERVERS=$(az postgres flexible-server list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null)
    
    if [[ -z "$DB_SERVERS" ]]; then
        echo "❌ No se encontraron servidores de base de datos"
        return
    fi
    
    for db_server in $DB_SERVERS; do
        echo -e "\n${YELLOW}Servidor: $db_server${NC}"
        az postgres flexible-server show --name "$db_server" --resource-group "$RESOURCE_GROUP" --query "{
            name: name,
            state: state,
            version: version,
            location: location,
            tier: sku.tier,
            compute: sku.name,
            storageSizeGB: storage.storageSizeGB,
            backup: backup.backupRetentionDays,
            fqdn: fullyQualifiedDomainName
        }" -o table 2>/dev/null
        
        echo -e "\n${YELLOW}Firewall rules:${NC}"
        az postgres flexible-server firewall-rule list --name "$db_server" --resource-group "$RESOURCE_GROUP" --query "[].{Name:name,StartIP:startIpAddress,EndIP:endIpAddress}" -o table 2>/dev/null
        
        echo -e "\n${YELLOW}Configuraciones:${NC}"
        az postgres flexible-server parameter list --server-name "$db_server" --resource-group "$RESOURCE_GROUP" --query "[?source=='user-override'].{Name:name,Value:value,DefaultValue:defaultValue}" -o table 2>/dev/null
    done
}

# Función 6: Application Gateway diagnostics
check_appgateway_diagnostics() {
    echo -e "\n${BLUE}🚨 APPLICATION GATEWAY DIAGNOSTICS${NC}"
    echo "=============================================="
    
    APPGW_NAME="agw-${PROJECT_NAME}-${ENVIRONMENT}"
    
    echo -e "\n${YELLOW}Backend Health:${NC}"
    az network application-gateway show-backend-health --name "$APPGW_NAME" --resource-group "$RESOURCE_GROUP" --query "backendAddressPools[].backendHttpSettingsCollection[].servers[].{address:address,health:health}" -o table 2>/dev/null || echo "❌ No disponible"
    
    echo -e "\n${YELLOW}Backend Pools:${NC}"
    az network application-gateway address-pool list --gateway-name "$APPGW_NAME" --resource-group "$RESOURCE_GROUP" --query "[].{Name:name,BackendAddresses:backendAddresses[].fqdn}" -o table 2>/dev/null || echo "❌ No disponible"
    
    echo -e "\n${YELLOW}HTTP Settings:${NC}"
    az network application-gateway http-settings list --gateway-name "$APPGW_NAME" --resource-group "$RESOURCE_GROUP" --query "[].{Name:name,Protocol:protocol,Port:port,Timeout:requestTimeout}" -o table 2>/dev/null || echo "❌ No disponible"
    
    echo -e "\n${YELLOW}Listeners:${NC}"
    az network application-gateway http-listener list --gateway-name "$APPGW_NAME" --resource-group "$RESOURCE_GROUP" --query "[].{Name:name,FrontendPort:frontendPort.id,Protocol:protocol}" -o table 2>/dev/null || echo "❌ No disponible"
}

# Función 7: Métricas de performance
show_performance_metrics() {
    echo -e "\n${BLUE}📈 MÉTRICAS DE PERFORMANCE${NC}"
    echo "===================================="
    
    echo -e "\n${YELLOW}Container Apps Metrics (últimas 24h):${NC}"
    APPS=$(az containerapp list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null)
    
    for app in $APPS; do
        echo -e "\n${CYAN}📊 Métricas de $app:${NC}"
        
        # CPU utilization
        az monitor metrics list \
            --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.App/containerApps/$app" \
            --metric "CpuPercentage" \
            --interval PT1H \
            --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ) \
            --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
            --query "value[0].timeseries[0].data[-1].average" -o tsv 2>/dev/null | xargs -I {} echo "CPU promedio: {}%"
        
        # Memory utilization
        az monitor metrics list \
            --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.App/containerApps/$app" \
            --metric "MemoryPercentage" \
            --interval PT1H \
            --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ) \
            --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
            --query "value[0].timeseries[0].data[-1].average" -o tsv 2>/dev/null | xargs -I {} echo "Memoria promedio: {}%"
        
        # Request count
        az monitor metrics list \
            --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.App/containerApps/$app" \
            --metric "Requests" \
            --interval PT1H \
            --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
            --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
            --query "value[0].timeseries[0].data[-1].total" -o tsv 2>/dev/null | xargs -I {} echo "Requests última hora: {}"
    done
}

# Función 8: Restart de aplicaciones
restart_applications() {
    echo -e "\n${BLUE}🔄 RESTART DE APLICACIONES${NC}"
    echo "================================="
    
    echo -e "\n${YELLOW}Container Apps disponibles:${NC}"
    APPS=$(az containerapp list --resource-group "$RESOURCE_GROUP" --query "[].name" -o tsv 2>/dev/null)
    
    if [[ -z "$APPS" ]]; then
        echo "❌ No se encontraron Container Apps"
        return
    fi
    
    echo "$APPS" | nl
    echo ""
    echo -n "Selecciona el número de la app para reiniciar (0 para todas): "
    read -r app_number
    
    if [[ "$app_number" == "0" ]]; then
        echo -e "\n${YELLOW}⚠️  ¿Estás seguro de reiniciar TODAS las aplicaciones? (y/N):${NC}"
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            for app in $APPS; do
                echo "Reiniciando $app..."
                az containerapp revision restart --name "$app" --resource-group "$RESOURCE_GROUP" --revision-name "$(az containerapp revision list --name "$app" --resource-group "$RESOURCE_GROUP" --query "[?properties.active].name" -o tsv)" 2>/dev/null || echo "❌ Error reiniciando $app"
            done
        fi
    else
        APP_NAME=$(echo "$APPS" | sed -n "${app_number}p")
        if [[ -n "$APP_NAME" ]]; then
            echo "Reiniciando $APP_NAME..."
            az containerapp revision restart --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --revision-name "$(az containerapp revision list --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" --query "[?properties.active].name" -o tsv)" 2>/dev/null || echo "❌ Error reiniciando $APP_NAME"
        else
            echo "❌ Selección inválida"
        fi
    fi
}

# Función 9: Limpiar logs antiguos
cleanup_old_logs() {
    echo -e "\n${BLUE}🧹 LIMPIAR LOGS ANTIGUOS${NC}"
    echo "==============================="
    
    LOG_WORKSPACE=$(az monitor log-analytics workspace list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv 2>/dev/null)
    
    if [[ -z "$LOG_WORKSPACE" ]]; then
        echo "❌ No se encontró Log Analytics Workspace"
        return
    fi
    
    echo -e "${YELLOW}Log Analytics Workspace encontrado: $LOG_WORKSPACE${NC}"
    echo ""
    echo "Opciones de limpieza:"
    echo "1. Ver espacio usado por tabla"
    echo "2. Configurar retención de logs"
    echo "3. Purgar logs de aplicación específica"
    echo ""
    echo -n "Selecciona opción: "
    read -r cleanup_option
    
    case $cleanup_option in
        1)
            echo -e "\n${BLUE}📊 Espacio usado por tabla:${NC}"
            az monitor log-analytics query \
                --workspace "$LOG_WORKSPACE" \
                --analytics-query "Usage | where TimeGenerated > ago(30d) | summarize TotalVolumeGB = sum(Quantity) / 1000 by DataType | order by TotalVolumeGB desc" \
                --query "tables[0].rows" -o table 2>/dev/null || echo "❌ Error consultando datos"
            ;;
        2)
            echo -e "\n${YELLOW}Configuración actual de retención:${NC}"
            az monitor log-analytics workspace show --workspace-name "$LOG_WORKSPACE" --resource-group "$RESOURCE_GROUP" --query "retentionInDays" -o tsv
            echo ""
            echo -n "Nuevos días de retención (30-730): "
            read -r retention_days
            if [[ "$retention_days" -ge 30 && "$retention_days" -le 730 ]]; then
                az monitor log-analytics workspace update --workspace-name "$LOG_WORKSPACE" --resource-group "$RESOURCE_GROUP" --retention-time "$retention_days"
                echo -e "${GREEN}✅ Retención actualizada a $retention_days días${NC}"
            else
                echo "❌ Valor inválido (debe estar entre 30 y 730)"
            fi
            ;;
        3)
            echo -e "\n${YELLOW}⚠️  La purga de logs específicos requiere permisos especiales${NC}"
            echo "Consulta la documentación de Azure para configurar data purge"
            ;;
        *)
            echo "❌ Opción inválida"
            ;;
    esac
}

# Menú principal
while true; do
    show_menu
    read -r option
    
    case $option in
        1) check_resources_status ;;
        2) check_container_apps ;;
        3) show_realtime_logs ;;
        4) test_connectivity ;;
        5) check_database_info ;;
        6) check_appgateway_diagnostics ;;
        7) show_performance_metrics ;;
        8) restart_applications ;;
        9) cleanup_old_logs ;;
        0) 
            echo -e "\n${GREEN}¡Hasta luego! 👋${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opción inválida${NC}"
            ;;
    esac
    
    echo -e "\n${CYAN}Presiona Enter para continuar...${NC}"
    read -r
done
