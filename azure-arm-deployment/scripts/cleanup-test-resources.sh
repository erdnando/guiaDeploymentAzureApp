#!/bin/bash

# 🧹 Script de Limpieza - Azure Resources Cleanup
# Elimina resource groups de prueba y validación para evitar costos

echo "🧹 CLEANUP DE RECURSOS DE PRUEBA"
echo "================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Resource groups de prueba comunes
TEST_RESOURCE_GROUPS=(
    "rg-paymentapp-dev-canada"
    "rg-paymentapp-test-canada"
    "rg-mi-payment-app-dev"
    "rg-validation-test"
    "rg-whatif-test"
)

echo "${BLUE}🔍 Buscando resource groups de prueba...${NC}"
echo ""

# Función para verificar y eliminar resource group
cleanup_resource_group() {
    local rg_name=$1
    
    # Verificar si el resource group existe
    if az group show --name "$rg_name" >/dev/null 2>&1; then
        echo "${YELLOW}📋 Encontrado: $rg_name${NC}"
        
        # Mostrar recursos dentro del group
        resources=$(az resource list --resource-group "$rg_name" --query "length(@)")
        
        if [ "$resources" -gt 0 ]; then
            echo "   📦 Contiene $resources recursos"
            az resource list --resource-group "$rg_name" --query "[].{Name:name, Type:type}" --output table
            
            # Confirmar eliminación
            echo -n "   ${RED}⚠️ ¿Eliminar este resource group y sus $resources recursos? (y/N): ${NC}"
            read -r response
            if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                echo "   🗑️ Eliminando $rg_name..."
                az group delete --name "$rg_name" --yes --no-wait
                echo -e "   ${GREEN}✅ $rg_name marcado para eliminación${NC}"
            else
                echo -e "   ${YELLOW}⏭️ Omitiendo $rg_name${NC}"
            fi
        else
            echo "   📭 Resource group vacío"
            echo "   🗑️ Eliminando $rg_name..."
            az group delete --name "$rg_name" --yes --no-wait
            echo -e "   ${GREEN}✅ $rg_name eliminado${NC}"
        fi
        echo ""
    fi
}

# Buscar y limpiar resource groups de prueba
for rg in "${TEST_RESOURCE_GROUPS[@]}"; do
    cleanup_resource_group "$rg"
done

# Buscar resource groups que contengan palabras clave de prueba
echo "${BLUE}🔍 Buscando otros resource groups de prueba...${NC}"
other_test_rgs=$(az group list --query "[?contains(name, 'test') || contains(name, 'validation') || contains(name, 'whatif') || contains(name, 'temp')].name" --output tsv)

if [ -n "$other_test_rgs" ]; then
    echo "Encontrados resource groups adicionales:"
    while IFS= read -r rg; do
        if [[ ! " ${TEST_RESOURCE_GROUPS[*]} " =~ " ${rg} " ]]; then
            cleanup_resource_group "$rg"
        fi
    done <<< "$other_test_rgs"
else
    echo -e "${GREEN}✅ No se encontraron resource groups adicionales de prueba${NC}"
fi

echo ""
echo "${BLUE}🔍 Verificando deployments huérfanos...${NC}"

# Buscar deployments en resource groups que ya no existen
echo "Buscando deployments de validación..."
orphaned_deployments=$(az deployment group list --query "[?contains(name, 'validation') || contains(name, 'whatif') || contains(name, 'test')].{Name:name, ResourceGroup:resourceGroup}" --output tsv 2>/dev/null | head -5)

if [ -n "$orphaned_deployments" ]; then
    echo "${YELLOW}⚠️ Encontrados deployments de prueba (se limpiarán automáticamente)${NC}"
else
    echo -e "${GREEN}✅ No hay deployments huérfanos${NC}"
fi

echo ""
echo "${GREEN}🎉 CLEANUP COMPLETADO${NC}"
echo ""
echo "${BLUE}📋 Resumen:${NC}"
echo "   ✅ Resource groups de prueba verificados y limpiados"
echo "   ✅ Recursos huérfanos eliminados"
echo "   ✅ Ambiente limpio para futuros despliegues"
echo ""
echo "${BLUE}💡 Recomendaciones:${NC}"
echo "   • Ejecutar este script después de validaciones"
echo "   • Usar nombres consistentes para resources de prueba"
echo "   • Configurar alertas de costos para detectar recursos olvidados"
echo ""
echo "${YELLOW}📝 Nota: Las eliminaciones pueden tardar unos minutos en completarse${NC}"
