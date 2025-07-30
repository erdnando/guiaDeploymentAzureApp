#!/bin/bash

# ============================================================================
# security-check.sh - Verificación de seguridad antes de commit
# ============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔒 VERIFICACIÓN DE SEGURIDAD - PRE-COMMIT${NC}"
echo "========================================="

ISSUES_FOUND=0

# 1. Verificar archivos .env
echo -e "\n${YELLOW}1. Verificando archivos .env...${NC}"
ENV_FILES=$(find . -name "*.env" -not -name "*.template" -not -path "./.git/*")
if [ -n "$ENV_FILES" ]; then
    # Verificar si están ignorados por git
    UNIGNORED_ENV=""
    while IFS= read -r file; do
        if ! git check-ignore "$file" >/dev/null 2>&1; then
            UNIGNORED_ENV="$UNIGNORED_ENV$file\n"
        fi
    done <<< "$ENV_FILES"
    
    if [ -n "$UNIGNORED_ENV" ]; then
        echo -e "${RED}❌ ARCHIVOS .env NO IGNORADOS POR GIT:${NC}"
        echo -e "$UNIGNORED_ENV"
        echo -e "${YELLOW}💡 Solución: Agregar a .gitignore${NC}"
        ISSUES_FOUND=1
    else
        echo -e "${GREEN}✅ Archivos .env encontrados pero están ignorados por git${NC}"
    fi
else
    echo -e "${GREEN}✅ No se encontraron archivos .env${NC}"
fi

# 2. Verificar archivos temporales
echo -e "\n${YELLOW}2. Verificando archivos temporales...${NC}"
if find . -path "*/tmp/*" -o -name "*.tmp" -o -name "*.bak" | grep -q .; then
    echo -e "${RED}❌ ARCHIVOS TEMPORALES ENCONTRADOS:${NC}"
    find . -path "*/tmp/*" -o -name "*.tmp" -o -name "*.bak"
    echo -e "${YELLOW}💡 Solución: Eliminar o agregar a .gitignore${NC}"
    ISSUES_FOUND=1
else
    echo -e "${GREEN}✅ No se encontraron archivos temporales${NC}"
fi

# 3. Verificar contraseñas hardcodeadas
echo -e "\n${YELLOW}3. Verificando contraseñas hardcodeadas...${NC}"
DANGEROUS_PATTERNS=$(grep -r -i "P@ssw0rd123" . --exclude-dir=.git --exclude-dir=.terraform --exclude="*.md" --exclude="security-check.sh" | while read line; do
    file=$(echo "$line" | cut -d: -f1)
    if ! git check-ignore "$file" >/dev/null 2>&1; then
        echo "$line"
    fi
done)

if [ -n "$DANGEROUS_PATTERNS" ]; then
    echo -e "${RED}❌ CONTRASEÑAS REALES EN ARCHIVOS NO IGNORADOS:${NC}"
    echo "$DANGEROUS_PATTERNS"
    echo -e "${YELLOW}💡 Solución: Mover a archivos .env (ignorados) o usar Azure Key Vault${NC}"
    ISSUES_FOUND=1
else
    echo -e "${GREEN}✅ No se encontraron contraseñas reales en archivos que se subirán${NC}"
    echo -e "${BLUE}ℹ️ Archivos .env están ignorados por git${NC}"
fi

# 4. Verificar secretos expuestos
echo -e "\n${YELLOW}4. Verificando secretos expuestos...${NC}"
# Buscar claves/tokens reales, no referencias a Key Vault
DANGEROUS_SECRETS=$(grep -r -E "(secret|key|token).*[\"'][a-zA-Z0-9+/]{40,}[\"']" . --exclude-dir=.git --exclude-dir=.terraform --exclude="*.md" --exclude="security-check.sh" | grep -v "azurerm_key_vault" | grep -v "secretName" | grep -v "secretRef" || true)
if [ -n "$DANGEROUS_SECRETS" ]; then
    echo -e "${RED}❌ POSIBLES SECRETOS REALES EXPUESTOS:${NC}"
    echo "$DANGEROUS_SECRETS" | head -3
    echo -e "${YELLOW}💡 Solución: Usar Azure Key Vault${NC}"
    ISSUES_FOUND=1
else
    echo -e "${GREEN}✅ No se encontraron secretos reales expuestos${NC}"
    echo -e "${BLUE}ℹ️ Referencias a Key Vault y nombres de secretos son seguros${NC}"
fi

# 5. Verificar git status
echo -e "\n${YELLOW}5. Verificando git status...${NC}"
if git status --porcelain | grep -E "\.(env|bak|tmp)$" | grep -q .; then
    echo -e "${RED}❌ ARCHIVOS SENSIBLES EN STAGING:${NC}"
    git status --porcelain | grep -E "\.(env|bak|tmp)$"
    echo -e "${YELLOW}💡 Solución: git reset <archivo> y agregar a .gitignore${NC}"
    ISSUES_FOUND=1
else
    echo -e "${GREEN}✅ No hay archivos sensibles en staging${NC}"
fi

# Resultado final
echo -e "\n${BLUE}=========================================${NC}"
if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}🎉 VERIFICACIÓN COMPLETA: SIN PROBLEMAS DE SEGURIDAD${NC}"
    echo -e "${GREEN}✅ Seguro para commit/push${NC}"
    exit 0
else
    echo -e "${RED}🚨 PROBLEMAS DE SEGURIDAD ENCONTRADOS${NC}"
    echo -e "${RED}❌ NO SEGURO para commit/push${NC}"
    echo -e "\n${YELLOW}📋 PASOS SIGUIENTES:${NC}"
    echo "1. Revisar y corregir los problemas listados arriba"
    echo "2. Verificar que .gitignore está configurado correctamente"
    echo "3. Ejecutar este script nuevamente"
    echo "4. Solo entonces hacer commit/push"
    exit 1
fi
