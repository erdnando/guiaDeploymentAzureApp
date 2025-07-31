#!/bin/bash

# ============================================================================
# CLEANUP SCRIPT - Eliminar todos los Resource Groups de comparación
# ============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    LIMPIEZA DE COMPARACIÓN                    ║${NC}"
echo -e "${BLUE}║               Eliminar todos los Resource Groups              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}⚠️  ADVERTENCIA:${NC}"
echo "Este script eliminará TODOS los Resource Groups de la comparación:"
echo "• rg-PaymentSystem-dev-cli"
echo "• rg-paymentapp-arm-dev"
echo "• rg-paymentapp-bicep-dev"
echo "• rg-PaymentSystem-terraform-dev"

echo -e "\n${RED}⚠️  ESTA ACCIÓN NO SE PUEDE DESHACER${NC}"
echo -e "\n${BLUE}¿Estás seguro que deseas continuar? (y/N)${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Operación cancelada"
    exit 0
fi

echo -e "\n${YELLOW}🧹 Iniciando limpieza...${NC}"

# Array de Resource Groups
RG_NAMES=(
    "rg-PaymentSystem-dev-cli"
    "rg-paymentapp-arm-dev"
    "rg-paymentapp-bicep-dev"
    "rg-PaymentSystem-terraform-dev"
)

# Función para eliminar RG
delete_rg() {
    local rg_name=$1
    echo -e "\n${YELLOW}🗑️  Eliminando: $rg_name${NC}"
    
    # Verificar si existe
    if az group show --name "$rg_name" >/dev/null 2>&1; then
        echo "Resource Group encontrado, eliminando..."
        az group delete --name "$rg_name" --yes --no-wait
        echo -e "${GREEN}✅ Eliminación iniciada para: $rg_name${NC}"
    else
        echo -e "${YELLOW}⚠️  Resource Group no encontrado: $rg_name${NC}"
    fi
}

# Eliminar todos los Resource Groups
for rg in "${RG_NAMES[@]}"; do
    delete_rg "$rg"
done

echo -e "\n${YELLOW}⏳ Las eliminaciones están en progreso (modo asíncrono)${NC}"
echo "Esto puede tomar varios minutos..."

echo -e "\n${BLUE}💡 Para verificar el progreso:${NC}"
echo "az group list --query \"[?starts_with(name, 'rg-')].{Name:name, State:properties.provisioningState}\" --output table"

echo -e "\n${GREEN}🎉 Limpieza iniciada!${NC}"
echo "Los Resource Groups se eliminarán en segundo plano."
