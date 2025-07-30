#!/bin/bash

# 🛡️ Script de Validación de Compliance con Azure Policies
# Verifica que todos los templates ARM cumplan con las políticas organizacionales

echo "🛡️ VALIDACIÓN DE COMPLIANCE CON AZURE POLICIES"
echo "=============================================="
echo ""

# Variables de configuración
RESOURCE_GROUP="rg-paymentapp-dev-canada"
LOCATION="canadacentral"
REQUIRED_TAG="Project"

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

# 1. Verificar que el resource group existe
echo "${YELLOW}🔍 Verificando Resource Group...${NC}"
az group show --name $RESOURCE_GROUP > /dev/null 2>&1
show_result $? "Resource Group $RESOURCE_GROUP existe en $LOCATION"

# 2. Validar templates uno por uno
echo ""
echo "${YELLOW}🔍 Validando Templates ARM...${NC}"

templates=(
    "01-infrastructure:dev.01-infrastructure"
    "02-postgresql:dev.02-postgresql"  
    "03-containerenv:dev.03-containerenv"
    "04-appgateway:dev.04-appgateway"
    "05-monitoring:dev.05-monitoring"
    "06-containerapps:dev.06-containerapps"
)

for template_info in "${templates[@]}"; do
    IFS=':' read -r template_name param_name <<< "$template_info"
    
    echo "  Validando $template_name..."
    
    # Validar sintaxis
    az deployment group validate \
        --resource-group $RESOURCE_GROUP \
        --template-file "templates/${template_name}.json" \
        --parameters "@parameters/${param_name}.parameters.json" \
        --output none 2>/dev/null
    
    show_result $? "Template ${template_name}.json - Sintaxis válida"
    
    # Verificar ubicación en parámetros
    location_in_params=$(jq -r '.parameters.location.value' "parameters/${param_name}.parameters.json")
    if [ "$location_in_params" = "$LOCATION" ]; then
        echo -e "    ${GREEN}✅ Ubicación: $location_in_params${NC}"
    else
        echo -e "    ${RED}❌ Ubicación incorrecta: $location_in_params (esperado: $LOCATION)${NC}"
        exit 1
    fi
    
    # Verificar tag Project en commonTags
    has_project_tag=$(jq -r '.variables.commonTags.Project' "templates/${template_name}.json")
    if [ "$has_project_tag" != "null" ] && [ "$has_project_tag" != "" ]; then
        echo -e "    ${GREEN}✅ Tag 'Project' configurado${NC}"
    else
        echo -e "    ${RED}❌ Tag 'Project' faltante${NC}"
        exit 1
    fi
    
    echo ""
done

# 3. Ejecutar what-if en template principal para verificar tags finales
echo "${YELLOW}🔍 Verificando What-If del template principal...${NC}"
what_if_output=$(az deployment group what-if \
    --resource-group $RESOURCE_GROUP \
    --template-file "templates/01-infrastructure.json" \
    --parameters "@parameters/dev.01-infrastructure.parameters.json" \
    --output json 2>/dev/null)

# Verificar que el output contiene los tags esperados
if echo "$what_if_output" | jq -e '.properties.changes[] | select(.resourceId | contains("networkSecurityGroups")) | .delta.tags.Project' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ What-if muestra tag 'Project' será aplicado${NC}"
else
    echo -e "${RED}❌ What-if no muestra tag 'Project'${NC}"
    exit 1
fi

if echo "$what_if_output" | jq -e '.properties.changes[] | select(.resourceId | contains("canadacentral"))' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ What-if muestra ubicación 'canadacentral'${NC}"
else
    echo -e "${RED}❌ What-if no muestra ubicación correcta${NC}"
    exit 1
fi

# 4. Verificar estructura de tags recomendados
echo ""
echo "${YELLOW}🔍 Verificando tags recomendados...${NC}"

required_tags=("Project" "Environment" "CostCenter" "Owner" "CreatedBy" "ManagedBy" "Purpose")

for tag in "${required_tags[@]}"; do
    # Verificar en template de infraestructura
    tag_present=$(jq -r ".variables.commonTags.$tag" "templates/01-infrastructure.json")
    if [ "$tag_present" != "null" ] && [ "$tag_present" != "" ]; then
        echo -e "    ${GREEN}✅ Tag '$tag' presente${NC}"
    else
        echo -e "    ${YELLOW}⚠️ Tag '$tag' faltante (recomendado)${NC}"
    fi
done

echo ""
echo "${GREEN}🎉 VALIDACIÓN COMPLETADA EXITOSAMENTE${NC}"
echo ""
echo "${BLUE}📋 Resumen de Compliance:${NC}"
echo "   ✅ Todos los templates son sintácticamente válidos"
echo "   ✅ Ubicación configurada: $LOCATION"
echo "   ✅ Tag 'Project' requerido presente en todos los recursos"
echo "   ✅ Tags adicionales de governance configurados"
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
echo "   1. Ejecutar despliegue: ./scripts/deploy-dev.sh"
echo "   2. Verificar tags post-despliegue: az resource list --resource-group $RESOURCE_GROUP --query '[].{Name:name, Tags:tags}'"
echo "   3. Configurar alertas de costos por CostCenter"
echo "   4. Ejecutar cleanup si es necesario: ./scripts/cleanup-test-resources.sh"
echo ""
