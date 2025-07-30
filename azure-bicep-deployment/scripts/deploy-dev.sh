#!/bin/bash

# ============================================================================
# BICEP Deployment Script for Development Environment
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
RESOURCE_GROUP_NAME="rg-paymentapp-dev"
LOCATION="eastus"
DEPLOYMENT_NAME="payment-app-$(date +%Y%m%d-%H%M%S)"
TEMPLATE_FILE="main.bicep"
PARAMETERS_FILE="parameters/dev-parameters.json"

echo -e "${BLUE}=== BICEP Deployment Script - Development Environment ===${NC}"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo -e "${RED}❌ Error: Azure CLI is not installed${NC}"
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Azure. Please login...${NC}"
    az login
fi

# Show current subscription
SUBSCRIPTION=$(az account show --query name -o tsv)
echo -e "${BLUE}📋 Current subscription: ${SUBSCRIPTION}${NC}"

# Create resource group if it doesn't exist
echo -e "${YELLOW}🔍 Checking if resource group exists...${NC}"
if ! az group show --name $RESOURCE_GROUP_NAME &> /dev/null; then
    echo -e "${YELLOW}📦 Creating resource group: $RESOURCE_GROUP_NAME${NC}"
    az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
    echo -e "${GREEN}✅ Resource group created successfully${NC}"
else
    echo -e "${GREEN}✅ Resource group already exists${NC}"
fi

# Validate the template
echo -e "${YELLOW}🔍 Validating BICEP template...${NC}"
az deployment group validate \
    --resource-group $RESOURCE_GROUP_NAME \
    --template-file $TEMPLATE_FILE \
    --parameters @$PARAMETERS_FILE

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Template validation successful${NC}"
else
    echo -e "${RED}❌ Template validation failed${NC}"
    exit 1
fi

# Deploy the template
echo -e "${YELLOW}🚀 Deploying BICEP template...${NC}"
echo -e "${BLUE}   Resource Group: $RESOURCE_GROUP_NAME${NC}"
echo -e "${BLUE}   Template: $TEMPLATE_FILE${NC}"
echo -e "${BLUE}   Parameters: $PARAMETERS_FILE${NC}"
echo -e "${BLUE}   Deployment Name: $DEPLOYMENT_NAME${NC}"
echo ""

az deployment group create \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $DEPLOYMENT_NAME \
    --template-file $TEMPLATE_FILE \
    --parameters @$PARAMETERS_FILE \
    --verbose

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    
    # Show deployment outputs
    echo -e "${YELLOW}📋 Deployment outputs:${NC}"
    az deployment group show \
        --resource-group $RESOURCE_GROUP_NAME \
        --name $DEPLOYMENT_NAME \
        --query properties.outputs
        
    echo ""
    echo -e "${BLUE}🔗 Access URLs:${NC}"
    APP_GATEWAY_URL=$(az deployment group show \
        --resource-group $RESOURCE_GROUP_NAME \
        --name $DEPLOYMENT_NAME \
        --query 'properties.outputs.accessUrls.value.applicationGateway' -o tsv)
        
    CONTAINER_APP_URL=$(az deployment group show \
        --resource-group $RESOURCE_GROUP_NAME \
        --name $DEPLOYMENT_NAME \
        --query 'properties.outputs.accessUrls.value.containerAppDirect' -o tsv)
    
    echo -e "${GREEN}   Application Gateway: $APP_GATEWAY_URL${NC}"
    echo -e "${GREEN}   Container App Direct: $CONTAINER_APP_URL${NC}"
    
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}=== Deployment Complete ===${NC}"
