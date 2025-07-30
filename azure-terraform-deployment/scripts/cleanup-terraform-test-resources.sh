#!/bin/bash

# 🧹 TERRAFORM CLEANUP SCRIPT - Azure Resources
# Limpia recursos de prueba Terraform para evitar costos

echo "🧹 CLEANUP DE RECURSOS TERRAFORM"
echo "================================"
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
TERRAFORM_DIR="/home/erdnando/proyectos/azure/GuiaAzureApp/azure-terraform-deployment"

# Resource groups de prueba Terraform
TERRAFORM_TEST_RESOURCE_GROUPS=(
    "rg-paymentapp-dev-canada-tf"
    "rg-paymentapp-test-canada-tf"
    "rg-paymentapp-prod-canada-tf"
    "rg-terraform-validation-test"
    "rg-terraform-whatif-test"
)

echo "${BLUE}🔍 Buscando resource groups de prueba Terraform...${NC}"
echo ""

# Función para verificar y eliminar resource group
cleanup_terraform_resource_group() {
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
            echo -n "   ${RED}⚠️ ¿Eliminar este resource group Terraform y sus $resources recursos? (y/N): ${NC}"
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

# Buscar y limpiar resource groups de prueba Terraform
for rg in "${TERRAFORM_TEST_RESOURCE_GROUPS[@]}"; do
    cleanup_terraform_resource_group "$rg"
done

# Buscar resource groups que contengan palabras clave Terraform
echo "${BLUE}🔍 Buscando otros resource groups Terraform de prueba...${NC}"
other_tf_test_rgs=$(az group list --query "[?contains(name, 'tf') && (contains(name, 'test') || contains(name, 'validation') || contains(name, 'temp'))].name" --output tsv)

if [ -n "$other_tf_test_rgs" ]; then
    echo "Encontrados resource groups Terraform adicionales:"
    while IFS= read -r rg; do
        if [[ ! " ${TERRAFORM_TEST_RESOURCE_GROUPS[*]} " =~ " ${rg} " ]]; then
            cleanup_terraform_resource_group "$rg"
        fi
    done <<< "$other_tf_test_rgs"
else
    echo -e "${GREEN}✅ No se encontraron resource groups Terraform adicionales de prueba${NC}"
fi

echo ""
echo "${BLUE}🔍 Verificando estado de Terraform...${NC}"

# Cambiar al directorio de Terraform
cd "$TERRAFORM_DIR" || {
    echo "${RED}❌ No se pudo acceder al directorio de Terraform${NC}"
    exit 1
}

# Verificar si hay estado de Terraform
if [ -f "terraform.tfstate" ]; then
    echo "${YELLOW}⚠️ Encontrado archivo terraform.tfstate${NC}"
    echo -n "   ${RED}¿Eliminar estado de Terraform? (y/N): ${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "   🗑️ Eliminando archivos de estado..."
        rm -f terraform.tfstate*
        rm -f .terraform.lock.hcl
        rm -rf .terraform/
        echo -e "   ${GREEN}✅ Estado de Terraform limpiado${NC}"
    else
        echo -e "   ${YELLOW}⏭️ Manteniendo estado de Terraform${NC}"
    fi
else
    echo -e "${GREEN}✅ No hay archivos de estado de Terraform${NC}"
fi

# Verificar archivos de plan
echo "${BLUE}🔍 Buscando archivos de plan de Terraform...${NC}"
PLAN_FILES=$(find . -name "*.tfplan" -type f 2>/dev/null)
if [ -n "$PLAN_FILES" ]; then
    echo "${YELLOW}⚠️ Encontrados archivos de plan:${NC}"
    echo "$PLAN_FILES"
    echo -n "   ${RED}¿Eliminar archivos de plan? (y/N): ${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        find . -name "*.tfplan" -type f -delete
        echo -e "   ${GREEN}✅ Archivos de plan eliminados${NC}"
    fi
else
    echo -e "${GREEN}✅ No hay archivos de plan de Terraform${NC}"
fi

# Verificar archivos de output
echo "${BLUE}🔍 Buscando archivos de output...${NC}"
OUTPUT_FILES=$(find . -name "*-outputs.json" -type f 2>/dev/null)
if [ -n "$OUTPUT_FILES" ]; then
    echo "${YELLOW}⚠️ Encontrados archivos de output:${NC}"
    echo "$OUTPUT_FILES"
    echo -n "   ${RED}¿Eliminar archivos de output? (y/N): ${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        find . -name "*-outputs.json" -type f -delete
        echo -e "   ${GREEN}✅ Archivos de output eliminados${NC}"
    fi
else
    echo -e "${GREEN}✅ No hay archivos de output${NC}"
fi

echo ""
echo "${GREEN}🎉 CLEANUP TERRAFORM COMPLETADO${NC}"
echo ""
echo "${BLUE}📋 Resumen:${NC}"
echo "   ✅ Resource groups Terraform de prueba verificados y limpiados"
echo "   ✅ Estado de Terraform gestionado según preferencia"
echo "   ✅ Archivos temporales limpiados"
echo "   ✅ Ambiente Terraform limpio para futuros despliegues"
echo ""
echo "${BLUE}💡 Recomendaciones Terraform:${NC}"
echo "   • Ejecutar este script después de validaciones y pruebas"
echo "   • Usar remote state (Azure Storage) para producción"
echo "   • Implementar Terraform Cloud/Enterprise para colaboración"
echo "   • Versionar archivos .tfvars pero NO archivos .tfstate"
echo ""
echo "${YELLOW}📝 Nota: Terraform maneja infraestructura como código declarativo${NC}"
