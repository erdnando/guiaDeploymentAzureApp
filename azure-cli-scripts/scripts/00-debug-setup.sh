#!/bin/bash

# ============================================================================
# 00-debug-setup.sh
# Script de debugging para verificar prerequisites y guiar a ingenieros junior
# ============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${PURPLE}============================================================================${NC}"
echo -e "${PURPLE} 🔍 DEBUG SETUP - VERIFICACIÓN COMPLETA PARA INGENIEROS JUNIOR${NC}"
echo -e "${PURPLE}============================================================================${NC}"

# ¿Qué estamos haciendo?
echo -e "\n${YELLOW}¿QUÉ HACE ESTE SCRIPT?${NC}"
echo "Este script verifica que tienes TODO lo necesario para implementar"
echo "el sistema de pagos exitosamente. Si algo falla, te dirá exactamente"
echo "cómo solucionarlo."

echo -e "\n${CYAN}🎯 OBJETIVO: Asegurar que puedas completar TODA la implementación sin problemas${NC}"

# Función para mostrar mensaje de error con solución
show_error_with_solution() {
    local error_msg=$1
    local solution=$2
    echo -e "\n${RED}❌ ERROR: $error_msg${NC}"
    echo -e "${YELLOW}💡 SOLUCIÓN:${NC}"
    echo -e "$solution"
    echo -e "\n${CYAN}Después de solucionarlo, ejecuta este script nuevamente.${NC}"
}

# Función para mostrar mensaje de éxito
show_success() {
    local msg=$1
    echo -e "${GREEN}✅ $msg${NC}"
}

# Función para mostrar advertencia
show_warning() {
    local msg=$1
    local tip=$2
    echo -e "${YELLOW}⚠️  $msg${NC}"
    if [[ -n "$tip" ]]; then
        echo -e "${CYAN}💡 TIP: $tip${NC}"
    fi
}

echo -e "\n${BLUE}🔍 INICIANDO VERIFICACIÓN COMPLETA...${NC}"
echo "========================================"

# Check 1: Verificar que estamos en el directorio correcto
echo -e "\n${BLUE}1. Verificando directorio de trabajo...${NC}"
CURRENT_DIR=$(basename "$(pwd)")
if [[ "$CURRENT_DIR" == "azure-cli-scripts" ]]; then
    show_success "Estás en el directorio correcto: azure-cli-scripts"
elif [[ -d "azure-cli-scripts" ]]; then
    show_warning "Estás en el directorio padre" "Ejecuta: cd azure-cli-scripts && ./scripts/00-debug-setup.sh"
    cd azure-cli-scripts
    show_success "Navegado automáticamente a azure-cli-scripts"
else
    show_error_with_solution "No estás en el directorio correcto" "
    1. Navega al directorio del proyecto:
       cd /ruta/a/tu/proyecto/azure-cli-scripts
    
    2. O clona el repositorio si no lo tienes:
       git clone [url-del-repo]
       cd azure-cli-scripts"
    exit 1
fi

# Check 2: Verificar Azure CLI instalado
echo -e "\n${BLUE}2. Verificando Azure CLI...${NC}"
if command -v az &> /dev/null; then
    AZ_VERSION=$(az version --query '\"azure-cli\"' -o tsv)
    show_success "Azure CLI instalado - versión: $AZ_VERSION"
    
    # Verificar versión mínima
    MIN_VERSION="2.50.0"
    if printf '%s\n' "$MIN_VERSION" "$AZ_VERSION" | sort -V | head -n1 | grep -q "^$MIN_VERSION$"; then
        show_success "Versión de Azure CLI es compatible"
    else
        show_warning "Tu versión de Azure CLI es antigua" "Actualiza con: az upgrade"
    fi
else
    show_error_with_solution "Azure CLI no está instalado" "
    1. En Ubuntu/Debian:
       curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    
    2. En macOS:
       brew install azure-cli
    
    3. En Windows:
       Descargar desde: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check 3: Verificar login en Azure
echo -e "\n${BLUE}3. Verificando autenticación en Azure...${NC}"
if az account show &>/dev/null; then
    ACCOUNT_NAME=$(az account show --query "name" -o tsv)
    SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
    show_success "Autenticado en Azure"
    echo -e "   ${CYAN}Subscription: $ACCOUNT_NAME${NC}"
    echo -e "   ${CYAN}ID: $SUBSCRIPTION_ID${NC}"
