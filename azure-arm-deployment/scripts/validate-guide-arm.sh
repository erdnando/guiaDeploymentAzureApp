#!/bin/bash

# 🎯 Script de Validación ARM Templates - Payment System
# Valida prerequisites y estructura antes de seguir la guía paso a paso

set -e

echo "🔍 ARM TEMPLATES VALIDATION - Payment System"
echo "============================================="
echo ""

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar éxito
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Función para mostrar warning
warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Función para mostrar error
error() {
    echo -e "${RED}❌ $1${NC}"
}

# Función para mostrar info
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Función para verificar comando
check_command() {
    if command -v "$1" &> /dev/null; then
        success "$1 está instalado"
        return 0
    else
        error "$1 no está instalado"
        return 1
    fi
}

echo "🧪 VERIFICANDO PREREQUISITES..."
echo "==============================="

# 1. Verificar Azure CLI
if check_command "az"; then
    az_version=$(az --version | head -1 | grep -o '[0-9]*\.[0-9]*\.[0-9]*')
    info "Azure CLI versión: $az_version"
else
    error "Azure CLI es requerido. Instalar: https://docs.microsoft.com/cli/azure/install-azure-cli"
    exit 1
fi

# 2. Verificar jq (para JSON parsing)
if check_command "jq"; then
    jq_version=$(jq --version)
    info "$jq_version"
else
    warning "jq no está instalado (opcional pero recomendado para parsing JSON)"
    info "Instalar: sudo apt-get install jq (Ubuntu) o brew install jq (macOS)"
fi

# 3. Verificar curl
if check_command "curl"; then
    curl_version=$(curl --version | head -1)
    info "$curl_version"
else
    error "curl es requerido para testing de endpoints"
    exit 1
fi

echo ""
echo "🔑 VERIFICANDO AZURE ACCESS..."
echo "=============================="

# Verificar login Azure
if az account show &> /dev/null; then
    account_name=$(az account show --query name --output tsv)
    subscription_id=$(az account show --query id --output tsv)
    success "Logueado en Azure"
    info "Cuenta: $account_name"
    info "Subscription: $subscription_id"
else
    error "No estás logueado en Azure"
    info "Ejecutar: az login"
    exit 1
fi

# Verificar permisos mínimos
echo ""
info "Verificando permisos de suscripción..."

# Verificar si puede listar resource groups
if az group list --query '[0].name' &> /dev/null; then
    success "Permisos de lectura confirmados"
else
    error "Sin permisos de lectura en la suscripción"
    exit 1
fi

# Verificar location permitida (canadacentral)
locations=$(az account list-locations --query '[].name' --output tsv)
if echo "$locations" | grep -q "canadacentral"; then
    success "Ubicación 'canadacentral' disponible"
else
    warning "Ubicación 'canadacentral' no encontrada en suscripción"
    info "Ubicaciones disponibles: $(echo $locations | tr '\n' ', ')"
fi

echo ""
echo "📁 VERIFICANDO ESTRUCTURA DEL PROYECTO..."
echo "========================================="

# Verificar que estamos en el directorio correcto
if [ -f "README.md" ] && [ -d "templates" ] && [ -d "parameters" ]; then
    success "Estructura de proyecto ARM correcta"
else
    error "No estás en el directorio azure-arm-deployment correcto"
    info "Navegar a: cd azure-arm-deployment/"
    exit 1
fi

# Verificar templates principales
required_templates=(
    "templates/main.json"
    "templates/01-infrastructure.json"
    "templates/02-postgresql.json"
    "templates/03-containerapp-environment.json"
    "templates/04-application-gateway.json"
    "templates/05-monitoring.json"
    "templates/06-container-apps.json"
)

missing_templates=()
for template in "${required_templates[@]}"; do
    if [ -f "$template" ]; then
        success "Template encontrado: $template"
    else
        error "Template faltante: $template"
        missing_templates+=("$template")
    fi
done

