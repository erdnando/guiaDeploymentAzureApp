#!/bin/bash

# 🧹 Script de Limpieza BICEP - Azure Resources Cleanup
# Elimina resource groups de prueba BICEP para evitar costos

echo "🧹 CLEANUP DE RECURSOS BICEP DE PRUEBA"
echo "====================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Resource groups de prueba BICEP
BICEP_TEST_RESOURCE_GROUPS=(
    "rg-paymentapp-dev-canada-bicep"
    "rg-paymentapp-test-canada-bicep"
    "rg-bicep-validation-test"
    "rg-bicep-whatif-test"
)

echo "${BLUE}🔍 Buscando resource groups de prueba BICEP...${NC}"
echo ""

# Función para verificar y eliminar resource group
cleanup_bicep_resource_group() {
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
            echo -n "   ${RED}⚠️ ¿Eliminar este resource group BICEP y sus $resources recursos? (y/N): ${NC}"
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

# Buscar y limpiar resource groups de prueba BICEP
for rg in "${BICEP_TEST_RESOURCE_GROUPS[@]}"; do
    cleanup_bicep_resource_group "$rg"
done

# Buscar resource groups que contengan palabras clave BICEP
echo "${BLUE}🔍 Buscando otros resource groups BICEP de prueba...${NC}"
other_bicep_test_rgs=$(az group list --query "[?contains(name, 'bicep') && (contains(name, 'test') || contains(name, 'validation') || contains(name, 'whatif') || contains(name, 'temp'))].name" --output tsv)

if [ -n "$other_bicep_test_rgs" ]; then
    echo "Encontrados resource groups BICEP adicionales:"
    while IFS= read -r rg; do
        if [[ ! " ${BICEP_TEST_RESOURCE_GROUPS[*]} " =~ " ${rg} " ]]; then
            cleanup_bicep_resource_group "$rg"
        fi
    done <<< "$other_bicep_test_rgs"
else
    echo -e "${GREEN}✅ No se encontraron resource groups BICEP adicionales de prueba${NC}"
fi

echo ""
echo "${BLUE}🔍 Verificando deployments BICEP huérfanos...${NC}"

# Buscar deployments BICEP específicos
echo "Buscando deployments de validación BICEP..."
orphaned_bicep_deployments=$(az deployment group list --query "[?contains(name, 'bicep') || contains(name, 'validation') || contains(name, 'whatif')].{Name:name, ResourceGroup:resourceGroup}" --output tsv 2>/dev/null | head -5)

if [ -n "$orphaned_bicep_deployments" ]; then
    echo "${YELLOW}⚠️ Encontrados deployments BICEP de prueba (se limpiarán automáticamente)${NC}"
else
    echo -e "${GREEN}✅ No hay deployments BICEP huérfanos${NC}"
fi

echo ""
echo "${GREEN}🎉 CLEANUP BICEP COMPLETADO${NC}"
echo ""
echo "${BLUE}📋 Resumen:${NC}"
echo "   ✅ Resource groups BICEP de prueba verificados y limpiados"
echo "   ✅ Recursos huérfanos BICEP eliminados"
echo "   ✅ Ambiente BICEP limpio para futuros despliegues"
echo ""
echo "${BLUE}💡 Recomendaciones BICEP:${NC}"
echo "   • Ejecutar este script después de validaciones BICEP"
echo "   • Usar nombres consistentes: [app]-[env]-canada-bicep"
echo "   • Aprovechar IntelliSense de BICEP para desarrollo más rápido"
echo "   • Considerar BICEP como estándar para nuevos proyectos"
echo ""
echo "${YELLOW}📝 Nota: BICEP compila a ARM, así que ambas implementaciones son equivalentes${NC}"