else
    show_error_with_solution "No estás autenticado en Azure" "
    1. Ejecuta: az login
    2. Sigue las instrucciones en el navegador
    3. Si tienes múltiples subscriptions:
       az account list --output table
       az account set --subscription 'nombre-o-id'"
    exit 1
fi

# Check 4: Verificar permisos en la subscription
echo -e "\n${BLUE}4. Verificando permisos en la subscription...${NC}"
ROLE_ASSIGNMENTS=$(az role assignment list --assignee "$(az account show --query user.name -o tsv)" --scope "/subscriptions/$(az account show --query id -o tsv)" --query "[?roleDefinitionName=='Owner' || roleDefinitionName=='Contributor'].roleDefinitionName" -o tsv)

if [[ -n "$ROLE_ASSIGNMENTS" ]]; then
    show_success "Tienes permisos suficientes: $ROLE_ASSIGNMENTS"
else
    show_warning "No se pudieron verificar permisos automáticamente" "
    Asegúrate de tener permisos de Contributor o Owner en la subscription.
    Si no tienes permisos, contacta al administrador de Azure."
fi

# Check 5: Verificar estructura de archivos
echo -e "\n${BLUE}5. Verificando estructura de archivos...${NC}"
REQUIRED_FILES=(
    "parameters/dev.env"
    "scripts/01-setup-environment.sh"
    "scripts/02-create-networking.sh"
    "scripts/03-create-database.sh"
    "scripts/04-create-container-env.sh"
    "scripts/05-create-monitoring.sh"
    "scripts/06-deploy-applications.sh"
    "scripts/07-create-app-gateway.sh"
    "scripts/98-troubleshoot.sh"
    "scripts/99-cleanup.sh"
    "docs/GUIA-CLI-PASO-A-PASO.md"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        show_success "Archivo encontrado: $file"
    else
        MISSING_FILES+=("$file")
        echo -e "${RED}❌ Archivo faltante: $file${NC}"
    fi
done

if [[ ${#MISSING_FILES[@]} -gt 0 ]]; then
    show_error_with_solution "Faltan archivos críticos" "
    Archivos faltantes: ${MISSING_FILES[*]}
    
    1. Asegúrate de haber descargado/clonado el proyecto completo
    2. Verifica que no hayas movido archivos accidentalmente
    3. Si persiste el problema, vuelve a descargar el proyecto"
    exit 1
fi

# Check 6: Verificar permisos de ejecución en scripts
echo -e "\n${BLUE}6. Verificando permisos de ejecución...${NC}"
SCRIPT_FILES=(scripts/*.sh)
SCRIPTS_WITHOUT_EXEC=()

for script in "${SCRIPT_FILES[@]}"; do
    if [[ -x "$script" ]]; then
        show_success "Script ejecutable: $(basename "$script")"
    else
        SCRIPTS_WITHOUT_EXEC+=("$script")
        echo -e "${RED}❌ Sin permisos de ejecución: $script${NC}"
    fi
done

if [[ ${#SCRIPTS_WITHOUT_EXEC[@]} -gt 0 ]]; then
    echo -e "\n${YELLOW}🔧 SOLUCIONANDO PERMISOS AUTOMÁTICAMENTE...${NC}"
    chmod +x scripts/*.sh
    show_success "Permisos de ejecución agregados a todos los scripts"
fi

# Check 7: Verificar variables de entorno
echo -e "\n${BLUE}7. Verificando archivo de variables...${NC}"
if [[ -f "parameters/dev.env" ]]; then
    # Cargar variables sin mostrar el output
    source parameters/dev.env >/dev/null 2>&1
    
    REQUIRED_VARS=("PROJECT_NAME" "ENVIRONMENT" "LOCATION" "RESOURCE_GROUP")
    MISSING_VARS=()
    
    for var in "${REQUIRED_VARS[@]}"; do
        if [[ -n "${!var}" ]]; then
            show_success "Variable definida: $var=${!var}"
        else
            MISSING_VARS+=("$var")
            echo -e "${RED}❌ Variable faltante: $var${NC}"
        fi
    done
    
    if [[ ${#MISSING_VARS[@]} -gt 0 ]]; then
        show_error_with_solution "Variables críticas no definidas" "
        Edita el archivo parameters/dev.env y define:
        ${MISSING_VARS[*]}
        
        Ejemplo:
        export PROJECT_NAME=\"PaymentSystem\"
        export ENVIRONMENT=\"dev\"
        export LOCATION=\"canadacentral\""
        exit 1
    fi
else
    show_error_with_solution "Archivo de variables no encontrado" "
    El archivo parameters/dev.env es obligatorio.
    Crea el archivo o verifica que no lo hayas movido."
    exit 1
fi

# Check 8: Verificar conectividad a Azure
echo -e "\n${BLUE}8. Verificando conectividad a Azure...${NC}"
if az group list --query "[0].name" -o tsv &>/dev/null; then
    show_success "Conectividad a Azure API funcionando"
else
    show_error_with_solution "No se puede conectar a Azure API" "
    1. Verifica tu conexión a internet
    2. Prueba: az login --use-device-code
    3. Si persiste, verifica firewall/proxy corporativo"
    exit 1
fi

# Check 9: Verificar disponibilidad de recursos en la región
echo -e "\n${BLUE}9. Verificando disponibilidad de recursos en $LOCATION...${NC}"
AVAILABLE_LOCATIONS=$(az account list-locations --query "[?name=='$LOCATION'].name" -o tsv)
if [[ -n "$AVAILABLE_LOCATIONS" ]]; then
    show_success "Región $LOCATION disponible"
    
    # Verificar Container Apps disponible en la región
    CONTAINER_APPS_AVAILABLE=$(az provider show --namespace Microsoft.App --query "resourceTypes[?resourceType=='containerApps'].locations[]" -o tsv | grep -i "$LOCATION" || echo "")
    if [[ -n "$CONTAINER_APPS_AVAILABLE" ]]; then
        show_success "Container Apps disponible en $LOCATION"
    else
        show_warning "Container Apps puede no estar disponible en $LOCATION" "
        Considera cambiar LOCATION a 'canadacentral' o 'eastus2' en parameters/dev.env"
    fi
else
    show_error_with_solution "Región $LOCATION no válida" "
    1. Ve regiones disponibles: az account list-locations --output table
    2. Cambia LOCATION en parameters/dev.env a una región válida
    3. Recomendadas: canadacentral, eastus2, westeurope"
    exit 1
fi

# Check 10: Verificar cuotas y límites
echo -e "\n${BLUE}10. Verificando cuotas básicas...${NC}"
CURRENT_RG_COUNT=$(az group list --query "length([])" -o tsv)
show_success "Resource Groups actuales: $CURRENT_RG_COUNT"

if [[ $CURRENT_RG_COUNT -gt 800 ]]; then
    show_warning "Tienes muchos Resource Groups" "
    Considera limpiar RGs no utilizados para evitar límites"
fi

# RESUMEN FINAL
echo -e "\n${PURPLE}============================================================================${NC}"
echo -e "${PURPLE} 🎉 VERIFICACIÓN COMPLETA - RESUMEN${NC}"
echo -e "${PURPLE}============================================================================${NC}"

echo -e "\n${GREEN}✅ TODAS LAS VERIFICACIONES PASARON EXITOSAMENTE${NC}"
echo ""
echo -e "${CYAN}📋 CONFIGURACIÓN ACTUAL:${NC}"
echo -e "   Proyecto: ${YELLOW}$PROJECT_NAME${NC}"
echo -e "   Ambiente: ${YELLOW}$ENVIRONMENT${NC}"
echo -e "   Región: ${YELLOW}$LOCATION${NC}"
echo -e "   Resource Group: ${YELLOW}$RESOURCE_GROUP${NC}"
echo -e "   Subscription: ${YELLOW}$(az account show --query name -o tsv)${NC}"

echo -e "\n${BLUE}🚀 SIGUIENTE PASO:${NC}"
echo -e "Ahora puedes ejecutar los scripts en orden:"
echo ""
echo -e "${CYAN}# Para comenzar la implementación completa:${NC}"
echo -e "${YELLOW}./scripts/01-setup-environment.sh${NC}"
echo ""
echo -e "${CYAN}# O para seguir la guía paso a paso:${NC}"
echo -e "${YELLOW}cat docs/GUIA-CLI-PASO-A-PASO.md${NC}"

echo -e "\n${GREEN}💡 TIPS PARA INGENIEROS JUNIOR:${NC}"
echo "1. 📖 Lee SIEMPRE la guía completa antes de empezar"
echo "2. 🔍 Ejecuta UN script a la vez y verifica resultados"
echo "3. 📝 Si algo falla, usa ./scripts/98-troubleshoot.sh"
echo "4. 🧹 Al terminar, limpia recursos con ./scripts/99-cleanup.sh"
echo "5. ❓ Cada script explica QUÉ hace y POR QUÉ lo hace"

echo -e "\n${PURPLE}🎯 ¡ESTÁS LISTO PARA IMPLEMENTAR EL SISTEMA DE PAGOS!${NC}"
