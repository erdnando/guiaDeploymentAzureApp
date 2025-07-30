#!/bin/bash

# 🛡️ Script de Validación de Compliance BICEP con Azure Policies
# Verifica que todos los templates BICEP cumplan con las políticas organizacionales

echo "🛡️ VALIDACIÓN DE COMPLIANCE BICEP CON AZURE POLICIES"
echo "=================================================="
echo ""

# Variables de configuración
RESOURCE_GROUP="rg-paymentapp-dev-canada-bicep"
LOCATION="canadacentral"
REQUIRED_TAG="Project"
MAIN_TEMPLATE="main.bicep"
PARAMETERS_FILE="parameters/dev-parameters.json"

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar resultado
show_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        exit 1
    fi
}

echo "${BLUE}📋 Verificando Azure Policies configuradas:${NC}"
echo "   1. Require a tag on resources: 'Project'"
echo "   2. Allowed locations: 'canadacentral'"
echo ""

# 1. Crear resource group de prueba si no existe
echo "${YELLOW}🔍 Verificando Resource Group...${NC}"
if ! az group show --name $RESOURCE_GROUP > /dev/null 2>&1; then
    echo "Creando resource group de prueba..."
    az group create --name $RESOURCE_GROUP --location $LOCATION > /dev/null
fi
show_result $? "Resource Group $RESOURCE_GROUP disponible en $LOCATION"

# 2. Validar template principal BICEP
echo ""
echo "${YELLOW}🔍 Validando Template BICEP Principal...${NC}"

echo "  Validando sintaxis BICEP..."
az deployment group validate \
    --resource-group $RESOURCE_GROUP \
    --template-file $MAIN_TEMPLATE \
    --parameters @$PARAMETERS_FILE \
    --output none 2>/dev/null

show_result $? "Template BICEP principal - Sintaxis válida"

# 3. Verificar ubicación en parámetros
location_in_params=$(jq -r '.parameters.location.value' $PARAMETERS_FILE)
if [ "$location_in_params" = "$LOCATION" ]; then
    echo -e "    ${GREEN}✅ Ubicación: $location_in_params${NC}"
else
    echo -e "    ${RED}❌ Ubicación incorrecta: $location_in_params (esperado: $LOCATION)${NC}"
    exit 1
fi

# 4. Verificar parámetros de governance
echo ""
echo "${YELLOW}🔍 Verificando parámetros de governance...${NC}"

cost_center=$(jq -r '.parameters.costCenter.value' $PARAMETERS_FILE)
if [ "$cost_center" != "null" ] && [ "$cost_center" != "" ]; then
    echo -e "    ${GREEN}✅ CostCenter configurado: $cost_center${NC}"
else
    echo -e "    ${RED}❌ CostCenter faltante${NC}"
    exit 1
fi

owner=$(jq -r '.parameters.owner.value' $PARAMETERS_FILE)
if [ "$owner" != "null" ] && [ "$owner" != "" ]; then
    echo -e "    ${GREEN}✅ Owner configurado: $owner${NC}"
else
    echo -e "    ${RED}❌ Owner faltante${NC}"
    exit 1
fi

# 5. Verificar módulos BICEP individuales
echo ""
echo "${YELLOW}🔍 Verificando módulos BICEP...${NC}"

modules=(
    "bicep/modules/01-infrastructure.bicep:Infrastructure"
    "bicep/modules/02-postgresql.bicep:PostgreSQL"
    "bicep/modules/03-containerapp-environment.bicep:Container Environment"
    "bicep/modules/04-application-gateway.bicep:Application Gateway"
    "bicep/modules/05-monitoring.bicep:Monitoring"
    "bicep/modules/06-container-apps.bicep:Container Apps"
)

for module_info in "${modules[@]}"; do
    IFS=':' read -r module_path module_name <<< "$module_info"
    
    if [ -f "$module_path" ]; then
        echo "  Verificando $module_name..."
        
        # Verificar que tiene parámetros de governance
        if grep -q "param costCenter" "$module_path" && grep -q "param owner" "$module_path"; then
            echo -e "    ${GREEN}✅ Parámetros de governance presentes${NC}"
        else
            echo -e "    ${YELLOW}⚠️ Parámetros de governance faltantes (no crítico para algunos módulos)${NC}"
        fi
        
        # Verificar commonTags
        if grep -q "CostCenter:" "$module_path" && grep -q "Project:" "$module_path"; then
            echo -e "    ${GREEN}✅ Tags de compliance configurados${NC}"
        else
            echo -e "    ${RED}❌ Tags de compliance faltantes${NC}"
            exit 1
        fi
    else
        echo -e "    ${YELLOW}⚠️ Módulo $module_name no encontrado (opcional)${NC}"
    fi
    echo ""
done

# 6. Ejecutar what-if para verificar tags finales
echo "${YELLOW}🔍 Ejecutando What-If de template principal...${NC}"
what_if_output=$(az deployment group what-if \
    --resource-group $RESOURCE_GROUP \
    --template-file $MAIN_TEMPLATE \
    --parameters @$PARAMETERS_FILE \
    --output json 2>/dev/null)

# Verificar que el output contiene ubicación correcta
if echo "$what_if_output" | grep -q "canadacentral"; then
    echo -e "${GREEN}✅ What-if confirma ubicación 'canadacentral'${NC}"
else
    echo -e "${RED}❌ What-if no muestra ubicación correcta${NC}"
    exit 1
fi

# Verificar que contiene tag Project
if echo "$what_if_output" | grep -q '"Project"'; then
    echo -e "${GREEN}✅ What-if confirma tag 'Project' será aplicado${NC}"
else
    echo -e "${RED}❌ What-if no muestra tag 'Project'${NC}"
    exit 1
fi

echo ""
echo "${GREEN}🎉 VALIDACIÓN BICEP COMPLETADA EXITOSAMENTE${NC}"
echo ""
echo "${BLUE}📋 Resumen de Compliance:${NC}"
echo "   ✅ Template BICEP principal sintácticamente válido"
echo "   ✅ Ubicación configurada: $LOCATION"
echo "   ✅ Tag 'Project' requerido presente"
echo "   ✅ Parámetros de governance configurados"
echo "   ✅ What-if confirma configuración correcta"
echo ""

# Preguntar si quiere limpiar el resource group de prueba
echo "${YELLOW}🧹 ¿Eliminar el resource group de prueba '$RESOURCE_GROUP'? (y/N):${NC}"
read -r cleanup_response
if [[ "$cleanup_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "🗑️ Eliminando resource group de prueba..."
    az group delete --name $RESOURCE_GROUP --yes --no-wait
    echo -e "${GREEN}✅ Resource group marcado para eliminación${NC}"
    echo -e "${YELLOW}📝 Nota: La eliminación puede tardar unos minutos${NC}"
else
    echo -e "${YELLOW}⚠️ Recuerda eliminar manualmente: az group delete --name $RESOURCE_GROUP --yes${NC}"
fi

echo ""
echo "${BLUE}🚀 Próximos pasos:${NC}"
echo "   1. Desplegar BICEP: az deployment group create --resource-group <rg> --template-file $MAIN_TEMPLATE --parameters @$PARAMETERS_FILE"
echo "   2. Verificar tags post-despliegue: az resource list --resource-group <rg> --query '[].{Name:name, Tags:tags}'"
echo "   3. Comparar con implementación ARM equivalente"
echo "   4. Configurar alertas de costos por CostCenter"
echo ""
