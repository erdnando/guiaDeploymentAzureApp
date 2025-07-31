#!/bin/bash

# 🎯 Script 02: Create Networking - Payment System CLI
# Crea VNet, subnets, NSGs y reglas de seguridad

set -e

echo "🌐 FASE 1: NETWORKING DESDE CERO"
echo "=========================# Asociar NSG con subnet de Application Gateway
az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --name "subnet-appgateway" \
  --network-security-group "nsg-appgw-$ENVIRONMENT" \
  --output table

# Asociar NSG con subnet de Container Apps
az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --name "subnet-containerapp" \
  --network-security-group "nsg-containerapp-$ENVIRONMENT" \
  --output table

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Cargar variables
if [ -f "/tmp/cli-vars.env" ]; then
    source /tmp/cli-vars.env
    success "Variables cargadas"
else
    error "Variables no encontradas. Ejecutar primero: ./scripts/01-setup-environment.sh"
    exit 1
fi

echo ""
echo "🏗️ Creando Virtual Network..."

# Crear VNet principal
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --address-prefix "10.0.0.0/16" \
  --location $LOCATION \
  --tags \
    Project=$PROJECT_NAME \
    Environment=$ENVIRONMENT \
    Purpose="Main-Network" \
  --output table

success "Virtual Network creada: vnet-$PROJECT_NAME-$ENVIRONMENT"

echo ""
echo "🔧 Creando subnets especializadas..."

# Subnet para Container Apps
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --name "subnet-containerapp" \
  --address-prefix "10.0.2.0/24" \
  --output table

success "Subnet Container Apps: 10.0.2.0/24 (254 IPs)"

# Subnet para Application Gateway
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --name "subnet-appgateway" \
  --address-prefix "10.0.1.0/24" \
  --output table

success "Subnet Application Gateway: 10.0.1.0/24 (254 IPs)"

# Subnet para Database (para futuro Private Endpoint)
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --name "subnet-database" \
  --address-prefix "10.0.3.0/24" \
  --output table

success "Subnet Database: 10.0.3.0/24 (254 IPs)"

echo ""
echo "🔐 Creando Network Security Groups..."

# NSG para Container Apps
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name "nsg-containerapp-$ENVIRONMENT" \
  --location $LOCATION \
  --tags \
    Project=$PROJECT_NAME \
    Environment=$ENVIRONMENT \
    Purpose="Container-Security" \
  --output table

# NSG para Application Gateway
az network nsg create \
  --resource-group $RESOURCE_GROUP \
  --name "nsg-appgateway-$ENVIRONMENT" \
  --location $LOCATION \
  --tags \
    Project=$PROJECT_NAME \
    Environment=$ENVIRONMENT \
    Purpose="AppGateway-Security" \
  --output table

success "NSGs creados"

echo ""
echo "🛡️ Configurando reglas de seguridad..."

# Reglas para Application Gateway NSG
info "Configurando reglas para Application Gateway..."

az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name "nsg-appgateway-$ENVIRONMENT" \
  --name "AllowHTTPS" \
  --priority 100 \
  --protocol Tcp \
  --source-address-prefixes "*" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 443 \
  --access Allow \
  --direction Inbound \
  --description "Allow HTTPS traffic from internet"

az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name "nsg-appgateway-$ENVIRONMENT" \
  --name "AllowHTTP" \
  --priority 110 \
  --protocol Tcp \
  --source-address-prefixes "*" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 80 \
  --access Allow \
  --direction Inbound \
  --description "Allow HTTP traffic from internet"

# Gateway Manager traffic (required for App Gateway)
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name "nsg-appgateway-$ENVIRONMENT" \
  --name "AllowGatewayManager" \
  --priority 120 \
  --protocol Tcp \
  --source-address-prefixes "GatewayManager" \
  --source-port-ranges "*" \
  --destination-address-prefixes "*" \
  --destination-port-ranges 65200-65535 \
  --access Allow \
  --direction Inbound \
  --description "Allow Azure Gateway Manager"

success "Reglas Application Gateway configuradas"

# Reglas para Container Apps NSG
info "Configurando reglas para Container Apps..."

az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name "nsg-containerapp-$ENVIRONMENT" \
  --name "AllowFromAppGateway" \
  --priority 100 \
  --protocol Tcp \
  --source-address-prefixes "10.0.1.0/24" \
  --source-port-ranges "*" \
  --destination-address-prefixes "10.0.2.0/24" \
  --destination-port-ranges 80 443 \
  --access Allow \
  --direction Inbound \
  --description "Allow traffic from Application Gateway subnet"

# Permitir tráfico interno entre Container Apps
az network nsg rule create \
  --resource-group $RESOURCE_GROUP \
  --nsg-name "nsg-containerapp-$ENVIRONMENT" \
  --name "AllowInternalTraffic" \
  --priority 110 \
  --protocol "*" \
  --source-address-prefixes "10.0.2.0/24" \
  --source-port-ranges "*" \
  --destination-address-prefixes "10.0.2.0/24" \
  --destination-port-ranges "*" \
  --access Allow \
  --direction Inbound \
  --description "Allow internal communication between containers"

success "Reglas Container Apps configuradas"

echo ""
echo "🔗 Asociando NSGs con subnets..."

# Asociar NSG con subnet de Application Gateway
az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --name "snet-appgateway" \
  --network-security-group "nsg-appgateway-$ENVIRONMENT" \
  --output table

# Asociar NSG con subnet de Container Apps
az network vnet subnet update \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --name "snet-containerapp" \
  --network-security-group "nsg-containerapp-$ENVIRONMENT" \
  --output table

success "NSGs asociados con subnets"

echo ""
echo "🔍 Verificando configuración de red..."

# Mostrar resumen de la configuración
echo "📋 RESUMEN DE NETWORKING:"
az network vnet subnet list \
  --resource-group $RESOURCE_GROUP \
  --vnet-name "vnet-$PROJECT_NAME-$ENVIRONMENT" \
  --query '[].{Subnet:name, AddressPrefix:addressPrefix, NSG:networkSecurityGroup.id}' \
  --output table

# Guardar información de red para otros scripts
echo "export VNET_NAME=\"vnet-$PROJECT_NAME-$ENVIRONMENT\"" >> /tmp/cli-vars.env
echo "export CONTAINER_SUBNET=\"subnet-containerapp\"" >> /tmp/cli-vars.env
echo "export APPGW_SUBNET=\"subnet-appgateway\"" >> /tmp/cli-vars.env

echo ""
success "🎉 NETWORKING COMPLETADO!"
info "Próximo paso: ./scripts/03-create-database.sh"
echo ""
