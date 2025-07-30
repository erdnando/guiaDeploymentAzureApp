#!/bin/bash

# =============================================================================
# Script de Despliegue Completo - Azure ARM Templates
# =============================================================================
# Este script despliega toda la infraestructura en orden secuencial
# Asegúrate de haber configurado las variables en variables.sh

set -e  # Salir si cualquier comando falla

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

# Verificar que las variables estén cargadas
if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}❌ Error: Variables no cargadas correctamente${NC}"
    exit 1
fi

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

# Función para desplegar un template
deploy_template() {
    local template_number=$1
    local template_name=$2
    local description=$3
    
    log "📋 Desplegando Template $template_number: $description"
    
    local template_file="$PROJECT_ROOT/templates/0${template_number}-${template_name}.json"
    local parameters_file="$PROJECT_ROOT/parameters/0${template_number}-${template_name}.${ENVIRONMENT}.json"
    
    # Verificar que los archivos existan
    if [ ! -f "$template_file" ]; then
        error "Template file no encontrado: $template_file"
        return 1
    fi
    
    if [ ! -f "$parameters_file" ]; then
        error "Parameters file no encontrado: $parameters_file"
        return 1
    fi
    
    # Crear el deployment
    local deployment_name="deploy-${template_name}-$(date +%Y%m%d-%H%M%S)"
    
    log "   📤 Iniciando deployment: $deployment_name"
    log "   📄 Template: $(basename $template_file)"
    log "   ⚙️  Parameters: $(basename $parameters_file)"
    
    az deployment group create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$deployment_name" \
        --template-file "$template_file" \
        --parameters "@$parameters_file" \
        --output table
    
    if [ $? -eq 0 ]; then
        log "   ✅ Template $template_number completado exitosamente"
    else
        error "   ❌ Falló el deployment del template $template_number"
        return 1
    fi
    
    echo ""
}

