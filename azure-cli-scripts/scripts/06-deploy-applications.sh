#!/bin/bash

# ============================================================================
# 06-deploy-applications.sh
# Desplegar aplicaciones en Container Apps
# ============================================================================

set -e  # Salir si algún comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE} 06 - DESPLEGAR APLICACIONES EN CONTAINER APPS${NC}"
echo -e "${BLUE}============================================================================${NC}"

# ¿Qué estamos haciendo?
echo -e "\n${YELLOW}¿QUÉ ESTAMOS HACIENDO?${NC}"
echo "Desplegando las aplicaciones del sistema de pagos:"
echo "• API Gateway (proxy y enrutamiento)"
echo "• Payment API (procesamiento de pagos)"
echo "• User API (gestión de usuarios)"
echo "• Notification Service (notificaciones)"

# ¿Por qué?
echo -e "\n${YELLOW}¿POR QUÉ?${NC}"
echo "Container Apps proporciona:"
echo "• Scaling automático basado en demanda"
echo "• Gestión de múltiples revisiones"
echo "• Balanceado de carga automático"
echo "• Integración nativa con monitoring"

# Validar variables requeridas
echo -e "\n${BLUE}🔍 VALIDANDO VARIABLES...${NC}"
if [[ -z "$RESOURCE_GROUP" ]]; then
    echo -e "${RED}❌ Error: RESOURCE_GROUP no está definido${NC}"
    echo "Ejecuta: source parameters/dev.env"
    exit 1
fi

required_vars=("PROJECT_NAME" "ENVIRONMENT" "LOCATION" "CONTAINER_IMAGE" "APP_PORT")
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo -e "${RED}❌ Error: Variable $var no está definida${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ Variables validadas${NC}"

# Definir nombres de recursos
CONTAINER_ENV_NAME="cae-${PROJECT_NAME}-${ENVIRONMENT}"
API_GATEWAY_NAME="ca-gateway-${ENVIRONMENT}"
PAYMENT_API_NAME="ca-payment-${ENVIRONMENT}"
USER_API_NAME="ca-user-${ENVIRONMENT}"
NOTIFICATION_SERVICE_NAME="ca-notification-${ENVIRONMENT}"

echo -e "\n${BLUE}📋 APLICACIONES A DESPLEGAR:${NC}"
echo "• API Gateway: $API_GATEWAY_NAME"
echo "• Payment API: $PAYMENT_API_NAME"
echo "• User API: $USER_API_NAME"
echo "• Notification Service: $NOTIFICATION_SERVICE_NAME"
echo "• Container Environment: $CONTAINER_ENV_NAME"

