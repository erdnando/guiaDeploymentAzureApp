#!/bin/bash

# 🔍 TERRAFORM VALIDATION SCRIPT - Azure Policy Compliance
# Verifica compliance con políticas antes del deployment

echo "🔍 VALIDACIÓN TERRAFORM - AZURE POLICY COMPLIANCE"
echo "================================================"
echo ""

# Colores para output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
TERRAFORM_DIR="/home/erdnando/proyectos/azure/GuiaAzureApp/azure-terraform-deployment"
VALIDATION_ERRORS=0

echo "${BLUE}📋 Iniciando validación de Azure Policy compliance...${NC}"
echo ""

# Cambiar al directorio de Terraform
cd "$TERRAFORM_DIR" || exit 1

# 1. Verificar sintaxis de Terraform
echo "${BLUE}1️⃣ Validando sintaxis de Terraform...${NC}"
terraform validate
if [ $? -eq 0 ]; then
    echo "${GREEN}✅ Sintaxis de Terraform válida${NC}"
else
    echo "${RED}❌ Errores de sintaxis en Terraform${NC}"
    ((VALIDATION_ERRORS++))
fi
echo ""

# 2. Verificar formato de código
echo "${BLUE}2️⃣ Verificando formato de código...${NC}"
terraform fmt -check=true -recursive
if [ $? -eq 0 ]; then
    echo "${GREEN}✅ Formato de código correcto${NC}"
else
    echo "${YELLOW}⚠️ Código necesita formateo (ejecutar: terraform fmt -recursive)${NC}"
fi
echo ""

# 3. Validar variables de dev
echo "${BLUE}3️⃣ Validando configuración de development...${NC}"
terraform plan \
    -var-file="environments/dev/terraform.tfvars" \
    -refresh=false \
    -detailed-exitcode \
    >/dev/null 2>&1

case $? in
    0)
        echo "${GREEN}✅ Configuración de dev válida - sin cambios${NC}"
        ;;
    1)
        echo "${RED}❌ Error en configuración de dev${NC}"
        ((VALIDATION_ERRORS++))
        ;;
    2)
        echo "${GREEN}✅ Configuración de dev válida - cambios detectados${NC}"
        ;;
esac
echo ""

# 4. Validar variables de prod
echo "${BLUE}4️⃣ Validando configuración de production...${NC}"
terraform plan \
    -var-file="environments/prod/terraform.tfvars" \
    -refresh=false \
    -detailed-exitcode \
    >/dev/null 2>&1

case $? in
    0)
        echo "${GREEN}✅ Configuración de prod válida - sin cambios${NC}"
        ;;
    1)
        echo "${RED}❌ Error en configuración de prod${NC}"
        ((VALIDATION_ERRORS++))
        ;;
    2)
        echo "${GREEN}✅ Configuración de prod válida - cambios detectados${NC}"
        ;;
esac
echo ""

# 5. Verificar Azure Policy compliance en archivos
echo "${BLUE}5️⃣ Verificando Azure Policy compliance...${NC}"

# Verificar tag Project obligatorio
PROJECT_TAG_FOUND=$(grep -r "project.*=" environments/ | wc -l)
if [ "$PROJECT_TAG_FOUND" -gt 0 ]; then
    echo "${GREEN}✅ Azure Policy 'Require a tag on resources': Project tag configurado${NC}"
else
    echo "${RED}❌ Azure Policy 'Require a tag on resources': Project tag faltante${NC}"
    ((VALIDATION_ERRORS++))
fi

# Verificar location canadacentral
LOCATION_CANADA=$(grep -r 'location.*=.*"canadacentral"' environments/ | wc -l)
if [ "$LOCATION_CANADA" -gt 0 ]; then
    echo "${GREEN}✅ Azure Policy 'Allowed locations': canadacentral configurado${NC}"
else
    echo "${RED}❌ Azure Policy 'Allowed locations': location debe ser canadacentral${NC}"
    ((VALIDATION_ERRORS++))
fi

# Verificar que no haya locations no permitidas
INVALID_LOCATIONS=$(grep -r 'location.*=' environments/ | grep -v "canadacentral" | grep -v "var.location" | wc -l)
if [ "$INVALID_LOCATIONS" -eq 0 ]; then
    echo "${GREEN}✅ No se encontraron locations no permitidas${NC}"