# Función para mostrar progreso
show_progress() {
    local step=$1
    local total=6
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📊 PROGRESO DEL DESPLIEGUE: Paso $step de $total${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Banner inicial
echo -e "${BLUE}"
echo "██╗    ██╗███████╗██╗      ██████╗ ██████╗ ███╗   ███╗███████╗"
echo "██║    ██║██╔════╝██║     ██╔════╝██╔═══██╗████╗ ████║██╔════╝"
echo "██║ █╗ ██║█████╗  ██║     ██║     ██║   ██║██╔████╔██║█████╗  "
echo "██║███╗██║██╔══╝  ██║     ██║     ██║   ██║██║╚██╔╝██║██╔══╝  "
echo "╚███╔███╔╝███████╗███████╗╚██████╗╚██████╔╝██║ ╚═╝ ██║███████╗"
echo " ╚══╝╚══╝ ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝"
echo ""
echo "🏗️  Azure ARM Deployment - Sistema de Pagos"
echo "📦 Proyecto: $PROJECT_NAME"
echo "🌍 Entorno: $ENVIRONMENT"
echo "📍 Región: $LOCATION"
echo -e "${NC}"
echo ""

# Verificaciones iniciales
log "🔍 Ejecutando verificaciones previas..."

# Verificar Azure CLI
if ! command -v az &> /dev/null; then
    error "Azure CLI no está instalado"
    exit 1
fi

# Verificar autenticación
if ! az account show &> /dev/null; then
    error "No estás autenticado en Azure. Ejecuta 'az login'"
    exit 1
fi

# Verificar/crear resource group
log "🏗️  Verificando Resource Group: $RESOURCE_GROUP"
if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
    log "📁 Creando Resource Group: $RESOURCE_GROUP"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
else
    log "✅ Resource Group ya existe"
fi

echo ""
log "🚀 Iniciando despliegue secuencial de templates..."
echo ""

# Template 1: Infraestructura Base (VNET, NSG, Subnets)
show_progress 1
deploy_template 1 "infrastructure" "Infraestructura Base (VNET, NSG, Subnets)"

# Template 2: PostgreSQL Database
show_progress 2
deploy_template 2 "postgresql" "Base de Datos PostgreSQL"

# Template 3: Container Apps Environment
show_progress 3
deploy_template 3 "containerenv" "Entorno de Container Apps"

# Template 4: Application Gateway
show_progress 4
deploy_template 4 "appgateway" "Application Gateway con WAF"

# Template 5: Monitoring (Log Analytics, Application Insights)
show_progress 5
deploy_template 5 "monitoring" "Monitoreo y Alertas"

# Template 6: Container Apps
show_progress 6
deploy_template 6 "containerapps" "Aplicaciones Container Apps"

# Resumen final
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 ¡DESPLIEGUE COMPLETADO EXITOSAMENTE!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
log "📊 Obteniendo información de los recursos desplegados..."

# Obtener información de los recursos principales
echo ""
echo -e "${BLUE}📋 RECURSOS DESPLEGADOS:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Application Gateway IP
APP_GW_IP=$(az network public-ip show \
    --resource-group "$RESOURCE_GROUP" \
    --name "pip-appgw-$PROJECT_NAME-$ENVIRONMENT" \
    --query "ipAddress" \
    --output tsv 2>/dev/null || echo "No disponible")

# Container Apps URLs
BACKEND_URL=$(az containerapp show \
    --name "ca-payment-api-$ENVIRONMENT" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.configuration.ingress.fqdn" \
    --output tsv 2>/dev/null || echo "No disponible")

FRONTEND_URL=$(az containerapp show \
    --name "ca-payment-frontend-$ENVIRONMENT" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.configuration.ingress.fqdn" \
    --output tsv 2>/dev/null || echo "No disponible")

# PostgreSQL FQDN
POSTGRES_FQDN=$(az postgres flexible-server show \
    --name "$POSTGRES_SERVER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "fullyQualifiedDomainName" \
    --output tsv 2>/dev/null || echo "No disponible")

echo "🌐 Application Gateway IP: $APP_GW_IP"
echo "🗄️  PostgreSQL FQDN: $POSTGRES_FQDN"
echo "🔗 Backend URL: https://$BACKEND_URL"
echo "🖥️  Frontend URL: https://$FRONTEND_URL"
echo "📊 Resource Group: $RESOURCE_GROUP"
echo ""

echo -e "${YELLOW}📝 PRÓXIMOS PASOS:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Configurar tu aplicación para usar la cadena de conexión de PostgreSQL"
echo "2. Desplegar tus imágenes de contenedor a GitHub Container Registry"
echo "3. Actualizar las Container Apps con las nuevas imágenes"
echo "4. Configurar el dominio personalizado en Application Gateway (opcional)"
echo "5. Configurar alertas adicionales en Azure Monitor"
echo ""
echo -e "${GREEN}✨ ¡Tu infraestructura está lista para usar!${NC}"
echo ""

# Guardar información importante en un archivo
OUTPUT_FILE="$PROJECT_ROOT/deployment-info-$(date +%Y%m%d-%H%M%S).txt"
cat > "$OUTPUT_FILE" << EOF
AZURE ARM DEPLOYMENT - INFORMACIÓN DE RECURSOS
===============================================
Fecha de despliegue: $(date)
Proyecto: $PROJECT_NAME
Entorno: $ENVIRONMENT
Resource Group: $RESOURCE_GROUP
Región: $LOCATION

RECURSOS PRINCIPALES:
- Application Gateway IP: $APP_GW_IP
- PostgreSQL FQDN: $POSTGRES_FQDN
- Backend URL: https://$BACKEND_URL
- Frontend URL: https://$FRONTEND_URL

COMANDOS ÚTILES:
- Ver recursos: az resource list --resource-group "$RESOURCE_GROUP" --output table
- Ver logs backend: az containerapp logs show --name "ca-payment-api-$ENVIRONMENT" --resource-group "$RESOURCE_GROUP"
- Ver logs frontend: az containerapp logs show --name "ca-payment-frontend-$ENVIRONMENT" --resource-group "$RESOURCE_GROUP"
- Eliminar todo: az group delete --name "$RESOURCE_GROUP" --yes --no-wait
EOF

log "💾 Información guardada en: $OUTPUT_FILE"
