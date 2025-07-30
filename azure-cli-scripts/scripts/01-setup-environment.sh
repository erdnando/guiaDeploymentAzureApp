#!/bin/bash

# ============================================================================
# 01-setup-environment.sh
# Configuración del entorno base - CON VALIDACIONES PARA INGENIEROS JUNIOR
# ============================================================================

set -e  # Salir si algún comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE} 01 - CONFIGURACIÓN DEL ENTORNO${NC}"
echo -e "${BLUE}============================================================================${NC}"

# ¿Qué estamos haciendo?
echo -e "\n${YELLOW}¿QUÉ ESTAMOS HACIENDO?${NC}"
echo "Configurando el entorno base para nuestro sistema de pagos:"
echo "• Verificando prerrequisitos"
echo "• Creando Resource Group"
echo "• Configurando ubicación por defecto"
echo "• Validando permisos"

# ¿Por qué?
echo -e "\n${YELLOW}¿POR QUÉ?${NC}"
echo "Este paso es fundamental porque:"
echo "• Establece la 'foundation' donde vivirán todos los recursos"
echo "• Verifica que tenemos permisos adecuados"
echo "• Configura la región óptima para el proyecto"
echo "• Evita errores en pasos posteriores"

# 🚨 VALIDACIONES CRÍTICAS PARA INGENIEROS JUNIOR
echo -e "\n${CYAN}🔍 VALIDACIONES PARA INGENIEROS JUNIOR...${NC}"

# Verificar que estamos en el directorio correcto
CURRENT_DIR=$(basename "$(pwd)")
if [[ "$CURRENT_DIR" != "azure-cli-scripts" ]]; then
    echo -e "${RED}❌ ERROR: No estás en el directorio correcto${NC}"
    echo -e "${YELLOW}💡 SOLUCIÓN: cd azure-cli-scripts${NC}"
    echo "Directorio actual: $(pwd)"
    echo "Directorio esperado: .../azure-cli-scripts"
    exit 1
fi

# Verificar Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ ERROR: Azure CLI no está instalado${NC}"
    echo -e "${YELLOW}💡 SOLUCIÓN: Instala Azure CLI${NC}"
    echo "Ubuntu/Debian: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    echo "macOS: brew install azure-cli"
    exit 1
fi

# Verificar login en Azure
if ! az account show &>/dev/null; then
    echo -e "${RED}❌ ERROR: No estás autenticado en Azure${NC}"
    echo -e "${YELLOW}💡 SOLUCIÓN: az login${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Validaciones básicas pasaron${NC}"

echo -e "${GREEN}✅ Validaciones básicas pasaron${NC}"

echo -e "\n${BLUE}🔧 CARGANDO CONFIGURACIÓN...${NC}"

# Cargar variables de entorno
if [[ -f "parameters/dev.env" ]]; then
    source parameters/dev.env
    echo -e "${GREEN}✅ Variables cargadas desde parameters/dev.env${NC}"
else
    echo -e "${RED}❌ ERROR: Archivo parameters/dev.env no encontrado${NC}"
    echo -e "${YELLOW}💡 SOLUCIÓN: Crear archivo con las variables necesarias${NC}"
    echo ""
    echo "El archivo debe contener al menos:"
    echo "export PROJECT_NAME=\"PaymentSystem\""
    echo "export ENVIRONMENT=\"dev\""
    echo "export LOCATION=\"canadacentral\""
    exit 1
fi

# Verificar variables críticas
echo -e "\n${BLUE}🔍 VERIFICANDO VARIABLES CRÍTICAS...${NC}"
required_vars=("PROJECT_NAME" "ENVIRONMENT" "LOCATION" "RESOURCE_GROUP" "DB_ADMIN_USER" "DB_ADMIN_PASSWORD")
missing_vars=()

for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        missing_vars+=("$var")
        echo -e "${RED}❌ Variable faltante: $var${NC}"
    else
        echo -e "${GREEN}✅ Variable configurada: $var${NC}"
    fi
done

if [[ ${#missing_vars[@]} -gt 0 ]]; then
    echo -e "\n${RED}❌ ERROR: Variables críticas no configuradas${NC}"
    echo -e "${YELLOW}💡 SOLUCIÓN: Edita parameters/dev.env y agrega:${NC}"
    for var in "${missing_vars[@]}"; do
        echo "export $var=\"valor-aqui\""
    done
    exit 1
fi

echo ""
info "📋 CONFIGURACIÓN ACTUAL:"
echo "   PROJECT_NAME: $PROJECT_NAME"
echo "   ENVIRONMENT: $ENVIRONMENT"
echo "   LOCATION: $LOCATION"
echo "   RESOURCE_GROUP: $RESOURCE_GROUP"
echo "   DB_SERVER_NAME: $DB_SERVER_NAME"
echo "   DB_ADMIN_USER: $DB_ADMIN_USER"

echo ""
echo "🔍 Verificando Azure CLI..."

# Verificar Azure CLI
if ! command -v az &> /dev/null; then
    error "Azure CLI no está instalado"
    exit 1
fi

# Verificar login
if ! az account show &> /dev/null; then
    error "No estás logueado en Azure"
    info "Ejecutar: az login"
    exit 1
fi

account_name=$(az account show --query name --output tsv)
success "Logueado en Azure: $account_name"

echo ""
echo "🔧 Instalando extensiones Azure CLI..."

# Instalar extensiones necesarias
az extension add --name containerapp --upgrade 2>/dev/null || true
az extension add --name application-insights --upgrade 2>/dev/null || true
az extension add --name log-analytics --upgrade 2>/dev/null || true

success "Extensiones Azure CLI actualizadas"

echo ""
echo "🏗️ Creando Resource Group..."

# Crear Resource Group con tags
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --tags \
    Project=$PROJECT_NAME \
    Environment=$ENVIRONMENT \
    CreatedBy="CLI-Scripts" \
    ManagedBy="Manual-CLI" \
    Purpose="Payment-Processing-System" \
  --output table

success "Resource Group creado: $RESOURCE_GROUP"

# Guardar variables para otros scripts
echo "export PROJECT_NAME=\"$PROJECT_NAME\"" > /tmp/cli-vars.env
echo "export ENVIRONMENT=\"$ENVIRONMENT\"" >> /tmp/cli-vars.env
echo "export LOCATION=\"$LOCATION\"" >> /tmp/cli-vars.env
echo "export RESOURCE_GROUP=\"$RESOURCE_GROUP\"" >> /tmp/cli-vars.env
echo "export DB_SERVER_NAME=\"$DB_SERVER_NAME\"" >> /tmp/cli-vars.env
echo "export DB_ADMIN_USER=\"$DB_ADMIN_USER\"" >> /tmp/cli-vars.env
echo "export DB_ADMIN_PASSWORD=\"$DB_ADMIN_PASSWORD\"" >> /tmp/cli-vars.env

success "Variables guardadas en /tmp/cli-vars.env"

echo ""
success "🎉 SETUP COMPLETADO!"
info "Próximo paso: ./scripts/02-create-networking.sh"
echo ""
