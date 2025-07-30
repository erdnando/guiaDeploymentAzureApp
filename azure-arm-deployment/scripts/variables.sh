#!/bin/bash

# =============================================================================
# Variables de Entorno para Azure ARM Deployment
# =============================================================================
# Este archivo contiene todas las variables necesarias para el despliegue
# Asegúrate de personalizar estos valores antes de ejecutar los scripts

# Variables principales del proyecto
export PROJECT_NAME="paymentapp"
export ENVIRONMENT="dev"  # Opciones: dev, test, prod
export RESOURCE_GROUP="rg-${PROJECT_NAME}-${ENVIRONMENT}"
export LOCATION="eastus"   # Cambiar según tu región preferida

# Variables de PostgreSQL
export POSTGRES_ADMIN_USER="pgadmin"
export POSTGRES_DB_NAME="paymentdb"
export POSTGRES_VERSION="14"

# Variables de Container Registry (GitHub Container Registry)
export REGISTRY_SERVER="ghcr.io"
export REGISTRY_USERNAME="tu-usuario-github"          # CAMBIAR POR TU USUARIO
export REGISTRY_PASSWORD="tu-github-token"            # CAMBIAR POR TU TOKEN
export BACKEND_IMAGE="${REGISTRY_SERVER}/${REGISTRY_USERNAME}/payment-api:latest"
export FRONTEND_IMAGE="${REGISTRY_SERVER}/${REGISTRY_USERNAME}/payment-frontend:latest"

# Variables de monitoreo
export ALERT_EMAIL="admin@tuempresa.com"              # CAMBIAR POR TU EMAIL

# Variables calculadas automáticamente
export UNIQUE_SUFFIX=$(date +%s)
export POSTGRES_SERVER_NAME="pg-${PROJECT_NAME}-${ENVIRONMENT}-${UNIQUE_SUFFIX}"
export VNET_NAME="vnet-${PROJECT_NAME}-${ENVIRONMENT}"
export CONTAINERAPP_ENV_NAME="env-${PROJECT_NAME}-${ENVIRONMENT}"
export LOG_ANALYTICS_WORKSPACE="log-${PROJECT_NAME}-${ENVIRONMENT}"

# Función para mostrar todas las variables configuradas
show_variables() {
    echo "=========================================="
    echo "Variables de entorno configuradas:"
    echo "=========================================="
    echo "PROJECT_NAME: $PROJECT_NAME"
    echo "ENVIRONMENT: $ENVIRONMENT"
    echo "RESOURCE_GROUP: $RESOURCE_GROUP"
    echo "LOCATION: $LOCATION"
    echo "POSTGRES_SERVER_NAME: $POSTGRES_SERVER_NAME"
    echo "VNET_NAME: $VNET_NAME"
    echo "BACKEND_IMAGE: $BACKEND_IMAGE"
    echo "FRONTEND_IMAGE: $FRONTEND_IMAGE"
    echo "ALERT_EMAIL: $ALERT_EMAIL"
    echo "=========================================="
}

# Función para validar variables requeridas
validate_variables() {
    local errors=0
    
    if [[ "$REGISTRY_USERNAME" == "tu-usuario-github" ]]; then
        echo "❌ ERROR: Debes cambiar REGISTRY_USERNAME por tu usuario real de GitHub"
        errors=$((errors + 1))
    fi
    
    if [[ "$REGISTRY_PASSWORD" == "tu-github-token" ]]; then
        echo "❌ ERROR: Debes cambiar REGISTRY_PASSWORD por tu token real de GitHub"
        errors=$((errors + 1))
    fi
    
    if [[ "$ALERT_EMAIL" == "admin@tuempresa.com" ]]; then
        echo "⚠️  ADVERTENCIA: Considera cambiar ALERT_EMAIL por tu email real"
    fi
    
    if [ $errors -gt 0 ]; then
        echo ""
        echo "❌ Se encontraron $errors errores en la configuración."
        echo "Por favor, edita el archivo variables.sh antes de continuar."
        return 1
    fi
    
    echo "✅ Todas las variables están configuradas correctamente"
    return 0
}

# Función para verificar autenticación en Azure
check_azure_auth() {
    echo "🔍 Verificando autenticación en Azure..."
    if ! az account show > /dev/null 2>&1; then
        echo "❌ No estás autenticado en Azure. Ejecuta 'az login' primero."
        return 1
    fi
    
    local subscription_name=$(az account show --query name -o tsv)
    local subscription_id=$(az account show --query id -o tsv)
    echo "✅ Autenticado en Azure"
    echo "   Suscripción: $subscription_name"
    echo "   ID: $subscription_id"
    return 0
}

# Si el script se ejecuta directamente (no se hace source)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "🚀 Configurando variables de entorno para Azure ARM Deployment"
    echo ""
    show_variables
    echo ""
    validate_variables
    echo ""
    check_azure_auth
    echo ""
    echo "💡 Para cargar estas variables en tu sesión actual, ejecuta:"
    echo "   source variables.sh"
fi
