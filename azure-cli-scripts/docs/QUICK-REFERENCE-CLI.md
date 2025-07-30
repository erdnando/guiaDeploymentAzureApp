# Azure CLI - Referencia Rápida

## 🚀 Comandos Esenciales de Azure CLI

### Autenticación y Configuración
```bash
# Login en Azure
az login

# Listar subscripciones
az account list --output table

# Establecer subscripción por defecto
az account set --subscription "nombre-o-id"

# Verificar subscription actual
az account show

# Configurar location por defecto
az configure --defaults location=canadacentral
```

### Resource Groups
```bash
# Crear resource group
az group create --name "mi-rg" --location "canadacentral"

# Listar resource groups
az group list --output table

# Mostrar detalles de resource group
az group show --name "mi-rg"

# Eliminar resource group
az group delete --name "mi-rg" --yes --no-wait
```

## 🌐 Networking

### Virtual Networks
```bash
# Crear VNet
az network vnet create \
  --name "mi-vnet" \
  --resource-group "mi-rg" \
  --address-prefix "10.0.0.0/16" \
  --subnet-name "default" \
  --subnet-prefix "10.0.1.0/24"

# Crear subnet adicional
az network vnet subnet create \
  --vnet-name "mi-vnet" \
  --name "mi-subnet" \
  --resource-group "mi-rg" \
  --address-prefix "10.0.2.0/24"

# Listar VNets
az network vnet list --resource-group "mi-rg" --output table
```

### Network Security Groups (NSG)
```bash
# Crear NSG
az network nsg create --name "mi-nsg" --resource-group "mi-rg"

# Crear regla NSG
az network nsg rule create \
  --nsg-name "mi-nsg" \
  --resource-group "mi-rg" \
  --name "AllowHTTP" \
  --protocol Tcp \
  --priority 1000 \
  --destination-port-range 80 \
  --access Allow
```

### Public IP
```bash
# Crear Public IP estática
az network public-ip create \
  --name "mi-pip" \
  --resource-group "mi-rg" \
  --allocation-method Static \
  --sku Standard

# Mostrar Public IP
az network public-ip show --name "mi-pip" --resource-group "mi-rg" --query "ipAddress"
```

## 💾 Bases de Datos

### PostgreSQL Flexible Server
```bash
# Crear servidor PostgreSQL
az postgres flexible-server create \
  --name "mi-psql-server" \
  --resource-group "mi-rg" \
  --location "canadacentral" \
  --admin-user "pgadmin" \
  --admin-password "P@ssw0rd123!" \
  --sku-name "Standard_B1ms" \
  --tier "Burstable" \
  --storage-size 32

# Configurar firewall para permitir Azure services
az postgres flexible-server firewall-rule create \
  --name "mi-psql-server" \
  --resource-group "mi-rg" \
  --rule-name "AllowAzureServices" \
  --start-ip-address "0.0.0.0" \
  --end-ip-address "0.0.0.0"

# Conectar a la base de datos
az postgres flexible-server connect \
  --name "mi-psql-server" \
  --admin-user "pgadmin" \
  --database-name "postgres"
```

## 📦 Container Apps

### Container Apps Environment
```bash
# Crear Container Apps Environment
az containerapp env create \
  --name "mi-cae" \
  --resource-group "mi-rg" \
  --location "canadacentral"

# Listar environments
az containerapp env list --resource-group "mi-rg" --output table
```

### Container Apps
```bash
# Crear Container App
az containerapp create \
  --name "mi-app" \
  --resource-group "mi-rg" \
  --environment "mi-cae" \
  --image "nginx:latest" \
  --target-port 80 \
  --ingress external \
  --cpu "0.5" \
  --memory "1Gi" \
  --min-replicas 1 \
  --max-replicas 3

# Actualizar Container App
az containerapp update \
  --name "mi-app" \
  --resource-group "mi-rg" \
  --image "nginx:alpine"

# Obtener URL de la app
az containerapp show \
  --name "mi-app" \
  --resource-group "mi-rg" \
  --query "properties.configuration.ingress.fqdn"

# Ver logs
az containerapp logs show \
  --name "mi-app" \
  --resource-group "mi-rg" \
  --follow
```

## 🚪 Application Gateway

### Crear Application Gateway
```bash
# Crear Application Gateway básico
az network application-gateway create \
  --name "mi-agw" \
  --location "canadacentral" \
  --resource-group "mi-rg" \
  --vnet-name "mi-vnet" \
  --subnet "mi-subnet" \
  --capacity 2 \
  --sku Standard_v2 \
  --http-settings-cookie-based-affinity Disabled \
  --frontend-port 80 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --public-ip-address "mi-pip"

# Ver backend health
az network application-gateway show-backend-health \
  --name "mi-agw" \
  --resource-group "mi-rg"
```

## 📊 Monitoring

### Log Analytics
```bash
# Crear Log Analytics Workspace
az monitor log-analytics workspace create \
  --workspace-name "mi-log-workspace" \
  --resource-group "mi-rg" \
  --location "canadacentral"

# Ejecutar consulta KQL
az monitor log-analytics query \
  --workspace "mi-log-workspace" \
  --analytics-query "ContainerAppConsoleLogs_CL | limit 10"
```

