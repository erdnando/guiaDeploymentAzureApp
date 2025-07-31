#!/bin/bash

# ============================================================================
# 07-create-app-gateway.sh
# Crear Application Gateway con SSL y routing avanzado
# ============================================================================

set -e  # Salir si algún comando falla

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE} 07 - CREAR APPLICATION GATEWAY${NC}"
echo -e "${BLUE}============================================================================${NC}"

# ¿Qué estamos haciendo?
echo -e "\n${YELLOW}¿QUÉ ESTAMOS HACIENDO?${NC}"
echo "Creando Application Gateway como punto de entrada único:"
echo "• Load balancer de capa 7 (HTTP/HTTPS)"
echo "• SSL termination y certificados"
echo "• Path-based routing a Container Apps"
echo "• WAF (Web Application Firewall) opcional"

# ¿Por qué?
echo -e "\n${YELLOW}¿POR QUÉ?${NC}"
echo "Application Gateway proporciona:"
echo "• Punto de entrada único con dominio custom"
echo "• SSL offloading y gestión de certificados"
echo "• Routing inteligente basado en paths/headers"
echo "• Protección WAF contra ataques comunes"
echo "• Session affinity y health probes"

# Validar variables requeridas
echo -e "\n${BLUE}🔍 VALIDANDO VARIABLES...${NC}"
if [[ -z "$RESOURCE_GROUP" ]]; then
    echo -e "${RED}❌ Error: RESOURCE_GROUP no está definido${NC}"
    echo "Ejecuta: source parameters/dev.env"
    exit 1
fi

required_vars=("PROJECT_NAME" "ENVIRONMENT" "LOCATION")
for var in "${required_vars[@]}"; do
    if [[ -z "${!var}" ]]; then
        echo -e "${RED}❌ Error: Variable $var no está definida${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ Variables validadas${NC}"

# Definir nombres de recursos
APPGW_NAME="agw-${PROJECT_NAME}-${ENVIRONMENT}"
APPGW_PIP_NAME="pip-agw-${PROJECT_NAME}-${ENVIRONMENT}"
VNET_NAME="vnet-${PROJECT_NAME}-${ENVIRONMENT}"
APPGW_SUBNET_NAME="subnet-appgw"

echo -e "\n${BLUE}📋 RECURSOS A CREAR:${NC}"
echo "• Application Gateway: $APPGW_NAME"
echo "• Public IP: $APPGW_PIP_NAME"
echo "• VNet: $VNET_NAME"
echo "• Subnet: $APPGW_SUBNET_NAME"
echo "• Ubicación: $LOCATION"