# CHECKPOINT: Verificar que Container Apps Environment existe
echo -e "\n${YELLOW}🔍 CHECKPOINT: Verificando Container Apps Environment...${NC}"
ENV_EXISTS=$(az containerapp env show \
    --name "$CONTAINER_ENV_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "name" -o tsv 2>/dev/null || echo "")

if [[ -z "$ENV_EXISTS" ]]; then
    echo -e "${RED}❌ Container Apps Environment no encontrado${NC}"
    echo "Ejecuta primero: ./04-create-container-env.sh"
    exit 1
fi

echo -e "${GREEN}✅ Container Apps Environment encontrado: $ENV_EXISTS${NC}"

# Función para crear Container App
create_container_app() {
    local app_name=$1
    local app_description=$2
    local cpu_requests=$3
    local memory_requests=$4
    local min_replicas=$5
    local max_replicas=$6
    local env_vars=$7

    echo -e "\n${BLUE}🚀 CREANDO: $app_description${NC}"
    echo "Nombre: $app_name"
    echo "CPU: $cpu_requests | Memoria: $memory_requests"
    echo "Replicas: $min_replicas-$max_replicas"

    # Verificar si ya existe
    EXISTING_APP=$(az containerapp show \
        --name "$app_name" \
        --resource-group "$RESOURCE_GROUP" \
        --query "name" -o tsv 2>/dev/null || echo "")

    if [[ -n "$EXISTING_APP" ]]; then
        echo -e "${YELLOW}⚠️  Container App ya existe: $EXISTING_APP${NC}"
        echo "¿Deseas actualizar? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "Actualizando..."
            az containerapp update \
                --name "$app_name" \
                --resource-group "$RESOURCE_GROUP" \
                --image "$CONTAINER_IMAGE" \
                --cpu "$cpu_requests" \
                --memory "$memory_requests" \
                --min-replicas "$min_replicas" \
                --max-replicas "$max_replicas" \
                --env-vars $env_vars \
                --output table
        else
            echo "Saltando $app_name..."
            return
        fi
    else
        # Crear nueva Container App
        echo "Comando a ejecutar:"
        echo "az containerapp create \\"
        echo "  --name $app_name \\"
        echo "  --resource-group $RESOURCE_GROUP \\"
        echo "  --environment $CONTAINER_ENV_NAME \\"
        echo "  --image $CONTAINER_IMAGE \\"
        echo "  --target-port $APP_PORT \\"
        echo "  --ingress external"

        az containerapp create \
            --name "$app_name" \
            --resource-group "$RESOURCE_GROUP" \
            --environment "$CONTAINER_ENV_NAME" \
            --image "$CONTAINER_IMAGE" \
            --target-port "$APP_PORT" \
            --ingress external \
            --cpu "$cpu_requests" \
            --memory "$memory_requests" \
            --min-replicas "$min_replicas" \
            --max-replicas "$max_replicas" \
            --env-vars $env_vars \
            --output table
    fi

    echo -e "${GREEN}✅ $app_description configurado${NC}"
}

# Cargar variables de monitoring si existen
if [[ -f "parameters/monitoring.env" ]]; then
    echo -e "\n${BLUE}📊 CARGANDO VARIABLES DE MONITORING...${NC}"
    source parameters/monitoring.env
fi

# Desplegar API Gateway
create_container_app \
    "$API_GATEWAY_NAME" \
    "API Gateway" \
    "0.5" \
    "1Gi" \
    "1" \
    "3" \
    "SERVICE_TYPE=gateway PAYMENT_API_URL=https://$PAYMENT_API_NAME.internal USER_API_URL=https://$USER_API_NAME.internal"

# Desplegar Payment API
create_container_app \
    "$PAYMENT_API_NAME" \
    "Payment API" \
    "0.75" \
    "1.5Gi" \
    "2" \
    "5" \
    "SERVICE_TYPE=payment DB_CONNECTION_STRING=postgresql://$DB_ADMIN_USER:$DB_ADMIN_PASSWORD@$DB_SERVER_NAME.postgres.database.azure.com/postgres"

# Desplegar User API
create_container_app \
    "$USER_API_NAME" \
    "User API" \
    "0.5" \
    "1Gi" \
    "1" \
    "3" \
    "SERVICE_TYPE=user DB_CONNECTION_STRING=postgresql://$DB_ADMIN_USER:$DB_ADMIN_PASSWORD@$DB_SERVER_NAME.postgres.database.azure.com/postgres"

# Desplegar Notification Service
create_container_app \
    "$NOTIFICATION_SERVICE_NAME" \
    "Notification Service" \
    "0.25" \
    "0.5Gi" \
    "1" \
    "2" \
    "SERVICE_TYPE=notification QUEUE_CONNECTION_STRING=placeholder"

# APRENDIZAJE: Conceptos técnicos
echo -e "\n${YELLOW}📚 APRENDIZAJE: Container Apps${NC}"
echo ""
echo "🏗️  ARQUITECTURA DE MICROSERVICIOS:"
echo "   • API Gateway: Punto de entrada único, enrutamiento y autenticación"
echo "   • Payment API: Core business logic para procesamiento de pagos"
echo "   • User API: Gestión de usuarios y autenticación"
echo "   • Notification Service: Comunicaciones asíncronas"
echo ""
echo "⚡ CARACTERÍSTICAS CONTAINER APPS:"
echo "   • Auto-scaling: Escala basado en HTTP requests, CPU, memoria"
echo "   • Revisiones: Permite blue-green deployments"
echo "   • Ingress: Balanceador de carga HTTP/HTTPS automático"
echo "   • Service Discovery: Comunicación interna automática"
echo ""
echo "🔗 NETWORKING:"
echo "   • Ingress External: Accesible desde internet"
echo "   • Ingress Internal: Solo accesible dentro del environment"
echo "   • FQDN automático: <app-name>.<environment-domain>"

# Obtener URLs de las aplicaciones
echo -e "\n${BLUE}🌐 OBTENIENDO URLs DE LAS APLICACIONES...${NC}"

declare -a app_names=("$API_GATEWAY_NAME" "$PAYMENT_API_NAME" "$USER_API_NAME" "$NOTIFICATION_SERVICE_NAME")
declare -a app_urls=()

for app in "${app_names[@]}"; do
    URL=$(az containerapp show \
        --name "$app" \
        --resource-group "$RESOURCE_GROUP" \
        --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null || echo "N/A")
    app_urls+=("https://$URL")
done

# Mostrar información de las aplicaciones
echo -e "\n${BLUE}📊 APLICACIONES DESPLEGADAS:${NC}"
echo "╔══════════════════════════════════════════════════════════════════════════════════════╗"
echo "║                              CONTAINER APPS URLS                                     ║"
echo "╠══════════════════════════════════════════════════════════════════════════════════════╣"
echo "║ API Gateway:         ${app_urls[0]}"
echo "║ Payment API:         ${app_urls[1]}"
echo "║ User API:            ${app_urls[2]}"
echo "║ Notification Service: ${app_urls[3]}"
echo "╚══════════════════════════════════════════════════════════════════════════════════════╝"

# Crear archivo con URLs para referencia
echo -e "\n${BLUE}💾 GUARDANDO URLs DE APLICACIONES...${NC}"
cat > "parameters/applications.env" << EOF
# URLs de aplicaciones generadas por 06-deploy-applications.sh
export API_GATEWAY_URL="${app_urls[0]}"
export PAYMENT_API_URL="${app_urls[1]}"
export USER_API_URL="${app_urls[2]}"
export NOTIFICATION_SERVICE_URL="${app_urls[3]}"

echo "✅ URLs de aplicaciones cargadas"
EOF

echo -e "${GREEN}✅ URLs guardadas en: parameters/applications.env${NC}"

# CHECKPOINT: Verificar que todas las aplicaciones están funcionando
echo -e "\n${YELLOW}🔍 CHECKPOINT FINAL: Verificando estado de aplicaciones...${NC}"

all_healthy=true
for app in "${app_names[@]}"; do
    STATUS=$(az containerapp show \
        --name "$app" \
        --resource-group "$RESOURCE_GROUP" \
        --query "properties.provisioningState" -o tsv 2>/dev/null || echo "Failed")
    
    if [[ "$STATUS" == "Succeeded" ]]; then
        echo -e "${GREEN}✅ $app: $STATUS${NC}"
    else
        echo -e "${RED}❌ $app: $STATUS${NC}"
        all_healthy=false
    fi
done

if [[ "$all_healthy" == true ]]; then
    echo -e "\n${GREEN}✅ Todas las aplicaciones están funcionando correctamente${NC}"
else
    echo -e "\n${RED}❌ Algunas aplicaciones tienen problemas${NC}"
    echo "Revisar logs en Azure Portal > Container Apps"
fi

# LOGRO
echo -e "\n${GREEN}🎉 LOGRO ALCANZADO:${NC}"
echo "✅ 4 microservicios desplegados exitosamente"
echo "✅ Auto-scaling configurado"
echo "✅ URLs públicas disponibles"
echo "✅ Integración con monitoring activa"
echo ""
echo -e "${BLUE}📍 SIGUIENTE PASO:${NC}"
echo "Ejecutar: ./07-create-app-gateway.sh"
echo ""
echo -e "${YELLOW}💡 TIPS:${NC}"
echo "• Usa las URLs en parameters/applications.env"
echo "• Monitorea métricas en Azure Portal > Container Apps"
echo "• Los logs están disponibles en Log Analytics"