### Application Insights
```bash
# Crear Application Insights
az monitor app-insights component create \
  --app "mi-app-insights" \
  --location "canadacentral" \
  --resource-group "mi-rg" \
  --workspace "/subscriptions/{sub-id}/resourceGroups/mi-rg/providers/Microsoft.OperationalInsights/workspaces/mi-log-workspace"

# Obtener connection string
az monitor app-insights component show \
  --app "mi-app-insights" \
  --resource-group "mi-rg" \
  --query "connectionString"
```

## 🔍 Comandos de Diagnóstico

### Información de Recursos
```bash
# Listar todos los recursos en un RG
az resource list --resource-group "mi-rg" --output table

# Mostrar detalles de un recurso específico
az resource show --ids "/subscriptions/{sub-id}/resourceGroups/mi-rg/providers/Microsoft.App/containerApps/mi-app"

# Ver métricas de un recurso
az monitor metrics list \
  --resource "/subscriptions/{sub-id}/resourceGroups/mi-rg/providers/Microsoft.App/containerApps/mi-app" \
  --metric "Requests" \
  --interval PT1H
```

### Troubleshooting
```bash
# Ver estado de deployment
az deployment group list --resource-group "mi-rg" --output table

# Ver actividad logs
az monitor activity-log list --resource-group "mi-rg" --max-events 10

# Test de conectividad
az network vnet subnet show --vnet-name "mi-vnet" --name "mi-subnet" --resource-group "mi-rg"
```

## 🏷️ Tags y Metadatos

### Gestión de Tags
```bash
# Agregar tags a un resource group
az group update --name "mi-rg" --tags Environment=Dev Project=PaymentSystem

# Agregar tags a un recurso específico
az resource tag --tags Environment=Dev Owner=TeamA \
  --resource-group "mi-rg" \
  --name "mi-app" \
  --resource-type "Microsoft.App/containerApps"

# Buscar recursos por tags
az resource list --tag Environment=Dev --output table
```

## 🔧 Operaciones Avanzadas

### Scaling
```bash
# Escalar Container App manualmente
az containerapp update \
  --name "mi-app" \
  --resource-group "mi-rg" \
  --min-replicas 2 \
  --max-replicas 10

# Ver réplicas activas
az containerapp revision list \
  --name "mi-app" \
  --resource-group "mi-rg" \
  --query "[?properties.active].{Name:name,Replicas:properties.replicas}"
```

### Backup y Restore
```bash
# Backup de configuración (export a ARM template)
az group export --name "mi-rg" > backup-template.json

# Crear snapshot de recursos
az resource list --resource-group "mi-rg" \
  --query "[].{name:name,type:type,location:location}" > resources-snapshot.json
```

## 📋 Formatos de Output

### Opciones de Output
```bash
# Tabla (default, más legible)
az resource list --output table

# JSON (para scripting)
az resource list --output json

# YAML (más legible que JSON)
az resource list --output yaml

# TSV (para procesamiento en scripts)
az resource list --output tsv

# Solo valores específicos con --query
az resource list --query "[].name" --output tsv
```

### JMESPath Queries Útiles
```bash
# Filtrar por tipo de recurso
az resource list --query "[?type=='Microsoft.App/containerApps'].name"

# Obtener solo campos específicos
az resource list --query "[].{Name:name,Type:type,Location:location}"

# Filtrar y contar
az resource list --query "length([?type=='Microsoft.App/containerApps'])"
```

## ⚡ Tips y Trucos

### Variables de Environment
```bash
# Usar variables para evitar repetición
RG_NAME="mi-rg"
LOCATION="canadacentral"

az group create --name "$RG_NAME" --location "$LOCATION"
```

### Ejecución en Paralelo
```bash
# Crear múltiples recursos en paralelo
az containerapp create --name "app1" --resource-group "$RG_NAME" &
az containerapp create --name "app2" --resource-group "$RG_NAME" &
wait  # Esperar a que terminen ambos
```

### Validación antes de ejecución
```bash
# Usar --dry-run cuando esté disponible
az group delete --name "$RG_NAME" --dry-run

# Validar templates
az deployment group validate --resource-group "$RG_NAME" --template-file template.json
```

---

## 🚨 Comandos de Emergencia

### Parar todo rápidamente
```bash
# Escalar todas las Container Apps a 0 réplicas
for app in $(az containerapp list --resource-group "$RG_NAME" --query "[].name" -o tsv); do
  az containerapp update --name "$app" --resource-group "$RG_NAME" --min-replicas 0 --max-replicas 0
done
```

### Limpiar recursos huérfanos
```bash
# Buscar recursos sin tags (posibles huérfanos)
az resource list --query "[?tags==null].{Name:name,Type:type,ResourceGroup:resourceGroup}" --output table
```

### Verificar costs en tiempo real
```bash
# Ver consumption por resource group (requiere permisos)
az consumption usage list --scope "/subscriptions/{subscription-id}/resourceGroups/$RG_NAME"
```

---

**💡 Tip:** Guarda este archivo como referencia rápida. Úsalo junto con `az --help` para obtener información detallada de cualquier comando.
