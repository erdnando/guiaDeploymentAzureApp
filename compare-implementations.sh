#!/bin/bash

# ============================================================================
# SCRIPT DE COMPARACIÓN DE IMPLEMENTACIONES
# Despliega las 4 implementaciones en Resource Groups separados
# ============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║               COMPARACIÓN DE IMPLEMENTACIONES IaC             ║${NC}"
echo -e "${BLUE}║            CLI vs ARM vs Bicep vs Terraform                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}🎯 OBJETIVO:${NC}"
echo "Desplegar la misma infraestructura con 4 tecnologías diferentes"
echo "para validar que generan recursos idénticos en Azure"

echo -e "\n${YELLOW}📋 RESOURCE GROUPS QUE SE CREARÁN:${NC}"
echo "• rg-PaymentSystem-dev-cli        (Azure CLI)"
echo "• rg-paymentapp-arm-dev          (ARM Templates)"
echo "• rg-paymentapp-bicep-dev        (Bicep)"
echo "• rg-PaymentSystem-terraform-dev (Terraform)"

echo -e "\n${YELLOW}🏗️ INFRAESTRUCTURA A DESPLEGAR:${NC}"
echo "• VNet: 10.0.0.0/16"
echo "• App Gateway Subnet: 10.0.1.0/24"
echo "• Container Apps Subnet: 10.0.2.0/24"
echo "• Database Subnet: 10.0.3.0/24"
echo "• PostgreSQL 14 (Standard_B1ms, 32GB)"
echo "• Container Apps Environment"
echo "• Log Analytics Workspace"
echo "• Application Gateway"

echo -e "\n${BLUE}¿Deseas continuar con el despliegue comparativo? (y/N)${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Operación cancelada"
    exit 0
fi

# Función para mostrar progreso
show_progress() {
    local tech=$1
    local step=$2
    echo -e "\n${PURPLE}[$tech]${NC} $step"
}

# Función para manejar errores
handle_error() {
    local tech=$1
    local error=$2
    echo -e "\n${RED}❌ ERROR en $tech: $error${NC}"
}

echo -e "\n${GREEN}🚀 INICIANDO DESPLIEGUES PARALELOS...${NC}"

# =============================================================================
# 1. AZURE CLI DEPLOYMENT
# =============================================================================
show_progress "CLI" "Iniciando despliegue con Azure CLI..."
(
    cd azure-cli-scripts
    echo "Cargando variables de entorno CLI..."
    source parameters/dev.env
    
    echo "Ejecutando scripts CLI en secuencia..."
    ./scripts/01-setup-environment.sh
    ./scripts/02-create-networking.sh
    ./scripts/03-create-database.sh
    ./scripts/04-create-container-env.sh
    ./scripts/05-create-monitoring.sh
    
    echo -e "${GREEN}✅ CLI deployment completado${NC}"
) &
CLI_PID=$!

# =============================================================================
# 2. ARM TEMPLATES DEPLOYMENT
# =============================================================================
show_progress "ARM" "Iniciando despliegue con ARM Templates..."
(
    cd azure-arm-deployment
    echo "Ejecutando despliegue ARM..."
    ./scripts/deploy.sh dev
    
    echo -e "${GREEN}✅ ARM deployment completado${NC}"
) &
ARM_PID=$!

# =============================================================================
# 3. BICEP DEPLOYMENT
# =============================================================================
show_progress "BICEP" "Iniciando despliegue con Bicep..."
(
    cd azure-bicep-deployment
    echo "Ejecutando despliegue Bicep..."
    ./scripts/deploy-dev.sh
    
    echo -e "${GREEN}✅ Bicep deployment completado${NC}"
) &
BICEP_PID=$!

# =============================================================================
# 4. TERRAFORM DEPLOYMENT
# =============================================================================
show_progress "TERRAFORM" "Iniciando despliegue con Terraform..."
(
    cd azure-terraform-deployment
    echo "Ejecutando despliegue Terraform..."
    terraform init
    terraform plan -var-file="environments/dev/terraform.tfvars"
    terraform apply -var-file="environments/dev/terraform.tfvars" -auto-approve
    
    echo -e "${GREEN}✅ Terraform deployment completado${NC}"
) &
TERRAFORM_PID=$!

# Esperar a que todos los deployments terminen
echo -e "\n${YELLOW}⏳ Esperando a que todos los despliegues terminen...${NC}"

wait $CLI_PID
CLI_RESULT=$?

wait $ARM_PID
ARM_RESULT=$?

wait $BICEP_PID
BICEP_RESULT=$?

wait $TERRAFORM_PID
TERRAFORM_RESULT=$?

# =============================================================================
# REPORTE DE RESULTADOS
# =============================================================================
echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                     REPORTE DE RESULTADOS                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${YELLOW}📊 ESTADO DE DESPLIEGUES:${NC}"

if [ $CLI_RESULT -eq 0 ]; then
    echo -e "• CLI:        ${GREEN}✅ EXITOSO${NC}"
else
    echo -e "• CLI:        ${RED}❌ FALLÓ${NC}"
fi

if [ $ARM_RESULT -eq 0 ]; then
    echo -e "• ARM:        ${GREEN}✅ EXITOSO${NC}"
else
    echo -e "• ARM:        ${RED}❌ FALLÓ${NC}"
fi

if [ $BICEP_RESULT -eq 0 ]; then
    echo -e "• Bicep:      ${GREEN}✅ EXITOSO${NC}"
else
    echo -e "• Bicep:      ${RED}❌ FALLÓ${NC}"
fi

if [ $TERRAFORM_RESULT -eq 0 ]; then
    echo -e "• Terraform:  ${GREEN}✅ EXITOSO${NC}"
else
    echo -e "• Terraform:  ${RED}❌ FALLÓ${NC}"
fi

echo -e "\n${YELLOW}🔍 VERIFICACIÓN MANUAL:${NC}"
echo "Usa Azure Portal para comparar los Resource Groups:"
echo "1. Navega a: https://portal.azure.com/#view/HubsExtension/BrowseResourceGroups"
echo "2. Filtra por: rg-*-dev-*"
echo "3. Compara recursos en cada RG para validar consistencia"

echo -e "\n${YELLOW}🧹 LIMPIEZA (OPCIONAL):${NC}"
echo "Para limpiar todos los recursos:"
echo "./cleanup-comparison.sh"

echo -e "\n${GREEN}🎉 Comparación completada!${NC}"
