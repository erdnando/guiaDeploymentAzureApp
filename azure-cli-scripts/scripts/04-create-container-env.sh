#!/bin/bash

# ============================================================================
# 04-create-container-env.sh
# Crear Container Apps Environment
# ============================================================================

set -e  # Salir si algún comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE} 04 - CREAR CONTAINER APPS ENVIRONMENT${NC}"
echo -e "${BLUE}============================================================================${NC}"

# ¿Qué estamos haciendo?
echo -e "\n${YELLOW}¿QUÉ ESTAMOS HACIENDO?${NC}"
echo "Creando el Container Apps Environment que hospedará nuestras aplicaciones"
echo "Este será el entorno gestionado donde se ejecutarán los containers"

# ¿Por qué?
echo -e "\n${YELLOW}¿POR QUÉ?${NC}"
echo "Container Apps Environment proporciona:"
echo "• Gestión automática de infraestructura Kubernetes"
echo "• Networking aislado y seguro"
echo "• Integración con Log Analytics"
echo "• Scaling automático y gestión de tráfico"

# Validar variables requeridas
echo -e "\n${BLUE}🔍 VALIDANDO VARIABLES...${NC}"
if [[ -z "$RESOURCE_GROUP" ]]; then
    echo -e "${RED}❌ Error: RESOURCE_GROUP no está definido${NC}"
    echo "Ejecuta: source parameters/dev.env"
    exit 1
fi

required_vars=("PROJECT_NAME" "ENVIRONMENT" "LOCATION" "LOG_WORKSPACE_NAME")
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo -e "${RED}❌ Error: Variable $var no está definida${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ Variables validadas${NC}"

# Definir nombres de recursos
CONTAINER_ENV_NAME="cae-${PROJECT_NAME}-${ENVIRONMENT}"
LOG_WORKSPACE_FULL="log-${PROJECT_NAME}-${ENVIRONMENT}"

echo -e "\n${BLUE}📋 RECURSOS A CREAR:${NC}"
echo "• Container Apps Environment: $CONTAINER_ENV_NAME"
echo "• Ubicación: $LOCATION"
echo "• Resource Group: $RESOURCE_GROUP"
echo "• Log Analytics: $LOG_WORKSPACE_FULL"

# CHECKPOINT: Verificar que Log Analytics existe
echo -e "\n${YELLOW}🔍 CHECKPOINT: Verificando Log Analytics Workspace...${NC}"
LOG_WORKSPACE_ID=$(az monitor log-analytics workspace show \
    --resource-group "$RESOURCE_GROUP" \
    --workspace-name "$LOG_WORKSPACE_FULL" \
    --query "id" -o tsv 2>/dev/null || echo "")

if [[ -z "$LOG_WORKSPACE_ID" ]]; then
    echo -e "${RED}❌ Log Analytics Workspace no encontrado${NC}"
    echo "Ejecuta primero: ./05-create-monitoring.sh"
    exit 1
fi

echo -e "${GREEN}✅ Log Analytics Workspace encontrado: $LOG_WORKSPACE_ID${NC}"

# Verificar si Container Apps Environment ya existe
echo -e "\n${YELLOW}🔍 CHECKPOINT: Verificando si Container Apps Environment existe...${NC}"
EXISTING_ENV=$(az containerapp env show \
    --name "$CONTAINER_ENV_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "name" -o tsv 2>/dev/null || echo "")

if [[ -n "$EXISTING_ENV" ]]; then
    echo -e "${YELLOW}⚠️  Container Apps Environment ya existe: $EXISTING_ENV${NC}"
    echo "¿Deseas continuar? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Operación cancelada"
        exit 0
    fi
else
    echo -e "${GREEN}✅ Listo para crear Container Apps Environment${NC}"
fi

# Crear Container Apps Environment
echo -e "\n${BLUE}🚀 CREANDO CONTAINER APPS ENVIRONMENT...${NC}"
echo "Comando a ejecutar:"
echo "az containerapp env create \\"
echo "  --name $CONTAINER_ENV_NAME \\"
echo "  --resource-group $RESOURCE_GROUP \\"
echo "  --location $LOCATION \\"
echo "  --logs-workspace-id $LOG_WORKSPACE_ID"

az containerapp env create \
    --name "$CONTAINER_ENV_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --logs-workspace-id "$LOG_WORKSPACE_ID" \
    --output table

# APRENDIZAJE: Conceptos técnicos
echo -e "\n${YELLOW}📚 APRENDIZAJE: Container Apps Environment${NC}"
echo ""
echo "🏗️  ARQUITECTURA:"
echo "   Container Apps Environment es una 'boundary' lógica donde:"
echo "   • Se ejecutan múltiples Container Apps"
echo "   • Se comparte la misma VNet y subnet"
echo "   • Se centraliza logging y monitoring"
echo ""
echo "🔗 COMPONENTES CLAVE:"
echo "   • Control Plane: Gestión de Kubernetes (invisible para el usuario)"
echo "   • Data Plane: Donde se ejecutan los containers"
echo "   • Log Analytics: Centralización de logs y métricas"
echo ""
echo "⚡ BENEFICIOS:"
echo "   • Sin gestión de nodos Kubernetes"
echo "   • Auto-scaling basado en demanda"
echo "   • Networking simplificado"
echo "   • Integración nativa con Azure"

# Verificar creación exitosa
echo -e "\n${YELLOW}🔍 CHECKPOINT: Verificando Container Apps Environment...${NC}"
ENV_STATUS=$(az containerapp env show \
    --name "$CONTAINER_ENV_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.provisioningState" -o tsv)

if [[ "$ENV_STATUS" == "Succeeded" ]]; then
    echo -e "${GREEN}✅ Container Apps Environment creado exitosamente${NC}"
else
    echo -e "${RED}❌ Error en la creación. Estado: $ENV_STATUS${NC}"
    exit 1
fi

# Mostrar información del environment
echo -e "\n${BLUE}📊 INFORMACIÓN DEL ENVIRONMENT:${NC}"
az containerapp env show \
    --name "$CONTAINER_ENV_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "{
        name: name,
        location: location,
        provisioningState: properties.provisioningState,
        defaultDomain: properties.defaultDomain,
        staticIp: properties.staticIp
    }" \
    --output table

# LOGRO
echo -e "\n${GREEN}🎉 LOGRO ALCANZADO:${NC}"
echo "✅ Container Apps Environment configurado"
echo "✅ Integración con Log Analytics establecida"
echo "✅ Infraestructura lista para aplicaciones"
echo ""
echo -e "${BLUE}📍 SIGUIENTE PASO:${NC}"
echo "Ejecutar: ./06-deploy-applications.sh"
echo ""
echo -e "${YELLOW}💡 TIP:${NC}"
echo "Puedes ver el environment en Azure Portal > Container Apps > Environments"