if [ ${#missing_templates[@]} -gt 0 ]; then
    error "Templates faltantes detectados"
    exit 1
fi

# Verificar parámetros
required_params=(
    "parameters/dev-parameters.json"
)

for param in "${required_params[@]}"; do
    if [ -f "$param" ]; then
        success "Parámetros encontrados: $param"
        # Validar JSON
        if jq empty "$param" 2>/dev/null; then
            success "JSON válido: $param"
        else
            error "JSON inválido: $param"
            exit 1
        fi
    else
        error "Parámetros faltantes: $param"
        exit 1
    fi
done

echo ""
echo "🧪 VALIDANDO TEMPLATES ARM..."
echo "============================="

# Validar template principal
info "Validando template principal..."
if jq empty templates/main.json 2>/dev/null; then
    success "main.json es JSON válido"
else
    error "main.json contiene errores de sintaxis JSON"
    exit 1
fi

# Verificar esquemas ARM
schema_url="https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
main_schema=$(jq -r '."$schema"' templates/main.json)

if [ "$main_schema" = "$schema_url" ] || [[ "$main_schema" == *"deploymentTemplate.json"* ]]; then
    success "Schema ARM válido en main.json"
else
    warning "Schema ARM no estándar en main.json: $main_schema"
fi

# Verificar secciones requeridas en main template
required_sections=("parameters" "variables" "resources" "outputs")
for section in "${required_sections[@]}"; do
    if jq -e ".$section" templates/main.json &> /dev/null; then
        success "Sección '$section' encontrada en main.json"
    else
        error "Sección '$section' faltante en main.json"
        exit 1
    fi
done

echo ""
echo "⚙️  CONFIGURANDO VARIABLES DE ENTORNO..."
echo "========================================"

# Configurar variables para la guía
export PROJECT_NAME="PaymentSystem"
export ENVIRONMENT="dev"
export LOCATION="canadacentral"
export RESOURCE_GROUP="rg-${PROJECT_NAME}-${ENVIRONMENT}"

success "Variables configuradas:"
info "PROJECT_NAME=$PROJECT_NAME"
info "ENVIRONMENT=$ENVIRONMENT"
info "LOCATION=$LOCATION"
info "RESOURCE_GROUP=$RESOURCE_GROUP"

echo ""
info "Para usar estas variables en tu sesión, ejecuta:"
echo "export PROJECT_NAME=\"$PROJECT_NAME\""
echo "export ENVIRONMENT=\"$ENVIRONMENT\""
echo "export LOCATION=\"$LOCATION\""
echo "export RESOURCE_GROUP=\"$RESOURCE_GROUP\""

echo ""
echo "🎯 RECOMENDACIONES PARA LA GUÍA..."
echo "================================="

success "¡Todo listo para empezar con ARM Templates!"
echo ""
info "Próximos pasos recomendados:"
echo "1. 🎓 Abrir: docs/GUIA-INGENIERO-ARM-PASO-A-PASO.md"
echo "2. 🚀 Seguir FASE 0: Setup y Preparación"
echo "3. 📚 Completar todas las fases (0-7)"
echo ""
info "Alternativamente:"
echo "• ⚡ Para deploy rápido: docs/deployment-guide.md"
echo "• 📖 Para referencia: docs/QUICK-REFERENCE-ARM.md"
echo "• 🏗️ Para arquitectura: docs/architecture.md"

echo ""
echo "📚 DOCUMENTACIÓN DISPONIBLE:"
echo "==========================="
echo "• docs/GUIA-INGENIERO-ARM-PASO-A-PASO.md (principiantes)"
echo "• docs/QUICK-REFERENCE-ARM.md (desarrolladores)"
echo "• docs/plantillas_arm_azure.md (documentación técnica)"
echo "• docs/deployment-guide.md (deploy simplificado)"
echo "• docs/architecture.md (diseño del sistema)"
echo "• docs/INDEX.md (navegación completa)"

echo ""
success "🎉 Validación completada exitosamente!"
info "Tiempo estimado para completar la guía: 2-4 horas"
info "¡Happy ARM Templates coding! 🚀"
