#!/bin/bash

# ============================================================================
# 05-create-monitoring.sh
# Crear Log Analytics Workspace y Application Insights
# ============================================================================

set -e  # Salir si algún comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE} 05 - CREAR MONITORING (LOG ANALYTICS + APP INSIGHTS)${NC}"
echo -e "${BLUE}============================================================================${NC}"

# ¿Qué estamos haciendo?
echo -e "\n${YELLOW}¿QUÉ ESTAMOS HACIENDO?${NC}"
echo "Creando la infraestructura de monitoreo y observabilidad:"
echo "• Log Analytics Workspace para logs centralizados"
echo "• Application Insights para telemetría de aplicaciones"

# ¿Por qué?
echo -e "\n${YELLOW}¿POR QUÉ?${NC}"
echo "El monitoring es fundamental para:"
echo "• Detectar problemas antes que afecten usuarios"
echo "• Analizar rendimiento y patrones de uso"
echo "• Debugging eficiente en producción"
echo "• Cumplir con SLAs y alertas proactivas"

# Validar variables requeridas
echo -e "\n${BLUE}🔍 VALIDANDO VARIABLES...${NC}"
if [[ -z "$RESOURCE_GROUP" ]]; then
    echo -e "${RED}❌ Error: RESOURCE_GROUP no está definido${NC}"
    echo "Ejecuta: source parameters/dev.env"
    exit 1
fi

required_vars=("PROJECT_NAME" "ENVIRONMENT" "LOCATION" "LOG_WORKSPACE_NAME" "APPINSIGHTS_NAME")
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo -e "${RED}❌ Error: Variable $var no está definida${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ Variables validadas${NC}"

echo -e "\n${BLUE}📋 RECURSOS A CREAR:${NC}"
echo "• Log Analytics Workspace: $LOG_WORKSPACE_NAME"
echo "• Application Insights: $APPINSIGHTS_NAME"
echo "• Ubicación: $LOCATION"
echo "• Resource Group: $RESOURCE_GROUP"

