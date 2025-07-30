#!/bin/bash

# ============================================================================
# BICEP Cleanup Script
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

echo -e "${BLUE}=== BICEP Cleanup Script ===${NC}"
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
echo ""

# Confirm deletion
echo -e "${YELLOW}⚠️  This will DELETE the following resource group and ALL its resources:${NC}"
echo -e "${RED}   Resource Group: $RESOURCE_GROUP_NAME${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo ""

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo -e "${BLUE}❌ Operation cancelled${NC}"
    exit 0
fi

# Check if resource group exists
echo -e "${YELLOW}🔍 Checking if resource group exists...${NC}"
if az group show --name $RESOURCE_GROUP_NAME &> /dev/null; then
    echo -e "${YELLOW}🗑️  Deleting resource group: $RESOURCE_GROUP_NAME${NC}"
    echo -e "${YELLOW}   This may take several minutes...${NC}"
    
    az group delete --name $RESOURCE_GROUP_NAME --yes --no-wait
    
    echo -e "${GREEN}✅ Resource group deletion initiated${NC}"
    echo -e "${BLUE}ℹ️  The deletion is running in the background${NC}"
    echo -e "${BLUE}ℹ️  You can check the status in the Azure Portal${NC}"
else
    echo -e "${YELLOW}⚠️  Resource group '$RESOURCE_GROUP_NAME' does not exist${NC}"
fi

echo ""
echo -e "${BLUE}=== Cleanup Complete ===${NC}"