else
    echo "${RED}❌ Locations no permitidas encontradas - solo canadacentral está permitido${NC}"
    ((VALIDATION_ERRORS++))
fi
echo ""

# 6. Verificar governance tags en módulos
echo "${BLUE}6️⃣ Verificando governance tags en módulos...${NC}"

# Verificar que todos los módulos tengan common_tags
MODULES_WITH_TAGS=$(find modules/ -name "*.tf" -exec grep -l "common_tags" {} \; | wc -l)
TOTAL_MODULES=$(find modules/ -maxdepth 1 -type d | tail -n +2 | wc -l)

echo "   📊 Módulos con governance tags: $MODULES_WITH_TAGS/$TOTAL_MODULES"

if [ "$MODULES_WITH_TAGS" -eq "$TOTAL_MODULES" ]; then
    echo "${GREEN}✅ Todos los módulos implementan governance tags${NC}"
else
    echo "${RED}❌ Algunos módulos no implementan governance tags${NC}"
    ((VALIDATION_ERRORS++))
fi

# Verificar tags específicos en main.tf
REQUIRED_TAGS=("Project" "Environment" "CostCenter" "Owner" "CreatedBy" "ManagedBy" "Purpose")
for tag in "${REQUIRED_TAGS[@]}"; do
    if grep -q "$tag" main.tf; then
        echo "${GREEN}   ✅ Tag '$tag' encontrado${NC}"
    else
        echo "${RED}   ❌ Tag '$tag' faltante${NC}"
        ((VALIDATION_ERRORS++))
    fi
done
echo ""

# 7. Verificar estructura de módulos
echo "${BLUE}7️⃣ Verificando estructura de módulos...${NC}"

EXPECTED_MODULES=("infrastructure" "postgresql" "monitoring" "container-environment" "container-apps" "application-gateway")
for module in "${EXPECTED_MODULES[@]}"; do
    if [ -d "modules/$module" ] && [ -f "modules/$module/main.tf" ]; then
        echo "${GREEN}   ✅ Módulo '$module' existe y tiene main.tf${NC}"
    else
        echo "${RED}   ❌ Módulo '$module' faltante o incompleto${NC}"
        ((VALIDATION_ERRORS++))
    fi
done
echo ""

# 8. Verificar outputs de compliance
echo "${BLUE}8️⃣ Verificando outputs de compliance...${NC}"
if grep -q "compliance_summary" main.tf; then
    echo "${GREEN}✅ Output de compliance_summary encontrado${NC}"
else
    echo "${RED}❌ Output de compliance_summary faltante${NC}"
    ((VALIDATION_ERRORS++))
fi
echo ""

# Resumen final
echo "${BLUE}📋 RESUMEN DE VALIDACIÓN${NC}"
echo "========================"
echo ""

if [ $VALIDATION_ERRORS -eq 0 ]; then
    echo "${GREEN}🎉 VALIDACIÓN EXITOSA${NC}"
    echo "${GREEN}✅ Todos los checks pasaron${NC}"
    echo "${GREEN}✅ Terraform está listo para deployment${NC}"
    echo "${GREEN}✅ Azure Policy compliance verificado${NC}"
    echo ""
    echo "${BLUE}💡 Próximos pasos:${NC}"
    echo "   1. 🚀 Ejecutar deployment con ./scripts/deploy-dev.sh"
    echo "   2. 🧪 Realizar pruebas post-deployment"
    echo "   3. 📊 Verificar compliance en Azure Portal"
    echo ""
    exit 0
else
    echo "${RED}❌ VALIDACIÓN FALLÓ${NC}"
    echo "${RED}🚨 $VALIDATION_ERRORS errores encontrados${NC}"
    echo ""
    echo "${YELLOW}🔧 Acciones requeridas:${NC}"
    echo "   1. 🔍 Revisar los errores arriba"
    echo "   2. 🛠️ Corregir problemas identificados"
    echo "   3. 🔄 Re-ejecutar validación"
    echo ""
    exit 1
fi