# CHECKPOINT: Verificar si Log Analytics ya existe
echo -e "\n${YELLOW}🔍 CHECKPOINT: Verificando Log Analytics Workspace...${NC}"
EXISTING_WORKSPACE=$(az monitor log-analytics workspace show \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$LOG_WORKSPACE_NAME" \
    --query "name" -o tsv 2>/dev/null || echo "")

if [[ -n "$EXISTING_WORKSPACE" ]]; then
    echo -e "${YELLOW}⚠️  Log Analytics Workspace ya existe: $EXISTING_WORKSPACE${NC}"
    echo "Continuando con Application Insights..."
else
    # Crear Log Analytics Workspace
    echo -e "\n${BLUE}🚀 CREANDO LOG ANALYTICS WORKSPACE...${NC}"
    echo "Comando a ejecutar:"
    echo "az monitor log-analytics workspace create \\"
    echo "  --workspace-name $LOG_WORKSPACE_NAME \\"
    echo "  --resource-group $RESOURCE_GROUP \\"
    echo "  --location $LOCATION"

    az monitor log-analytics workspace create \
        --workspace-name "$LOG_WORKSPACE_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --output table

    echo -e "${GREEN}✅ Log Analytics Workspace creado${NC}"
fi

# Obtener Workspace ID para Application Insights
echo -e "\n${BLUE}🔗 OBTENIENDO WORKSPACE ID...${NC}"
WORKSPACE_ID=$(az monitor log-analytics workspace show \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$LOG_WORKSPACE_NAME" \
    --query "id" -o tsv)

echo "Workspace ID: $WORKSPACE_ID"

# CHECKPOINT: Verificar si Application Insights ya existe
echo -e "\n${YELLOW}🔍 CHECKPOINT: Verificando Application Insights...${NC}"
EXISTING_APPINSIGHTS=$(az monitor app-insights component show \
    --app "$APPINSIGHTS_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "name" -o tsv 2>/dev/null || echo "")

if [[ -n "$EXISTING_APPINSIGHTS" ]]; then
    echo -e "${YELLOW}⚠️  Application Insights ya existe: $EXISTING_APPINSIGHTS${NC}"
    echo "¿Deseas continuar sin recrear? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Operación cancelada"
        exit 0
    fi
else
    # Crear Application Insights
    echo -e "\n${BLUE}🚀 CREANDO APPLICATION INSIGHTS...${NC}"
    echo "Comando a ejecutar:"
    echo "az monitor app-insights component create \\"
    echo "  --app $APPINSIGHTS_NAME \\"
    echo "  --location $LOCATION \\"
    echo "  --resource-group $RESOURCE_GROUP \\"
    echo "  --workspace $WORKSPACE_ID"

    az monitor app-insights component create \
        --app "$APPINSIGHTS_NAME" \
        --location "$LOCATION" \
        --resource-group "$RESOURCE_GROUP" \
        --workspace "$WORKSPACE_ID" \
        --output table

    echo -e "${GREEN}✅ Application Insights creado${NC}"
fi

# APRENDIZAJE: Conceptos técnicos
echo -e "\n${YELLOW}📚 APRENDIZAJE: Monitoring en Azure${NC}"
echo ""
echo "🔍 LOG ANALYTICS WORKSPACE:"
echo "   • Repositorio centralizado de logs y métricas"
echo "   • Motor de consultas KQL (Kusto Query Language)"
echo "   • Retención configurable de datos"
echo "   • Base para alertas y dashboards"
echo ""
echo "📊 APPLICATION INSIGHTS:"
echo "   • Telemetría de aplicaciones (performance, usage, availability)"
echo "   • Distributed tracing para microservicios"
echo "   • Detección automática de anomalías"
echo "   • Integración con Development lifecycle"
echo ""
echo "🔗 INTEGRACIÓN:"
echo "   • App Insights envía datos a Log Analytics"
echo "   • Correlación entre logs de infraestructura y aplicación"
echo "   • Alertas unificadas y dashboards"

# Obtener información de conexión
echo -e "\n${BLUE}🔑 OBTENIENDO CLAVES DE CONEXIÓN...${NC}"

# Application Insights Connection String
APP_INSIGHTS_CONNECTION_STRING=$(az monitor app-insights component show \
    --app "$APPINSIGHTS_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "connectionString" -o tsv)

# Application Insights Instrumentation Key
APP_INSIGHTS_KEY=$(az monitor app-insights component show \
    --app "$APPINSIGHTS_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "instrumentationKey" -o tsv)

# Log Analytics Workspace Key
WORKSPACE_KEY=$(az monitor log-analytics workspace get-shared-keys \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$LOG_WORKSPACE_NAME" \
    --query "primarySharedKey" -o tsv)

# Mostrar información de monitoreo
echo -e "\n${BLUE}📊 INFORMACIÓN DE MONITORING:${NC}"
echo "╔══════════════════════════════════════════════════════════════════════════════════════╗"
echo "║                              MONITORING INFORMATION                                   ║"
echo "╠══════════════════════════════════════════════════════════════════════════════════════╣"
echo "║ Log Analytics Workspace: $LOG_WORKSPACE_NAME"
echo "║ Application Insights: $APPINSIGHTS_NAME"
echo "║ Location: $LOCATION"
echo "╠══════════════════════════════════════════════════════════════════════════════════════╣"
echo "║ CLAVES DE CONEXIÓN:"
echo "║ App Insights Connection String: ${APP_INSIGHTS_CONNECTION_STRING:0:50}..."
echo "║ App Insights Instrumentation Key: ${APP_INSIGHTS_KEY}"
echo "╚══════════════════════════════════════════════════════════════════════════════════════╝"

# Crear archivo con variables de monitoring
echo -e "\n${BLUE}💾 GUARDANDO VARIABLES DE MONITORING...${NC}"
cat > "parameters/monitoring.env" << EOF
# Variables de monitoring generadas por 05-create-monitoring.sh
export LOG_WORKSPACE_NAME="$LOG_WORKSPACE_NAME"
export APPINSIGHTS_NAME="$APPINSIGHTS_NAME"
export APP_INSIGHTS_CONNECTION_STRING="$APP_INSIGHTS_CONNECTION_STRING"
export APP_INSIGHTS_KEY="$APP_INSIGHTS_KEY"
export WORKSPACE_ID="$WORKSPACE_ID"
export WORKSPACE_KEY="$WORKSPACE_KEY"

echo "✅ Variables de monitoring cargadas"
EOF

echo -e "${GREEN}✅ Variables guardadas en: parameters/monitoring.env${NC}"

# CHECKPOINT: Verificar que todo está funcionando
echo -e "\n${YELLOW}🔍 CHECKPOINT FINAL: Verificando recursos de monitoring...${NC}"

# Verificar Log Analytics
LA_STATUS=$(az monitor log-analytics workspace show \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$LOG_WORKSPACE_NAME" \
    --query "provisioningState" -o tsv)

# Verificar Application Insights
AI_STATUS=$(az monitor app-insights component show \
    --app "$APPINSIGHTS_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "provisioningState" -o tsv)

if [[ "$LA_STATUS" == "Succeeded" && "$AI_STATUS" == "Succeeded" ]]; then
    echo -e "${GREEN}✅ Todos los recursos de monitoring están funcionando${NC}"
else
    echo -e "${RED}❌ Problemas detectados:${NC}"
    echo "Log Analytics Status: $LA_STATUS"
    echo "Application Insights Status: $AI_STATUS"
    exit 1
fi

# LOGRO
echo -e "\n${GREEN}🎉 LOGRO ALCANZADO:${NC}"
echo "✅ Log Analytics Workspace configurado"
echo "✅ Application Insights configurado"  
echo "✅ Integración entre servicios establecida"
echo "✅ Claves de conexión disponibles"
echo ""
echo -e "${BLUE}📍 SIGUIENTE PASO:${NC}"
echo "Ejecutar: ./04-create-container-env.sh"
echo ""
echo -e "${YELLOW}💡 TIPS:${NC}"
echo "• Las variables están en: parameters/monitoring.env"
echo "• Puedes consultar logs con KQL en Azure Portal"
echo "• Application Insights detecta automáticamente dependencias"