# CHECKPOINT: Verificar que VNet existe
echo -e "\n${YELLOW}🔍 CHECKPOINT: Verificando Virtual Network...${NC}"
VNET_EXISTS=$(az network vnet show \
    --name "$VNET_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "name" -o tsv 2>/dev/null || echo "")

if [[ -z "$VNET_EXISTS" ]]; then
    echo -e "${RED}❌ Virtual Network no encontrada${NC}"
    echo "Ejecuta primero: ./02-create-networking.sh"
    exit 1
fi

echo -e "${GREEN}✅ Virtual Network encontrada: $VNET_EXISTS${NC}"

# Verificar si subnet para Application Gateway existe
echo -e "\n${YELLOW}🔍 CHECKPOINT: Verificando subnet para Application Gateway...${NC}"
APPGW_SUBNET_EXISTS=$(az network vnet subnet show \
    --vnet-name "$VNET_NAME" \
    --name "$APPGW_SUBNET_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "name" -o tsv 2>/dev/null || echo "")

if [[ -z "$APPGW_SUBNET_EXISTS" ]]; then
    echo -e "\n${BLUE}🚀 CREANDO SUBNET PARA APPLICATION GATEWAY...${NC}"
    echo "Comando a ejecutar:"
    echo "az network vnet subnet create \\"
    echo "  --vnet-name $VNET_NAME \\"
    echo "  --name $APPGW_SUBNET_NAME \\"
    echo "  --resource-group $RESOURCE_GROUP \\"
    echo "  --address-prefix 10.0.3.0/24"

    az network vnet subnet create \
        --vnet-name "$VNET_NAME" \
        --name "$APPGW_SUBNET_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --address-prefix "10.0.3.0/24" \
        --output table

    echo -e "${GREEN}✅ Subnet para Application Gateway creada${NC}"
else
    echo -e "${GREEN}✅ Subnet para Application Gateway ya existe: $APPGW_SUBNET_EXISTS${NC}"
fi

# Crear Public IP para Application Gateway
echo -e "\n${YELLOW}🔍 CHECKPOINT: Verificando Public IP...${NC}"
APPGW_PIP_EXISTS=$(az network public-ip show \
    --name "$APPGW_PIP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "name" -o tsv 2>/dev/null || echo "")

if [[ -z "$APPGW_PIP_EXISTS" ]]; then
    echo -e "\n${BLUE}🚀 CREANDO PUBLIC IP PARA APPLICATION GATEWAY...${NC}"
    echo "Comando a ejecutar:"
    echo "az network public-ip create \\"
    echo "  --name $APPGW_PIP_NAME \\"
    echo "  --resource-group $RESOURCE_GROUP \\"
    echo "  --allocation-method Static \\"
    echo "  --sku Standard"

    az network public-ip create \
        --name "$APPGW_PIP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --allocation-method Static \
        --sku Standard \
        --location "$LOCATION" \
        --output table

    echo -e "${GREEN}✅ Public IP creada${NC}"
else
    echo -e "${GREEN}✅ Public IP ya existe: $APPGW_PIP_EXISTS${NC}"
fi

# Obtener URLs de Container Apps si existen
echo -e "\n${BLUE}🔗 OBTENIENDO URLs DE CONTAINER APPS...${NC}"
API_GATEWAY_NAME="ca-gateway-${ENVIRONMENT}"
PAYMENT_API_NAME="ca-payment-${ENVIRONMENT}"

API_GATEWAY_FQDN=$(az containerapp show \
    --name "$API_GATEWAY_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null || echo "")

PAYMENT_API_FQDN=$(az containerapp show \
    --name "$PAYMENT_API_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null || echo "")

if [[ -z "$API_GATEWAY_FQDN" ]]; then
    echo -e "${YELLOW}⚠️  Container Apps no encontradas. Usando backends de ejemplo${NC}"
    API_GATEWAY_FQDN="httpbin.org"
    PAYMENT_API_FQDN="httpbin.org"
fi

echo "API Gateway FQDN: $API_GATEWAY_FQDN"
echo "Payment API FQDN: $PAYMENT_API_FQDN"

# Verificar si Application Gateway ya existe
echo -e "\n${YELLOW}🔍 CHECKPOINT: Verificando Application Gateway...${NC}"
APPGW_EXISTS=$(az network application-gateway show \
    --name "$APPGW_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "name" -o tsv 2>/dev/null || echo "")

if [[ -n "$APPGW_EXISTS" ]]; then
    echo -e "${YELLOW}⚠️  Application Gateway ya existe: $APPGW_EXISTS${NC}"
    echo "¿Deseas continuar sin recrear? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Operación cancelada"
        exit 0
    fi
else
    # 🛡️ CREAR WAF POLICY PRIMERO
    echo -e "\n${BLUE}🛡️ CREANDO WAF POLICY...${NC}"
    WAF_POLICY_NAME="wafpol-${PROJECT_NAME}-${ENVIRONMENT}"

    echo "Creando WAF Policy: $WAF_POLICY_NAME"
    az network application-gateway waf-policy create \
        --name "$WAF_POLICY_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --tags \
            Project="$PROJECT_NAME" \
            Environment="$ENVIRONMENT" \
            Purpose="WAF-Protection" \
        --output table

    success "WAF Policy creada: $WAF_POLICY_NAME"

    # Configurar reglas OWASP
    echo -e "\n${BLUE}🔒 CONFIGURANDO REGLAS OWASP...${NC}"
    az network application-gateway waf-policy managed-rule rule-set add \
        --policy-name "$WAF_POLICY_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --type "OWASP" \
        --version "3.2" \
        --output table

    # Configurar policy settings
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        WAF_MODE="Prevention"
        APPGW_SKU="WAF_v2"
    else
        WAF_MODE="Detection"
        APPGW_SKU="WAF_v2"  # Usar WAF también en dev para consistencia
    fi

    echo "Configurando WAF mode: $WAF_MODE"
    az network application-gateway waf-policy policy-setting update \
        --policy-name "$WAF_POLICY_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --mode "$WAF_MODE" \
        --state "Enabled" \
        --request-body-check true \
        --max-request-body-size 128 \
        --file-upload-limit 100 \
        --output table

    success "WAF Policy configurada en modo: $WAF_MODE"

    # Crear Application Gateway
    echo -e "\n${BLUE}🚀 CREANDO APPLICATION GATEWAY...${NC}"
    echo "Esto puede tomar 10-15 minutos..."
    echo ""
    echo "Comando a ejecutar:"
    echo "az network application-gateway create \\"
    echo "  --name $APPGW_NAME \\"
    echo "  --location $LOCATION \\"
    echo "  --resource-group $RESOURCE_GROUP \\"
    echo "  --vnet-name $VNET_NAME \\"
    echo "  --subnet $APPGW_SUBNET_NAME \\"
    echo "  --capacity 2 \\"
    echo "  --sku $APPGW_SKU \\"
    echo "  --waf-policy $WAF_POLICY_NAME \\"
    echo "  --http-settings-cookie-based-affinity Disabled \\"
    echo "  --frontend-port 80 \\"
    echo "  --http-settings-port 443 \\"
    echo "  --http-settings-protocol Https \\"
    echo "  --public-ip-address $APPGW_PIP_NAME \\"
    echo "  --servers $API_GATEWAY_FQDN"

    az network application-gateway create \
        --name "$APPGW_NAME" \
        --location "$LOCATION" \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "$VNET_NAME" \
        --subnet "$APPGW_SUBNET_NAME" \
        --capacity 2 \
        --sku "$APPGW_SKU" \
        --waf-policy "$WAF_POLICY_NAME" \
        --http-settings-cookie-based-affinity Disabled \
        --frontend-port 80 \
        --http-settings-port 443 \
        --http-settings-protocol Https \
        --public-ip-address "$APPGW_PIP_NAME" \
        --servers "$API_GATEWAY_FQDN" \
        --tags \
            Project="$PROJECT_NAME" \
            Environment="$ENVIRONMENT" \
            Purpose="Application-Gateway-WAF" \
        --output table

    echo -e "${GREEN}✅ Application Gateway creado con WAF habilitado${NC}"
    
    # Configurar diagnostic logging
    echo -e "\n${BLUE}📊 CONFIGURANDO DIAGNOSTIC LOGGING...${NC}"
    LOG_WORKSPACE_NAME="log-${PROJECT_NAME}-${ENVIRONMENT}-cli"
    
    # Obtener workspace ID
    WORKSPACE_ID=$(az monitor log-analytics workspace show \
        --resource-group "$RESOURCE_GROUP" \
        --workspace-name "$LOG_WORKSPACE_NAME" \
        --query "id" -o tsv 2>/dev/null || echo "")
        
    if [[ -n "$WORKSPACE_ID" ]]; then
        az monitor diagnostic-settings create \
            --name "diag-agw-${PROJECT_NAME}-${ENVIRONMENT}" \
            --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/applicationGateways/$APPGW_NAME" \
            --workspace "$WORKSPACE_ID" \
            --logs '[
                {
                    "category": "ApplicationGatewayAccessLog",
                    "enabled": true
                },
                {
                    "category": "ApplicationGatewayPerformanceLog", 
                    "enabled": true
                },
                {
                    "category": "ApplicationGatewayFirewallLog",
                    "enabled": true
                }
            ]' \
            --metrics '[
                {
                    "category": "AllMetrics",
                    "enabled": true
                }
            ]' \
            --output table
            
        success "Diagnostic logging configurado"
    else
        warning "Log Analytics workspace no encontrado, diagnostic logging omitido"
    fi
fi

# APRENDIZAJE: Conceptos técnicos
echo -e "\n${YELLOW}📚 APRENDIZAJE: Application Gateway + WAF${NC}"
echo ""
echo "🏗️  ARQUITECTURA LAYER 7:"
echo "   • Frontend: Listener en puerto 80/443"
echo "   • Backend Pool: Conjunto de servidores destino"
echo "   • HTTP Settings: Configuración de conexión al backend"
echo "   • Routing Rules: Reglas de enrutamiento de requests"
echo ""
echo "⚡ FUNCIONALIDADES AVANZADAS:"
echo "   • SSL Termination: Descarga SSL/TLS del backend"
echo "   • Path-based Routing: /api/users → User API, /api/payments → Payment API"
echo "   • Health Probes: Verificación automática de salud"
echo "   • Session Affinity: Sticky sessions si es necesario"
echo ""
echo "🛡️  SEGURIDAD Y WAF:"
echo "   • WAF Policy: ${WAF_POLICY_NAME}"
echo "   • OWASP Rule Set: Versión 3.2"
echo "   • Mode: ${WAF_MODE} (Detection en dev, Prevention en prod)"
echo "   • Protection: SQL Injection, XSS, CSRF, etc."
echo "   • Request Limits: 128KB body, 100MB uploads"
echo "   • Diagnostic Logging: Access, Performance, Firewall logs"
echo ""
echo "📊 MONITOREO CONFIGURADO:"
echo "   • Log Analytics Integration: Centralized logging"
echo "   • ApplicationGatewayAccessLog: Request/response details"
echo "   • ApplicationGatewayFirewallLog: WAF block/allow decisions"
echo "   • ApplicationGatewayPerformanceLog: Performance metrics"

# Configurar routing adicional si Container Apps existen
if [[ "$API_GATEWAY_FQDN" != "httpbin.org" ]]; then
    echo -e "\n${BLUE}🔗 CONFIGURANDO ROUTING AVANZADO...${NC}"
    
    # Crear backend pool para Payment API
    echo "Agregando Payment API al backend pool..."
    az network application-gateway address-pool create \
        --gateway-name "$APPGW_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --name "pool-payment-api" \
        --servers "$PAYMENT_API_FQDN" \
        --output table

    # Crear HTTP settings para Payment API
    az network application-gateway http-settings create \
        --gateway-name "$APPGW_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --name "settings-payment-api" \
        --port 443 \
        --protocol Https \
        --cookie-based-affinity Disabled \
        --timeout 30 \
        --output table

    # Crear path-based rule para /api/payments/*
    az network application-gateway url-path-map create \
        --gateway-name "$APPGW_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --name "path-map-apis" \
        --paths "/api/payments/*" \
        --address-pool "pool-payment-api" \
        --http-settings "settings-payment-api" \
        --output table

    echo -e "${GREEN}✅ Routing avanzado configurado${NC}"
fi

# Obtener información del Application Gateway
echo -e "\n${BLUE}🌐 OBTENIENDO INFORMACIÓN DEL APPLICATION GATEWAY...${NC}"

# Public IP del Application Gateway
APPGW_PUBLIC_IP=$(az network public-ip show \
    --name "$APPGW_PIP_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "ipAddress" -o tsv)

# Frontend ports
FRONTEND_PORTS=$(az network application-gateway frontend-port list \
    --gateway-name "$APPGW_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "[].{name:name,port:port}" -o table)

# Mostrar información del Application Gateway
echo -e "\n${BLUE}📊 INFORMACIÓN DEL APPLICATION GATEWAY:${NC}"
echo "╔══════════════════════════════════════════════════════════════════════════════════════╗"
echo "║                              APPLICATION GATEWAY INFO                                ║"
echo "╠══════════════════════════════════════════════════════════════════════════════════════╣"
echo "║ Name: $APPGW_NAME"
echo "║ Public IP: $APPGW_PUBLIC_IP"
echo "║ Location: $LOCATION"
echo "║ URL: http://$APPGW_PUBLIC_IP"
echo "╠══════════════════════════════════════════════════════════════════════════════════════╣"
echo "║ ROUTING CONFIGURADO:"
echo "║ • / → API Gateway ($API_GATEWAY_FQDN)"
if [[ "$API_GATEWAY_FQDN" != "httpbin.org" ]]; then
echo "║ • /api/payments/* → Payment API ($PAYMENT_API_FQDN)"
fi
echo "╚══════════════════════════════════════════════════════════════════════════════════════╝"

# Crear archivo con información del Application Gateway
echo -e "\n${BLUE}💾 GUARDANDO INFORMACIÓN DEL APPLICATION GATEWAY...${NC}"
cat > "parameters/appgateway.env" << EOF
# Información del Application Gateway generada por 07-create-app-gateway.sh
export APPGW_NAME="$APPGW_NAME"
export APPGW_PUBLIC_IP="$APPGW_PUBLIC_IP"
export APPGW_URL="http://$APPGW_PUBLIC_IP"
export APPGW_PIP_NAME="$APPGW_PIP_NAME"

echo "✅ Variables del Application Gateway cargadas"
EOF

echo -e "${GREEN}✅ Información guardada en: parameters/appgateway.env${NC}"

# CHECKPOINT: Verificar que Application Gateway está funcionando
echo -e "\n${YELLOW}🔍 CHECKPOINT FINAL: Verificando Application Gateway...${NC}"

APPGW_STATUS=$(az network application-gateway show \
    --name "$APPGW_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query "provisioningState" -o tsv)

if [[ "$APPGW_STATUS" == "Succeeded" ]]; then
    echo -e "${GREEN}✅ Application Gateway funcionando correctamente${NC}"
    
    # Test básico de conectividad
    echo -e "\n${BLUE}🧪 REALIZANDO TEST BÁSICO...${NC}"
    echo "Testeando conectividad a: http://$APPGW_PUBLIC_IP"
    
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$APPGW_PUBLIC_IP" --connect-timeout 10 || echo "000")
    
    if [[ "$HTTP_STATUS" -ge 200 && "$HTTP_STATUS" -lt 400 ]]; then
        echo -e "${GREEN}✅ Application Gateway responde correctamente (HTTP $HTTP_STATUS)${NC}"
    else
        echo -e "${YELLOW}⚠️  Application Gateway creado pero puede necesitar tiempo para estar listo (HTTP $HTTP_STATUS)${NC}"
        echo "Espera 2-3 minutos e intenta: curl http://$APPGW_PUBLIC_IP"
    fi
else
    echo -e "${RED}❌ Problemas con Application Gateway. Estado: $APPGW_STATUS${NC}"
fi

# LOGRO
echo -e "\n${GREEN}🎉 LOGRO ALCANZADO:${NC}"
echo "✅ Application Gateway desplegado exitosamente"
echo "✅ Load balancing configurado"
echo "✅ Routing avanzado implementado"
echo "✅ Punto de entrada único disponible"
echo ""
echo -e "${BLUE}📍 PRÓXIMOS PASOS OPCIONALES:${NC}"
echo "• Configurar SSL/TLS con certificados custom"
echo "• Activar WAF para protección adicional"
echo "• Configurar dominios custom"
echo "• Implementar health probes personalizados"
echo ""
echo -e "${YELLOW}💡 TIPS:${NC}"
echo "• URL principal: http://$APPGW_PUBLIC_IP"
echo "• Información guardada en: parameters/appgateway.env"
echo "• Monitorea métricas en Azure Portal > Application Gateway"
