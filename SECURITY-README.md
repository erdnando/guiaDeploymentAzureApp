# 🔒 GUÍA DE SEGURIDAD - CRÍTICO LEER ANTES DE SUBIR A GITHUB

## ⚠️ VULNERABILIDADES ENCONTRADAS Y SOLUCIONADAS

### 🚨 ARCHIVOS CON DATOS SENSIBLES IDENTIFICADOS

**1. Contraseñas en texto plano:**
- ❌ `azure-cli-scripts/parameters/dev.env` contiene `DB_ADMIN_PASSWORD="P@ssw0rd123!"`
- ❌ Múltiples scripts exponen contraseñas en variables de entorno

**2. Archivos temporales con credenciales:**
- ❌ `/tmp/cli-vars.env` - contiene todas las credenciales
- ❌ `/tmp/connection-strings.env` - contiene connection strings con passwords

**3. Keys de Application Insights expuestas:**
- ❌ Scripts muestran instrumentation keys en logs

## ✅ SOLUCIONES IMPLEMENTADAS

### 1. `.gitignore` Completo
- 🔒 Excluye todos los archivos `.env`
- 🔒 Excluye archivos temporales `/tmp/`
- 🔒 Excluye archivos con secretos y credenciales
- 🔒 Excluye archivos de backup `.bak`

### 2. Template de Variables de Entorno Seguro
Crear `dev.env.template` sin contraseñas reales:

```bash
# Variables de entorno para desarrollo
# Copiar a dev.env y personalizar

export PROJECT_NAME="PaymentSystem"
export ENVIRONMENT="dev"
export LOCATION="canadacentral"
export RESOURCE_GROUP="rg-\${PROJECT_NAME}-\${ENVIRONMENT}"

# ⚠️ CAMBIAR ESTAS CREDENCIALES
export DB_ADMIN_USER="pgadmin"
export DB_ADMIN_PASSWORD="CHANGE_ME_STRONG_PASSWORD"

# Placeholder images
export CONTAINER_IMAGE="nginx:latest"
export APP_PORT="80"
```

## 🛡️ PASOS ANTES DE COMMIT/PUSH

### ✅ CHECKLIST DE SEGURIDAD

1. **Verificar .gitignore está funcionando:**
```bash
git status
# NO debe aparecer:
# - dev.env, prod.env, local.env
# - archivos en /tmp/
# - archivos .bak
# - archivos con *secret*, *credential*
```

2. **Remover datos sensibles del historial:**
```bash
# Si ya commitaste archivos sensibles:
git filter-branch --force --index-filter \
'git rm --cached --ignore-unmatch azure-cli-scripts/parameters/dev.env' \
--prune-empty --tag-name-filter cat -- --all
```

3. **Verificar no hay contraseñas hardcodeadas:**
```bash
# Buscar posibles contraseñas
grep -r -i "password\|secret\|key" . --exclude-dir=.git
grep -r "P@ssw0rd\|123\|admin" . --exclude-dir=.git
```

## 🔧 CONFIGURACIÓN SEGURA PARA USUARIOS

### 1. Configuración Inicial Segura
```bash
# 1. Clonar el repositorio
git clone <repo-url>
cd GuiaAzureApp

# 2. Crear archivo de variables local (NO subir a git)
cp azure-cli-scripts/parameters/dev.env.template azure-cli-scripts/parameters/dev.env

# 3. Editar con contraseñas reales
vim azure-cli-scripts/parameters/dev.env
# CAMBIAR: DB_ADMIN_PASSWORD="TU_PASSWORD_SEGURO"

# 4. Verificar que no se sube a git
git status  # dev.env NO debe aparecer
```

### 2. Generación de Contraseñas Seguras
```bash
# Generar password seguro para BD
openssl rand -base64 32

# O usar pwgen si está disponible
pwgen -s 32 1
```

### 3. Mejores Prácticas en Producción

**🔒 Para Producción, usar Azure Key Vault:**
```bash
# Crear Key Vault
az keyvault create --name "kv-paymentsys-prod" --resource-group "rg-prod"

# Guardar secretos
az keyvault secret set --vault-name "kv-paymentsys-prod" \
  --name "db-admin-password" --value "PASSWORD_SEGURO"

# Usar en scripts
DB_PASSWORD=$(az keyvault secret show --vault-name "kv-paymentsys-prod" \
  --name "db-admin-password" --query value -o tsv)
```

## 🚫 QUÉ NUNCA HACER

### ❌ NUNCA subir estos archivos:
- `dev.env`, `prod.env`, `local.env`
- Archivos en `/tmp/` con credenciales
- Connection strings con passwords
- Application Insights keys
- Archivos `.bak` con datos sensibles

### ❌ NUNCA poner en código:
- Contraseñas hardcodeadas
- Connection strings con credenciales
- API keys o tokens
- Nombres de usuario y password en el mismo archivo

## 🔍 AUDITORÍA CONTINUA

### Scripts de Verificación
```bash
# Verificar archivos sensibles antes de commit
./azure-cli-scripts/scripts/security-check.sh

# Verificar logs no expongan secretos
grep -i "password\|secret" logs/*.log
```

### Hooks de Git Recomendados
```bash
# Crear pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Verificar que no se suben archivos sensibles
if git diff --cached --name-only | grep -E "\.(env|bak)$|/tmp/"; then
    echo "❌ ERROR: Intentando subir archivos sensibles!"
    echo "Archivos detectados:"
    git diff --cached --name-only | grep -E "\.(env|bak)$|/tmp/"
    exit 1
fi
EOF

chmod +x .git/hooks/pre-commit
```

## 📞 EN CASO DE EXPOSICIÓN ACCIDENTAL

Si accidentalmente subiste credenciales:

1. **CAMBIAR INMEDIATAMENTE las contraseñas expuestas**
2. **Rotar todos los secretos comprometidos**
3. **Limpiar historial de Git:**
```bash
git filter-branch --force --index-filter \
'git rm --cached --ignore-unmatch ARCHIVO_SENSIBLE' \
--prune-empty --tag-name-filter cat -- --all

git push origin --force --all
```
4. **Verificar Azure Portal** para detectar accesos no autorizados

## ✅ VALIDACIÓN FINAL

Antes de hacer push, ejecuta:
```bash
# 1. Verificar .gitignore funciona
git status | grep -E "\.env|/tmp/|\.bak" && echo "❌ ARCHIVOS SENSIBLES DETECTADOS" || echo "✅ OK"

# 2. Verificar no hay passwords en staged files
git diff --cached | grep -i "password\|secret" && echo "❌ CREDENCIALES EN COMMIT" || echo "✅ OK"

# 3. Verificar tamaño del repositorio
du -sh .git/
```

---
**🔒 Recuerda: La seguridad es responsabilidad de todos. Un solo archivo expuesto puede comprometer todo el sistema.**
