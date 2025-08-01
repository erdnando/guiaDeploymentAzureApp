# Guía de Acceso Remoto a PostgreSQL en Azure

## Introducción

Esta guía describe la configuración de acceso remoto seguro a bases de datos PostgreSQL desplegadas en Azure Database for PostgreSQL.

### Prerrequisitos

- Azure Database for PostgreSQL desplegado
- Azure CLI instalado y configurado
- Permisos de administrador en la base de datos

## Configuración de Firewall

### Reglas de Firewall a Nivel de Servidor

#### Permitir IPs Específicas

```bash
# Agregar IP específica
az postgres server firewall-rule create \
  --resource-group "rg-production" \
  --server-name "postgresql-prod-server" \
  --name "allow-office-ip" \
  --start-ip-address "203.0.113.1" \
  --end-ip-address "203.0.113.1"
```

#### Permitir Servicios Azure

```bash
# Permitir acceso desde servicios Azure
az postgres server firewall-rule create \
  --resource-group "rg-production" \
  --server-name "postgresql-prod-server" \
  --name "AllowAllAzureIps" \
  --start-ip-address "0.0.0.0" \
  --end-ip-address "0.0.0.0"
```

### Configuración por Ambiente

#### Desarrollo
- Oficinas corporativas: 203.0.113.0/24
- VPN corporativa: 10.0.0.0/16
- Desarrolladores remotos: IPs específicas
- Azure Services: Habilitado

#### Producción
- Solo aplicaciones Azure: Azure Services únicamente
- Acceso administrativo: IPs corporativas específicas
- Sin acceso público directo

## Configuración de Autenticación

### Crear Usuario de Solo Lectura

```sql
-- Crear usuario de solo lectura
CREATE USER readonly_user WITH PASSWORD 'SecurePassword123!';

-- Permisos de solo lectura
GRANT CONNECT ON DATABASE production_db TO readonly_user;
GRANT USAGE ON SCHEMA public TO readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;
```

### Crear Usuario de Aplicación

```sql
-- Crear usuario para aplicación
CREATE USER app_user WITH PASSWORD 'AppPassword456!';

-- Permisos de aplicación
GRANT CONNECT ON DATABASE production_db TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
```

## Conexión desde Aplicaciones Externas

### Cadenas de Conexión

#### .NET Core
```csharp
"ConnectionStrings": {
  "DefaultConnection": "Host=postgresql-prod-server.postgres.database.azure.com;Database=production_db;Username=app_user@postgresql-prod-server;Password=AppPassword456!;SslMode=Require"
}
```

#### Node.js
```javascript
const sequelize = new Sequelize('production_db', 'app_user@postgresql-prod-server', 'AppPassword456!', {
  host: 'postgresql-prod-server.postgres.database.azure.com',
  dialect: 'postgres',
  port: 5432,
  dialectOptions: {
    ssl: { require: true, rejectUnauthorized: false }
  }
});
```

#### Python
```python
import psycopg2

connection = psycopg2.connect(
    host="postgresql-prod-server.postgres.database.azure.com",
    database="production_db",
    user="app_user@postgresql-prod-server",
    password="AppPassword456!",
    port=5432,
    sslmode="require"
)
```

### Herramientas de Administración

#### pgAdmin 4
- Host: postgresql-prod-server.postgres.database.azure.com
- Port: 5432
- Username: admin_user@postgresql-prod-server
- SSL Mode: Require

#### DBeaver
- Server: postgresql-prod-server.postgres.database.azure.com
- Database: production_db
- SSL: Use SSL = true, SSL Mode = require

## Configuración SSL/TLS

### Forzar Conexiones SSL

```bash
# Habilitar SSL requerido
az postgres server update \
  --resource-group "rg-production" \
  --name "postgresql-prod-server" \
  --ssl-enforcement Enabled \
  --minimal-tls-version TLS1_2
```

## Monitoreo y Logging

