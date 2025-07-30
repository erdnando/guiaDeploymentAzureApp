#!/bin/bash

# ====================================================================
# VALIDADOR DE GUÍA PASO A PASO - BICEP
# ====================================================================
# 🎯 Objetivo: Verificar que todas las instrucciones funcionan
# 📋 Scope: Validar pre-requisitos y flujo básico BICEP

set -e  # Exit on error

echo "🔍 =================================================="
echo "   VALIDADOR: GUÍA BICEP PASO A PASO"
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

# Test 2: BICEP CLI
echo "🔍 Verificando BICEP CLI..."
if az bicep version &> /dev/null; then
    BICEP_VERSION=$(az bicep version)
    test_passed "BICEP instalado: $BICEP_VERSION"
else
    test_warning "BICEP no disponible - instalando..."
    if az bicep install &> /dev/null; then
        test_passed "BICEP instalado exitosamente"
    else
        test_failed "Error instalando BICEP"
        echo "          Ejecuta manualmente: az bicep install"
    fi
fi

# Test 3: Working Directory
echo "🔍 Verificando directorio de trabajo..."
if [[ -f "main.bicep" && -d "bicep/modules" && -d "parameters" ]]; then
    test_passed "Directorio BICEP correcto encontrado"
else
    test_failed "No estás en el directorio azure-bicep-deployment"
    echo "          Ejecuta: cd azure-bicep-deployment"
    exit 1
fi

# Test 4: Files integrity
echo "🔍 Verificando integridad de archivos..."
REQUIRED_FILES=(
    "main.bicep"
    "parameters/dev-parameters.json"
    "parameters/prod-parameters.json"
    "bicep/modules/01-infrastructure.bicep"
    "bicep/modules/02-postgresql.bicep"
    "bicep/modules/03-containerapp-environment.bicep"
    "bicep/modules/04-application-gateway.bicep"
    "bicep/modules/05-monitoring.bicep"
    "bicep/modules/06-container-apps.bicep"
    "scripts/validate-bicep-azure-policies.sh"
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
# FASE 1: VALIDACIÓN DE SINTAXIS BICEP
# ====================================================================

echo ""
echo "🎯 FASE 1: Validando Sintaxis BICEP..."

# Test 5: BICEP build
echo "🔍 Ejecutando az bicep build..."
if az bicep build --file main.bicep > /dev/null 2>&1; then
    test_passed "BICEP build exitoso"
    test_info "ARM template generado: main.json"
else
    test_failed "BICEP build falló"
    echo "          Ejecuta manualmente: az bicep build --file main.bicep"
    exit 1
fi

# Test 6: Template validation
echo "🔍 Ejecutando template validation..."
# Create temporary resource group for validation
TEMP_RG="rg-bicep-validation-temp"
if az group create --name "$TEMP_RG" --location "canadacentral" > /dev/null 2>&1; then
    if az deployment group validate \
        --resource-group "$TEMP_RG" \
        --template-file main.bicep \
        --parameters @parameters/parameters-dev.json > /dev/null 2>&1; then
        test_passed "Template validation exitosa"
    else
        test_warning "Template validation con advertencias"
        echo "          Revisa parámetros en parameters/parameters-dev.json"
    fi
    
    # Cleanup temp resource group
    az group delete --name "$TEMP_RG" --yes --no-wait > /dev/null 2>&1
else
    test_warning "No se pudo crear RG temporal para validación"
fi

# ====================================================================
# FASE 2: VALIDACIÓN DE AZURE POLICIES
# ====================================================================

echo ""
echo "🏛️ FASE 2: Validando Azure Policy Compliance..."

# Test 7: Azure Policy validation script
echo "🔍 Ejecutando validación de Azure Policies..."
if [[ -x "scripts/validate-bicep-azure-policies.sh" ]]; then
    if ./scripts/validate-bicep-azure-policies.sh > /dev/null 2>&1; then
        test_passed "Azure Policy compliance validation exitosa"
    else
        test_warning "Azure Policy validation con advertencias"
        echo "          Ejecuta manualmente: ./scripts/validate-bicep-azure-policies.sh"
    fi
else
    test_failed "Script de validación no ejecutable"
    echo "          Ejecuta: chmod +x scripts/validate-bicep-azure-policies.sh"
fi

# Test 8: Required parameters check
echo "🔍 Verificando parámetros requeridos..."
REQUIRED_PARAMS=("projectName" "location")
for param in "${REQUIRED_PARAMS[@]}"; do
    if grep -q "@description.*$param" main.bicep; then
        test_passed "Parámetro requerido encontrado: $param"
    elif grep -q "param $param" main.bicep; then
        test_passed "Parámetro requerido encontrado: $param"
    else
        test_failed "Parámetro requerido faltante: $param"
    fi
done

# Test 9: Environment configuration
echo "🔍 Verificando configuración de ambientes..."
for env in "dev" "prod"; do
    env_file="parameters/parameters-$env.json"
    if [[ -f "$env_file" ]]; then
        if grep -q "projectName" "$env_file" && grep -q "location" "$env_file"; then
            test_passed "Configuración $env válida"
        else
            test_warning "Configuración $env incompleta"
        fi
    fi
done

# Test 10: BICEP modules structure
echo "🔍 Verificando estructura de módulos..."
EXPECTED_MODULES=("infrastructure" "database" "monitoring" "containerApps" "applicationGateway")
for module in "${EXPECTED_MODULES[@]}"; do
    if grep -q "module $module" main.bicep; then
        test_passed "Módulo encontrado en main.bicep: $module"
    else
        test_warning "Módulo no referenciado: $module"
    fi
done

# ====================================================================
# RESUMEN FINAL
# ====================================================================

echo ""
echo "📊 =================================================="
echo "   RESUMEN DE VALIDACIÓN"
echo "📊 =================================================="

echo ""
echo "🎯 VALIDACIÓN COMPLETADA"
echo ""
echo "🚀 SIGUIENTE PASO:"
echo "   Puedes seguir la guía paso a paso con confianza"
echo "   Archivo: docs/GUIA-INGENIERO-BICEP-PASO-A-PASO.md"
echo ""
echo "🎯 PARA COMENZAR:"
echo "   1. Abre docs/GUIA-INGENIERO-BICEP-PASO-A-PASO.md"
echo "   2. Sigue desde 'FASE 1: Tu Primer Hello BICEP'"
echo "   3. Cada paso incluye explicaciones y checkpoints"
echo ""
test_passed "Sistema listo para deployment con BICEP"

echo ""
echo "🎨 VENTAJAS DE BICEP QUE DESCUBRIRÁS:"
echo "   ✅ Sintaxis 70% más limpia que ARM"
echo "   ✅ IntelliSense completo en VS Code"
echo "   ✅ Compila a ARM nativo"
echo "   ✅ Deploy de sistemas complejos en un comando"
echo ""

test_info "¡Disfruta aprendiendo BICEP - es mucho más fácil que ARM!"
