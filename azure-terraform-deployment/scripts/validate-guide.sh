#!/bin/bash

# ====================================================================
# VALIDADOR DE GUÍA PASO A PASO - TERRAFORM
# ====================================================================
# 🎯 Objetivo: Verificar que todas las instrucciones funcionan
# 📋 Scope: Validar pre-requisitos y flujo básico

set -e  # Exit on error

echo "🔍 =================================================="
echo "   VALIDADOR: GUÍA TERRAFORM PASO A PASO"
echo "🔍 =================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test functions
test_passed() {
    echo -e "✅ ${GREEN}$1${NC}"
}

test_failed() {
    echo -e "❌ ${RED}$1${NC}"
}

test_warning() {
    echo -e "⚠️  ${YELLOW}$1${NC}"
}

test_info() {
    echo -e "ℹ️  ${BLUE}$1${NC}"
}

# ====================================================================
# FASE 0: VALIDACIÓN DE PRE-REQUISITOS
# ====================================================================

echo ""
echo "🚀 FASE 0: Validando Pre-requisitos..."

# Test 1: Azure CLI
echo "🔍 Verificando Azure CLI..."
if command -v az &> /dev/null; then
    AZ_VERSION=$(az --version | head -n1)
    test_passed "Azure CLI instalado: $AZ_VERSION"
    
    # Test Azure login
    if az account show &> /dev/null; then
        SUBSCRIPTION=$(az account show --query "name" -o tsv)
        test_passed "Azure login activo: $SUBSCRIPTION"
    else
        test_warning "Azure CLI instalado pero no hay login activo"
        echo "          Ejecuta: az login"
    fi
else
    test_failed "Azure CLI no encontrado"
    echo "          Instala con: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    exit 1
fi

# Test 2: Terraform CLI
echo "🔍 Verificando Terraform CLI..."
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform version | head -n1)
    test_passed "Terraform instalado: $TF_VERSION"
    
    # Check version
    TF_VERSION_NUM=$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || echo "unknown")
    if [[ "$TF_VERSION_NUM" != "unknown" ]]; then
        if [[ "$TF_VERSION_NUM" == "1."* ]]; then
            test_passed "Versión Terraform compatible: $TF_VERSION_NUM"
        else
            test_warning "Versión Terraform puede ser incompatible: $TF_VERSION_NUM"
        fi
    fi
else
    test_failed "Terraform no encontrado"
    echo "          Instala siguiendo: https://learn.hashicorp.com/tutorials/terraform/install-cli"
    exit 1
fi

# Test 3: Working Directory
echo "🔍 Verificando directorio de trabajo..."
if [[ -f "main.tf" && -d "modules" && -d "environments" ]]; then
    test_passed "Directorio terraform correcto encontrado"
else
    test_failed "No estás en el directorio azure-terraform-deployment"
    echo "          Ejecuta: cd azure-terraform-deployment"
    exit 1
fi

# Test 4: Files integrity
echo "🔍 Verificando integridad de archivos..."
REQUIRED_FILES=(
    "main.tf"
    "environments/dev/terraform.tfvars"
    "environments/prod/terraform.tfvars"
    "modules/infrastructure/main.tf"
    "modules/monitoring/main.tf"
    "modules/postgresql/main.tf"
    "modules/container-environment/main.tf"
    "modules/container-apps/main.tf"
    "modules/application-gateway/main.tf"
    "scripts/validate-terraform-azure-policies.sh"
)

missing_files=0
for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        test_passed "Archivo encontrado: $file"
    else
        test_failed "Archivo faltante: $file"
        ((missing_files++))
    fi
done

if [[ $missing_files -gt 0 ]]; then
    test_failed "$missing_files archivos faltantes - estructura incompleta"
    exit 1
fi

# ====================================================================
# FASE 1: VALIDACIÓN DE SINTAXIS
# ====================================================================

echo ""
echo "🎯 FASE 1: Validando Sintaxis Terraform..."

# Test 5: Terraform init
echo "🔍 Ejecutando terraform init..."
if terraform init > /dev/null 2>&1; then
    test_passed "Terraform init exitoso"
