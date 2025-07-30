#!/bin/bash

# =============================================================================
# Script de Validación - Azure ARM Templates
# =============================================================================
# Este script valida los templates ARM antes del despliegue

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Cargar variables
echo -e "${BLUE}🔄 Cargando variables de entorno...${NC}"
source "$SCRIPT_DIR/variables.sh"

# Función para log con timestamp
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Función para validar un template
validate_template() {
    local template_number=$1
    local template_name=$2
    local description=$3
    
    log "🔍 Validando Template $template_number: $description"
    
    local template_file="$PROJECT_ROOT/templates/0${template_number}-${template_name}.json"
    local parameters_file="$PROJECT_ROOT/parameters/0${template_number}-${template_name}.${ENVIRONMENT}.json"
    
    # Verificar que los archivos existan
    if [ ! -f "$template_file" ]; then
        error "   ❌ Template file no encontrado: $template_file"
        return 1
    fi
    
    if [ ! -f "$parameters_file" ]; then
        error "   ❌ Parameters file no encontrado: $parameters_file"
        return 1
    fi
    
    # Validar sintaxis JSON del template
    if ! jq empty "$template_file" 2>/dev/null; then
        error "   ❌ Template tiene sintaxis JSON inválida"
        return 1
    fi
    
    # Validar sintaxis JSON de los parámetros
    if ! jq empty "$parameters_file" 2>/dev/null; then
        error "   ❌ Parameters file tiene sintaxis JSON inválida"
        return 1
    fi
    
    # Validar template con Azure CLI
    log "   🔍 Validando template con Azure CLI..."
    if az deployment group validate \
        --resource-group "$RESOURCE_GROUP" \
        --template-file "$template_file" \
        --parameters "@$parameters_file" \
        --output none 2>/dev/null; then
        log "   ✅ Template válido"
        return 0
    else
        error "   ❌ Template falló validación de Azure"
        
        # Mostrar detalles del error
        log "   📋 Detalles del error:"
        az deployment group validate \
            --resource-group "$RESOURCE_GROUP" \
            --template-file "$template_file" \
            --parameters "@$parameters_file" \
            --output table
        return 1
    fi
}

# Función para validar prerequisitos
validate_prerequisites() {
    log "🔍 Validando prerequisitos..."
    local errors=0
    
    # Verificar Azure CLI
    if ! command -v az &> /dev/null; then
        error "   ❌ Azure CLI no está instalado"
        errors=$((errors + 1))
    else
        log "   ✅ Azure CLI instalado"
    fi
    
    # Verificar jq para validación JSON
    if ! command -v jq &> /dev/null; then
        error "   ❌ jq no está instalado (necesario para validación JSON)"
        errors=$((errors + 1))
    else
        log "   ✅ jq instalado"
    fi
    
    # Verificar autenticación en Azure
    if ! az account show &> /dev/null; then
        error "   ❌ No estás autenticado en Azure. Ejecuta 'az login'"
        errors=$((errors + 1))
    else
        local account_name=$(az account show --query "name" --output tsv)
        log "   ✅ Autenticado en Azure: $account_name"
    fi
    
    # Verificar que el resource group existe
    if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        warning "   ⚠️  Resource Group '$RESOURCE_GROUP' no existe (se creará durante el despliegue)"
    else
        log "   ✅ Resource Group '$RESOURCE_GROUP' existe"
    fi
    
    return $errors
}

# Función para validar archivos del proyecto
validate_project_files() {
    log "🔍 Validando estructura de archivos del proyecto..."
    local errors=0
    
    # Verificar directorios
    for dir in "templates" "parameters" "scripts" "docs"; do
        if [ ! -d "$PROJECT_ROOT/$dir" ]; then
            error "   ❌ Directorio faltante: $dir"
            errors=$((errors + 1))
        else
            log "   ✅ Directorio encontrado: $dir"
        fi
    done
    
    # Verificar templates
    for i in {1..6}; do
        local template_files=(
            "01:infrastructure"
            "02:postgresql"
            "03:containerenv"
            "04:appgateway"
            "05:monitoring"
            "06:containerapps"
        )
        
        local template_info="${template_files[$((i-1))]}"
        local template_number="${template_info%%:*}"
        local template_name="${template_info##*:}"
        
        local template_file="$PROJECT_ROOT/templates/0${template_number}-${template_name}.json"
        local parameters_file="$PROJECT_ROOT/parameters/0${template_number}-${template_name}.${ENVIRONMENT}.json"
        
        if [ ! -f "$template_file" ]; then
            error "   ❌ Template faltante: 0${template_number}-${template_name}.json"
            errors=$((errors + 1))
        fi
        
        if [ ! -f "$parameters_file" ]; then
            error "   ❌ Parameters faltante: 0${template_number}-${template_name}.${ENVIRONMENT}.json"
            errors=$((errors + 1))
        fi
    done
    
    return $errors
}

