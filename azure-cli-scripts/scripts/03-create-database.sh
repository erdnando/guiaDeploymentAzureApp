#!/bin/bash

# 🎯 Script 03: Create Database - Payment System CLI  
# Crea PostgreSQL Flexible Server con configuración de seguridad

set -e

echo "🗄️ FASE 2: DATABASE POSTGRESQL"
echo "=============================="
echo ""

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
    error "Variables no encontradas. Ejecutar primero scripts anteriores"
    exit 1
fi

echo ""
echo "🗄️ Creando PostgreSQL Flexible Server..."

# Crear PostgreSQL server
info "Configuración: Standard_B1ms, 1 vCore, 2GB RAM, 32GB storage"
az postgres flexible-server create \
  --resource-group $RESOURCE_GROUP \
  --name "$DB_SERVER_NAME" \
  --location $LOCATION \
  --admin-user $DB_ADMIN_USER \
  --admin-password $DB_ADMIN_PASSWORD \
  --sku-name Standard_B1ms \
  --tier Burstable \
  --version 14 \
  --storage-size 32 \
  --backup-retention 7 \
  --geo-redundant-backup Disabled \
  --tags \
    Project=$PROJECT_NAME \
    Environment=$ENVIRONMENT \
    Purpose="Payment-Database" \
  --output table

success "PostgreSQL server creado: $DB_SERVER_NAME"

echo ""
echo "🔥 Configurando firewall de PostgreSQL..."

# Permitir acceso desde Container Apps subnet
info "Permitiendo acceso desde Container Apps (10.0.1.0/24)..."
az postgres flexible-server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --name "$DB_SERVER_NAME" \
  --rule-name "AllowContainerApps" \
  --start-ip-address "10.0.1.0" \
  --end-ip-address "10.0.1.255" \
  --output table

# Permitir acceso temporal desde tu IP para configuración inicial
MY_IP=$(curl -s ifconfig.me 2>/dev/null || echo "0.0.0.0")
if [ "$MY_IP" != "0.0.0.0" ]; then
    info "Permitiendo acceso temporal desde tu IP: $MY_IP"
    az postgres flexible-server firewall-rule create \
      --resource-group $RESOURCE_GROUP \
      --name "$DB_SERVER_NAME" \
      --rule-name "AllowMyIP" \
      --start-ip-address $MY_IP \
      --end-ip-address $MY_IP \
      --output table
else
    warning "No se pudo obtener tu IP pública - configurar manualmente si es necesario"
fi

success "Firewall configurado"

echo ""
echo "💾 Creando databases de aplicación..."

# Database para Payment Service
info "Creando database: payments"
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name "$DB_SERVER_NAME" \
  --database-name "payments" \
  --output table

# Database para Order Service
info "Creando database: orders"
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name "$DB_SERVER_NAME" \
  --database-name "orders" \
  --output table

# Database para User Service
info "Creando database: users"
az postgres flexible-server db create \
  --resource-group $RESOURCE_GROUP \
  --server-name "$DB_SERVER_NAME" \
  --database-name "users" \
  --output table

success "Databases de aplicación creadas"

echo ""
echo "🔍 Verificando configuración PostgreSQL..."

# Obtener información del servidor
DB_HOST=$(az postgres flexible-server show \
  --resource-group $RESOURCE_GROUP \
  --name "$DB_SERVER_NAME" \
  --query fullyQualifiedDomainName \
  --output tsv)

DB_STATE=$(az postgres flexible-server show \
  --resource-group $RESOURCE_GROUP \
  --name "$DB_SERVER_NAME" \
  --query state \
  --output tsv)

echo "📋 INFORMACIÓN DE LA DATABASE:"
echo "   Server Name: $DB_SERVER_NAME"
echo "   Host: $DB_HOST"
echo "   Admin User: $DB_ADMIN_USER"
echo "   State: $DB_STATE"
echo "   Version: PostgreSQL 13"
echo "   SSL: Required (default)"
echo ""
echo "   Databases disponibles:"
az postgres flexible-server db list \
  --resource-group $RESOURCE_GROUP \
  --server-name "$DB_SERVER_NAME" \
  --query '[].name' \
  --output table

echo ""
echo "🔌 Probando conectividad..."

# Test básico de conectividad si psql está disponible
if command -v psql &> /dev/null; then
    info "Probando conexión con psql..."
    if PGPASSWORD=$DB_ADMIN_PASSWORD psql \
      -h $DB_HOST \
      -U $DB_ADMIN_USER \
      -d postgres \
      -c "SELECT version();" \
      --set=sslmode=require \
      -t \
      -A 2>/dev/null; then
        success "Conexión PostgreSQL exitosa"
    else
        warning "Conexión falló - verificar firewall rules o credenciales"
    fi
else
    info "psql no disponible - conexión será verificada por las aplicaciones"
fi

# Crear connection strings para las aplicaciones
echo ""
info "📝 Creando connection strings..."

cat > /tmp/connection-strings.env << EOF
# Connection strings para aplicaciones
export DB_HOST="$DB_HOST"
export PAYMENTS_DB_URL="postgresql://$DB_ADMIN_USER:$DB_ADMIN_PASSWORD@$DB_HOST:5432/payments?sslmode=require"
export ORDERS_DB_URL="postgresql://$DB_ADMIN_USER:$DB_ADMIN_PASSWORD@$DB_HOST:5432/orders?sslmode=require"
export USERS_DB_URL="postgresql://$DB_ADMIN_USER:$DB_ADMIN_PASSWORD@$DB_HOST:5432/users?sslmode=require"
EOF

success "Connection strings guardadas en /tmp/connection-strings.env"

# Guardar información de database para otros scripts
echo "export DB_HOST=\"$DB_HOST\"" >> /tmp/cli-vars.env
echo "export PAYMENTS_DB_URL=\"postgresql://$DB_ADMIN_USER:$DB_ADMIN_PASSWORD@$DB_HOST:5432/payments?sslmode=require\"" >> /tmp/cli-vars.env
echo "export ORDERS_DB_URL=\"postgresql://$DB_ADMIN_USER:$DB_ADMIN_PASSWORD@$DB_HOST:5432/orders?sslmode=require\"" >> /tmp/cli-vars.env
echo "export USERS_DB_URL=\"postgresql://$DB_ADMIN_USER:$DB_ADMIN_PASSWORD@$DB_HOST:5432/users?sslmode=require\"" >> /tmp/cli-vars.env

echo ""
success "🎉 DATABASE COMPLETADA!"
info "Próximo paso: ./scripts/04-create-container-env.sh"
echo ""