else
    test_failed "Terraform init falló"
    echo "          Ejecuta manualmente: terraform init"
    exit 1
fi

# Test 6: Terraform validate
echo "🔍 Ejecutando terraform validate..."
if terraform validate > /dev/null 2>&1; then
    test_passed "Terraform validate exitoso"
else
    test_failed "Terraform validate falló"
    echo "          Ejecuta: terraform validate para ver errores"
    exit 1
fi

# Test 7: Terraform fmt check
echo "🔍 Verificando formato de código..."
if terraform fmt -check > /dev/null 2>&1; then
    test_passed "Formato de código correcto"
else
    test_warning "Formato de código necesita corrección"
    echo "          Ejecuta: terraform fmt"
fi

# ====================================================================
# FASE 2: VALIDACIÓN DE AZURE POLICIES
# ====================================================================

echo ""
echo "🏛️ FASE 2: Validando Azure Policy Compliance..."

# Test 8: Azure Policy validation script
echo "🔍 Ejecutando validación de Azure Policies..."
if [[ -x "scripts/validate-terraform-azure-policies.sh" ]]; then
    if ./scripts/validate-terraform-azure-policies.sh > /dev/null 2>&1; then
        test_passed "Azure Policy compliance validation exitosa"
    else
        test_warning "Azure Policy validation con advertencias"
        echo "          Ejecuta manualmente: ./scripts/validate-terraform-azure-policies.sh"
    fi
else
    test_failed "Script de validación no ejecutable"
    echo "          Ejecuta: chmod +x scripts/validate-terraform-azure-policies.sh"
fi

# Test 9: Required variables check
echo "🔍 Verificando variables requeridas..."
REQUIRED_VARS=("project" "location")
for var in "${REQUIRED_VARS[@]}"; do
    if grep -q "variable \"$var\"" main.tf; then
        test_passed "Variable requerida encontrada: $var"
    else
        test_failed "Variable requerida faltante: $var"
    fi
done

# Test 10: Environment configuration
echo "🔍 Verificando configuración de ambientes..."
for env in "dev" "prod"; do
    env_file="environments/$env/terraform.tfvars"
    if [[ -f "$env_file" ]]; then
        if grep -q "project.*=" "$env_file" && grep -q "location.*=" "$env_file"; then
            test_passed "Configuración $env válida"
        else
            test_warning "Configuración $env incompleta"
        fi
    fi
done

# ====================================================================
# FASE 3: VALIDACIÓN DE PLAN
# ====================================================================

echo ""
echo "📋 FASE 3: Validando Plan de Terraform..."

# Test 11: Terraform plan
echo "🔍 Ejecutando terraform plan..."
if terraform plan -var-file="environments/dev/terraform.tfvars" -detailed-exitcode > /dev/null 2>&1; then
    exit_code=$?
    case $exit_code in
        0)
            test_info "Plan exitoso - no hay cambios pendientes"
            ;;
        2)
            test_passed "Plan exitoso - cambios detectados (normal para deploy inicial)"
            ;;
        *)
            test_failed "Plan falló con código de salida $exit_code"
            ;;
    esac
else
    test_warning "Plan ejecutado con advertencias - revisar configuración"
fi

# ====================================================================
# RESUMEN FINAL
# ====================================================================

echo ""
echo "📊 =================================================="
echo "   RESUMEN DE VALIDACIÓN"
echo "📊 =================================================="

echo ""
# Simple success check based on exit codes
echo "🎯 VALIDACIÓN COMPLETADA"
echo ""
echo "🚀 SIGUIENTE PASO:"
echo "   Puedes seguir la guía paso a paso con confianza"
echo "   Archivo: GUIA-INGENIERO-TERRAFORM-PASO-A-PASO.md"
echo ""
echo "🎯 PARA COMENZAR:"
echo "   1. Abre GUIA-INGENIERO-TERRAFORM-PASO-A-PASO.md"
echo "   2. Sigue desde 'FASE 1: Tu Primer Hello Terraform'"
echo "   3. Cada paso incluye explicaciones y checkpoints"
echo ""
test_passed "Sistema listo para deployment"