### Habilitar Logging

```bash
# Habilitar logging de conexiones
az postgres server configuration set \
  --resource-group "rg-production" \
  --server-name "postgresql-prod-server" \
  --name "log_connections" \
  --value "ON"

# Habilitar logging de desconexiones
az postgres server configuration set \
  --resource-group "rg-production" \
  --server-name "postgresql-prod-server" \
  --name "log_disconnections" \
  --value "ON"
```

### Alertas de Monitoreo

#### Conexiones Fallidas
```bash
az monitor metrics alert create \
  --name "PostgreSQL Failed Connections" \
  --resource-group "rg-production" \
  --condition "count 'Failed Connections' > 10" \
  --window-size "5m"
```

## Troubleshooting

### Problemas Comunes

#### Error de Conexión Timeout
**Síntomas:** `psql: error: could not connect to server: Operation timed out`

**Soluciones:**
1. Verificar reglas de firewall
2. Verificar conectividad de red
3. Verificar estado del servidor

#### Error de Autenticación
**Síntomas:** `FATAL: password authentication failed for user`

**Soluciones:**
1. Verificar formato del usuario (usuario@servidor)
2. Verificar contraseña en Key Vault
3. Verificar permisos del usuario

#### Error SSL
**Síntomas:** `FATAL: SSL connection is required`

**Solución:** Agregar parámetro SSL a la conexión

### Test de Conectividad

```bash
#!/bin/bash
# Test de conectividad básico

SERVER="postgresql-prod-server.postgres.database.azure.com"
PORT="5432"

echo "Testing connectivity to $SERVER:$PORT"

if timeout 5 bash -c "</dev/tcp/$SERVER/$PORT"; then
    echo "✓ TCP connection successful"
else
    echo "✗ TCP connection failed"
fi
```

## Automatización

### Script de Configuración

```bash
#!/bin/bash
# setup-postgres-remote-access.sh

RESOURCE_GROUP="rg-production"
SERVER_NAME="postgresql-prod-server"

# Agregar regla de firewall
az postgres server firewall-rule create \
    --resource-group "$RESOURCE_GROUP" \
    --server-name "$SERVER_NAME" \
    --name "allow-office-ip" \
    --start-ip-address "203.0.113.1" \
    --end-ip-address "203.0.113.1"

# Habilitar SSL
az postgres server update \
    --resource-group "$RESOURCE_GROUP" \
    --name "$SERVER_NAME" \
    --ssl-enforcement Enabled

echo "PostgreSQL remote access configuration completed!"
```

## Mejores Prácticas de Seguridad

### Principio de Menor Privilegio

```sql
-- Crear roles específicos
CREATE ROLE app_read_only;
GRANT CONNECT ON DATABASE production_db TO app_read_only;
GRANT USAGE ON SCHEMA public TO app_read_only;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_read_only;

-- Asignar usuarios a roles
GRANT app_read_only TO readonly_user;
```

### Segregación de Ambientes

- **Desarrollo:** Acceso amplio para desarrolladores, datos de prueba
- **Staging:** Acceso limitado a CI/CD, subset de producción
- **Producción:** Solo aplicaciones y administradores, datos reales

### Backup y Recovery

```bash
#!/bin/bash
# Backup con cifrado

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="backup_${BACKUP_DATE}.sql.gz.enc"

# Crear backup cifrado
PGPASSWORD="$DB_PASSWORD" pg_dump \
    -h postgresql-prod-server.postgres.database.azure.com \
    -U backup_user@postgresql-prod-server \
    -d production_db \
    | gzip \
    | openssl enc -aes-256-cbc -salt -k "$ENCRYPTION_KEY" \
    > "$BACKUP_FILE"

echo "Backup completed: $BACKUP_FILE"
```

---

**Documentación generada:** $(date)  
**Versión:** 1.0  
**Próxima revisión:** $(date -d '+1 month')
