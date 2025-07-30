#!/bin/bash

# 🚀 TERRAFORM DEPLOYMENT SCRIPT - Development Environment
# Azure Policy compliant deployment with governance

echo "🚀 TERRAFORM DEPLOYMENT - DEVELOPMENT"
echo "====================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
ENVIRONMENT="dev"
TERRAFORM_DIR="/home/erdnando/proyectos/azure/GuiaAzureApp/azure-terraform-deployment"
ENV_DIR="$TERRAFORM_DIR/environments/$ENVIRONMENT"

echo "${BLUE}📋 Configuración del Deployment${NC}"
echo "   🏗️ Environment: $ENVIRONMENT"
echo "   📁 Terraform Directory: $TERRAFORM_DIR"
echo "   ⚙️ Variables File: $ENV_DIR/terraform.tfvars"
echo ""

# Verificar Azure CLI login
echo "${BLUE}🔐 Verificando Azure CLI authentication...${NC}"
if ! az account show >/dev/null 2>&1; then
    echo "${RED}❌ No estás autenticado en Azure CLI${NC}"
    echo "   💡 Ejecuta: az login"
    exit 1
fi

ACCOUNT=$(az account show --query name -o tsv)
echo "${GREEN}✅ Azure CLI autenticado: $ACCOUNT${NC}"
echo ""

# Cambiar al directorio de Terraform
cd "$TERRAFORM_DIR" || exit 1

# Terraform Init
echo "${BLUE}🔧 Terraform Init...${NC}"
terraform init
if [ $? -ne 0 ]; then
    echo "${RED}❌ Terraform init falló${NC}"
    exit 1
fi
echo "${GREEN}✅ Terraform inicializado${NC}"
echo ""

# Terraform Plan
echo "${BLUE}📋 Terraform Plan - Verificando cambios...${NC}"
terraform plan \
    -var-file="$ENV_DIR/terraform.tfvars" \
    -out="$ENVIRONMENT.tfplan"

if [ $? -ne 0 ]; then
    echo "${RED}❌ Terraform plan falló${NC}"
    exit 1
fi
echo "${GREEN}✅ Plan completado exitosamente${NC}"
echo ""

# Confirmar deployment
echo "${YELLOW}⚠️ ¿Continuar con el deployment a $ENVIRONMENT? (y/N)${NC}"
read -r response
if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "${YELLOW}⏭️ Deployment cancelado por el usuario${NC}"
    exit 0
fi

# Terraform Apply
echo "${BLUE}🚀 Terraform Apply - Desplegando infraestructura...${NC}"
terraform apply "$ENVIRONMENT.tfplan"

if [ $? -ne 0 ]; then
    echo "${RED}❌ Terraform apply falló${NC}"
    exit 1
fi

echo ""
echo "${GREEN}🎉 DEPLOYMENT COMPLETADO EXITOSAMENTE${NC}"
echo ""

# Mostrar outputs importantes
echo "${BLUE}📊 Información del Deployment:${NC}"
terraform output -json > "$ENVIRONMENT-outputs.json"

# Extraer información clave
RESOURCE_GROUP=$(terraform output -raw resource_group_name 2>/dev/null)
FRONTEND_URL=$(terraform output -raw frontend_url 2>/dev/null)
GATEWAY_IP=$(terraform output -raw application_gateway_public_ip 2>/dev/null)

echo "   📁 Resource Group: $RESOURCE_GROUP"
echo "   🌐 Frontend URL: $FRONTEND_URL"
echo "   🌍 Gateway IP: $GATEWAY_IP"
echo ""

echo "${BLUE}✅ Compliance Status:${NC}"
terraform output compliance_summary

echo ""
echo "${BLUE}💡 Próximos pasos:${NC}"
echo "   1. 🔍 Verificar recursos en Azure Portal"
echo "   2. 🧪 Realizar pruebas de conectividad"
echo "   3. 📊 Monitorear logs en Log Analytics"
echo "   4. 🔒 Configurar CI/CD pipelines"
echo ""
echo "${YELLOW}📝 Archivos generados:${NC}"
echo "   • $ENVIRONMENT.tfplan - Plan de deployment"
echo "   • $ENVIRONMENT-outputs.json - Outputs del deployment"
echo "   • terraform.tfstate - Estado de la infraestructura"
echo ""

# Limpiar plan file
rm -f "$ENVIRONMENT.tfplan"

echo "${GREEN}🎯 Deployment de $ENVIRONMENT completado con compliance Azure Policy${NC}"