# Función para validar configuración de variables
validate_variables() {
    log "🔍 Validando configuración de variables..."
    local errors=0
    
    # Variables requeridas
    local required_vars=(
        "PROJECT_NAME"
        "ENVIRONMENT"
        "RESOURCE_GROUP"
        "LOCATION"
        "POSTGRES_ADMIN_USER"
        "POSTGRES_DB_NAME"
        "REGISTRY_SERVER"
        "REGISTRY_USERNAME"
        "REGISTRY_PASSWORD"
        "BACKEND_IMAGE"
        "FRONTEND_IMAGE"
        "ALERT_EMAIL"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            error "   ❌ Variable requerida no definida: $var"
            errors=$((errors + 1))
        else
            log "   ✅ Variable definida: $var"
        fi
    done
    
    # Validaciones específicas
    if [ "$REGISTRY_USERNAME" = "tu-usuario-github" ]; then
        error "   ❌ Debes cambiar REGISTRY_USERNAME por tu usuario real de GitHub"
        errors=$((errors + 1))
    fi
    
    if [ "$REGISTRY_PASSWORD" = "tu-github-token" ]; then
        error "   ❌ Debes cambiar REGISTRY_PASSWORD por tu token real de GitHub"
        errors=$((errors + 1))
    fi
    
    if [ "$ALERT_EMAIL" = "admin@tuempresa.com" ]; then
        warning "   ⚠️  Considera cambiar ALERT_EMAIL por tu email real"
    fi
    
    return $errors
}

# Banner inicial
echo -e "${BLUE}"
echo "██╗   ██╗ █████╗ ██╗     ██╗██████╗  █████╗ ████████╗██╗ ██████╗ ███╗   ██╗"
echo "██║   ██║██╔══██╗██║     ██║██╔══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║"
echo "██║   ██║███████║██║     ██║██║  ██║███████║   ██║   ██║██║   ██║██╔██╗ ██║"
echo "╚██╗ ██╔╝██╔══██║██║     ██║██║  ██║██╔══██║   ██║   ██║██║   ██║██║╚██╗██║"
echo " ╚████╔╝ ██║  ██║███████╗██║██████╔╝██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║"
echo "  ╚═══╝  ╚═╝  ╚═╝╚══════╝╚═╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝"
echo ""
echo "🔍 Validación de Templates ARM - Sistema de Pagos"
echo "📦 Proyecto: $PROJECT_NAME"
echo "🌍 Entorno: $ENVIRONMENT"
echo -e "${NC}"
echo ""

total_errors=0

# Ejecutar validaciones
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 FASE 1: VALIDACIÓN DE PREREQUISITOS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
validate_prerequisites
total_errors=$((total_errors + $?))

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 FASE 2: VALIDACIÓN DE ARCHIVOS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
validate_project_files
total_errors=$((total_errors + $?))

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 FASE 3: VALIDACIÓN DE VARIABLES${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
validate_variables
total_errors=$((total_errors + $?))

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔍 FASE 4: VALIDACIÓN DE TEMPLATES ARM${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Solo validar templates si no hay errores críticos
if [ $total_errors -eq 0 ]; then
    # Crear resource group temporal para validación si no existe
    if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        log "📁 Creando Resource Group temporal para validación: $RESOURCE_GROUP"
        az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
        resource_group_created=true
    fi
    
    # Validar cada template
    template_errors=0
    validate_template 1 "infrastructure" "Infraestructura Base (VNET, NSG, Subnets)"
    template_errors=$((template_errors + $?))
    
    validate_template 2 "postgresql" "Base de Datos PostgreSQL"
    template_errors=$((template_errors + $?))
    
    validate_template 3 "containerenv" "Entorno de Container Apps"
    template_errors=$((template_errors + $?))
    
    validate_template 4 "appgateway" "Application Gateway con WAF"
    template_errors=$((template_errors + $?))
    
    validate_template 5 "monitoring" "Monitoreo y Alertas"
    template_errors=$((template_errors + $?))
    
    validate_template 6 "containerapps" "Aplicaciones Container Apps"
    template_errors=$((template_errors + $?))
    
    total_errors=$((total_errors + template_errors))
    
    # Limpiar resource group temporal si fue creado
    if [ "$resource_group_created" = true ] && [ $template_errors -eq 0 ]; then
        log "🧹 Eliminando Resource Group temporal"
        az group delete --name "$RESOURCE_GROUP" --yes --no-wait
    fi
else
    warning "⚠️  Saltando validación de templates debido a errores críticos"
fi

# Resumen final
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 RESUMEN DE VALIDACIÓN${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ $total_errors -eq 0 ]; then
    echo -e "${GREEN}🎉 ¡VALIDACIÓN EXITOSA!${NC}"
    echo -e "${GREEN}✅ Todos los templates y configuraciones son válidos${NC}"
    echo -e "${GREEN}✅ El proyecto está listo para despliegue${NC}"
    echo ""
    echo -e "${GREEN}🚀 Para desplegar, ejecuta: ./scripts/deploy.sh${NC}"
    exit 0
else
    echo -e "${RED}❌ VALIDACIÓN FALLÓ${NC}"
    echo -e "${RED}🔍 Se encontraron $total_errors errores${NC}"
    echo ""
    echo -e "${YELLOW}🔧 Corrige los errores y ejecuta la validación nuevamente${NC}"
    exit 1
fi
