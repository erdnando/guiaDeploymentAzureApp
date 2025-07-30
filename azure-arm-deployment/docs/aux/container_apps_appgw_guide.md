# Guía Completa: Azure Container Apps + Application Gateway + SQL Server

## Arquitectura objetivo
```
                                   ┌─► Container App (React Frontend)
                                   │
Internet → Application Gateway (WAF)
                                   │
                                   └─► Container App (ASP.NET API) ─► Azure SQL Database
                      ↓
                 VNET Integration
```

## Pre-requisitos
- Suscripción de Azure activa
- Azure CLI instalado
- Docker Desktop (para containerizar la aplicación)
- Visual Studio o VS Code
- Aplicación ASP.NET Core existente

---

## Fase 1: Preparación de la infraestructura base

### 1.1 Crear Resource Group
```bash
# Variables
RESOURCE_GROUP="rg-containerapp-demo"
LOCA### Consideraciones adicionales importantes

### Seguridad
- **Managed Identity:** Usar para conectar Container Apps con otros servicios de Azure
- **Key Vault:** Almacenar connection strings y secretos
- **Network Security Groups:** Configurar reglas específicas
- **CORS en API:** Configurar correctamente para permitir solo orígenes confiables

### Escalabilidad
- **Auto-scaling:** Container Apps escala automáticamente basado en CPU/memoria
- **Application Gateway:** Configurar auto-scaling según tráfico
- **SQL Database:** Considerar DTU auto-scaling
- **Frontend React:** Escala a cero en periodos sin tráfico para optimizar costosUS"
VNET_NAME="vnet-containerapp"
SUBNET_APPGW="subnet-appgw"
SUBNET_CONTAINERAPP="subnet-containerapp"

# Crear resource group
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### 1.2 Crear VNET y Subnets
```bash
# Crear VNET
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --location $LOCATION \
  --address-prefix 10.0.0.0/16

# Subnet para Application Gateway (mínimo /24)
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $SUBNET_APPGW \
  --address-prefix 10.0.1.0/24

# Subnet para Container Apps (mínimo /21)
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name $SUBNET_CONTAINERAPP \
  --address-prefix 10.0.8.0/21
```

---

## Fase 2: Configurar Azure SQL Database

### 2.1 Crear SQL Server y Database
```bash
SQL_SERVER_NAME="sqlserver-containerapp-demo"
SQL_DB_NAME="ProductInventoryDB"
SQL_ADMIN_USER="sqladmin"
SQL_ADMIN_PASSWORD="YourSecurePassword123!"

# Crear SQL Server
az sql server create \
  --name $SQL_SERVER_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --admin-user $SQL_ADMIN_USER \
  --admin-password $SQL_ADMIN_PASSWORD

# Crear Database
az sql db create \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER_NAME \
  --name $SQL_DB_NAME \
  --service-objective Basic \
  --max-size 32GB
```

### 2.2 Configurar Firewall Rules
```bash
# Permitir servicios de Azure
az sql server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER_NAME \
  --name "AllowAzureServices" \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Permitir tu IP para configuración inicial
MY_IP=$(curl -s ifconfig.me)
az sql server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --server $SQL_SERVER_NAME \
  --name "AllowMyIP" \
  --start-ip-address $MY_IP \
  --end-ip-address $MY_IP
```

---

## Fase 3: Containerizar la aplicación ASP.NET

### 3.1 Crear Dockerfile
```dockerfile
# Dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["YourApp.csproj", "."]
RUN dotnet restore "./YourApp.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "YourApp.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "YourApp.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "YourApp.dll"]
```

### 3.2 Configurar appsettings.json
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=sqlserver-containerapp-demo.database.windows.net;Database=ProductInventoryDB;User Id=sqladmin;Password=YourSecurePassword123!;Encrypt=True;TrustServerCertificate=False;"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  },
  "AllowedHosts": "*"
}
```

### 3.3 Opción A: Usar GitHub Container Registry
```bash
# Variables para GitHub Container Registry
GH_USERNAME="tu-usuario-github"
GH_TOKEN="tu-personal-access-token" # Token con permisos de packages:write
GH_REGISTRY="ghcr.io"

# Login a GitHub Container Registry
echo $GH_TOKEN | docker login ghcr.io -u $GH_USERNAME --password-stdin

# Build y tag para imágenes
# API Backend
docker build -t $GH_REGISTRY/$GH_USERNAME/backend-api:latest ./backend/

# Frontend React
docker build -t $GH_REGISTRY/$GH_USERNAME/frontend-react:latest ./frontend/

# Push imágenes
docker push $GH_REGISTRY/$GH_USERNAME/backend-api:latest
docker push $GH_REGISTRY/$GH_USERNAME/frontend-react:latest

# Guardar nombres completos para uso posterior
BACKEND_IMAGE="$GH_REGISTRY/$GH_USERNAME/backend-api:latest"
FRONTEND_IMAGE="$GH_REGISTRY/$GH_USERNAME/frontend-react:latest"
```

### 3.3 Opción B: Crear Azure Container Registry
```bash
ACR_NAME="acrcontainerapp$(date +%s)"

# Crear ACR
az acr create \
  --resource-group $RESOURCE_GROUP \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true

# Obtener credenciales
ACR_USERNAME=$ACR_NAME
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" --output tsv)
```

### 3.4 Build y Push de las imágenes (si usas ACR)
```bash
# Login a ACR
az acr login --name $ACR_NAME

# Build y Push - Backend API
docker build -t $ACR_NAME.azurecr.io/backend-api:latest ./backend/
docker push $ACR_NAME.azurecr.io/backend-api:latest

# Build y Push - Frontend React
docker build -t $ACR_NAME.azurecr.io/frontend-react:latest ./frontend/
docker push $ACR_NAME.azurecr.io/frontend-react:latest

# Guardar nombres completos para uso posterior
BACKEND_IMAGE="$ACR_NAME.azurecr.io/backend-api:latest"
FRONTEND_IMAGE="$ACR_NAME.azurecr.io/frontend-react:latest"
```

---

## Fase 4: Desplegar Container Apps

### 4.1 Crear Container Apps Environment
```bash
CONTAINERAPP_ENV_NAME="env-containerapp-demo"

# Crear environment con VNET integration
az containerapp env create \
  --name $CONTAINERAPP_ENV_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --infrastructure-subnet-resource-id "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/virtualNetworks/$VNET_NAME/subnets/$SUBNET_CONTAINERAPP" \
  --internal-only true
```

### 4.2 Crear Container App para API (.NET Core)
```bash
API_CONTAINERAPP_NAME="app-backend-api"

az containerapp create \
  --name $API_CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPP_ENV_NAME \
  --image "$ACR_NAME.azurecr.io/backend-api:latest" \
  --registry-server "$ACR_NAME.azurecr.io" \
  --registry-username $ACR_NAME \
  --registry-password $ACR_PASSWORD \
  --target-port 8080 \
  --ingress internal \
  --min-replicas 1 \
  --max-replicas 5 \
  --cpu 0.5 \
  --memory 1Gi \
  --env-vars "ConnectionStrings__DefaultConnection=Server=sqlserver-containerapp-demo.database.windows.net;Database=ProductInventoryDB;User Id=sqladmin;Password=YourSecurePassword123!;Encrypt=True;TrustServerCertificate=False;"
```

### 4.3 Crear Container App para Frontend (React)
```bash
FRONTEND_CONTAINERAPP_NAME="app-frontend-react"

az containerapp create \
  --name $FRONTEND_CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPP_ENV_NAME \
  --image "$ACR_NAME.azurecr.io/frontend-react:latest" \
  --registry-server "$ACR_NAME.azurecr.io" \
  --registry-username $ACR_NAME \
  --registry-password $ACR_PASSWORD \
  --target-port 80 \
  --ingress internal \
  --min-replicas 1 \
  --max-replicas 3 \
  --cpu 0.25 \
  --memory 0.5Gi \
  --env-vars "REACT_APP_API_BASE_URL=/api"
```

### 4.4 Obtener FQDN internos
```bash
# Obtener FQDN del API
API_FQDN=$(az containerapp show \
  --name $API_CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

echo "API Container App FQDN: $API_FQDN"

# Obtener FQDN del Frontend
FRONTEND_FQDN=$(az containerapp show \
  --name $FRONTEND_CONTAINERAPP_NAME \
  --resource-group $RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

echo "Frontend Container App FQDN: $FRONTEND_FQDN"
```

---

## Fase 5: Configurar Application Gateway

### 5.1 Crear IP Pública
```bash
APPGW_PUBLIC_IP_NAME="pip-appgw-demo"

az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name $APPGW_PUBLIC_IP_NAME \
  --allocation-method Static \
  --sku Standard
```

### 5.2 Crear Application Gateway
```bash
APPGW_NAME="appgw-containerapp-demo"

az network application-gateway create \
  --name $APPGW_NAME \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --subnet $SUBNET_APPGW \
  --capacity 2 \
  --sku WAF_v2 \
  --public-ip-address $APPGW_PUBLIC_IP_NAME \
  --frontend-port 80 \
  --routing-rule-type Basic
```

### 5.3 Configurar Backend Pools para Container Apps
```bash
# Crear backend pool para API
az network application-gateway address-pool create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "api-backend-pool" \
  --servers $API_FQDN

# Crear backend pool para Frontend
az network application-gateway address-pool create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "frontend-backend-pool" \
  --servers $FRONTEND_FQDN

# Configurar health probe para API
az network application-gateway probe create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "api-health-probe" \
  --protocol Http \
  --host-name-from-http-settings true \
  --path "/api/health" \
  --interval 30 \
  --timeout 30 \
  --threshold 3

# Configurar health probe para Frontend
az network application-gateway probe create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "frontend-health-probe" \
  --protocol Http \
  --host-name-from-http-settings true \
  --path "/" \
  --interval 30 \
  --timeout 30 \
  --threshold 3
```

### 5.4 Configurar HTTP Settings
```bash
# HTTP Settings para API
az network application-gateway http-settings create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "api-http-settings" \
  --port 443 \
  --protocol Https \
  --cookie-based-affinity Disabled \
  --host-name-from-backend-pool true \
  --probe "api-health-probe"

# HTTP Settings para Frontend con cache para activos estáticos
az network application-gateway http-settings create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "frontend-http-settings" \
  --port 443 \
  --protocol Https \
  --cookie-based-affinity Disabled \
  --host-name-from-backend-pool true \
  --probe "frontend-health-probe"
```

### 5.5 Crear Path Maps para Routing
```bash
# Crear URL Path Map
az network application-gateway url-path-map create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "app-routing" \
  --paths "/api/*" \
  --address-pool "api-backend-pool" \
  --http-settings "api-http-settings" \
  --default-address-pool "frontend-backend-pool" \
  --default-http-settings "frontend-http-settings"
```

### 5.6 Configurar regla de routing basada en Path
```bash
# Crear listener HTTP
az network application-gateway http-listener create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "http-listener" \
  --frontend-port appGatewayFrontendPort \
  --frontend-ip appGatewayFrontendIP

# Crear regla de routing
az network application-gateway rule create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "path-based-routing-rule" \
  --rule-type PathBasedRouting \
  --http-listener "http-listener" \
  --url-path-map "app-routing" \
  --priority 100
```

### 5.7 Configurar TLS/SSL (Opcional - requiere un certificado)
```bash
# Para producción, usar un certificado real
# Este ejemplo usa un certificado autofirmado para desarrollo

# Crear certificado autofirmado
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -out appgw.crt -keyout appgw.key -subj "/CN=your-domain.com"
openssl pkcs12 -export -out appgw.pfx -inkey appgw.key -in appgw.crt -passout pass:YourSecurePassword

# Importar certificado al Application Gateway
az network application-gateway ssl-cert create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "appgw-ssl-cert" \
  --cert-file "appgw.pfx" \
  --cert-password "YourSecurePassword"

# Crear listener HTTPS
az network application-gateway http-listener create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "https-listener" \
  --frontend-port 443 \
  --frontend-ip appGatewayFrontendIP \
  --ssl-cert "appgw-ssl-cert"

# Actualizar o crear regla para HTTPS
az network application-gateway rule create \
  --gateway-name $APPGW_NAME \
  --resource-group $RESOURCE_GROUP \
  --name "https-routing-rule" \
  --rule-type PathBasedRouting \
  --http-listener "https-listener" \
  --url-path-map "app-routing" \
  --priority 90
```

---

## Fase 6: Configurar WAF (Web Application Firewall)

### 6.1 Habilitar WAF Policy
```bash
WAF_POLICY_NAME="waf-policy-containerapp"

# Crear WAF Policy
az network application-gateway waf-policy create \
  --resource-group $RESOURCE_GROUP \
  --name $WAF_POLICY_NAME \
  --location $LOCATION

# Aplicar política al Application Gateway
az network application-gateway update \
  --resource-group $RESOURCE_GROUP \
  --name $APPGW_NAME \
  --waf-policy $WAF_POLICY_NAME
```

---

## Fase 7: Testing y Validación

### 7.1 Obtener IP pública del Application Gateway
```bash
APPGW_PUBLIC_IP=$(az network public-ip show \
  --resource-group $RESOURCE_GROUP \
  --name $APPGW_PUBLIC_IP_NAME \
  --query ipAddress \
  --output tsv)

echo "Application Gateway Public IP: $APPGW_PUBLIC_IP"
echo "Test URL: http://$APPGW_PUBLIC_IP"
```

### 7.2 Testing básico
```bash
# Test de conectividad
curl -I http://$APPGW_PUBLIC_IP

# Test con headers detallados
curl -v http://$APPGW_PUBLIC_IP
```

---

## Fase 8: Monitoreo y Troubleshooting

### 8.1 Configurar Log Analytics
```bash
LOG_ANALYTICS_NAME="law-containerapp-demo"

# Crear Log Analytics Workspace
az monitor log-analytics workspace create \
  --resource-group $RESOURCE_GROUP \
  --workspace-name $LOG_ANALYTICS_NAME \
  --location $LOCATION
```

### 8.2 Habilitar diagnósticos
```bash
# Para Application Gateway
az monitor diagnostic-settings create \
  --name "appgw-diagnostics" \
  --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/applicationGateways/$APPGW_NAME" \
  --workspace "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/$LOG_ANALYTICS_NAME" \
  --logs '[{"category":"ApplicationGatewayAccessLog","enabled":true},{"category":"ApplicationGatewayPerformanceLog","enabled":true},{"category":"ApplicationGatewayFirewallLog","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]'

# Para Container Apps
az monitor diagnostic-settings create \
  --name "containerapp-api-diagnostics" \
  --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.App/containerApps/$API_CONTAINERAPP_NAME" \
  --workspace "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/$LOG_ANALYTICS_NAME" \
  --logs '[{"category":"ContainerAppConsoleLogs","enabled":true},{"category":"ContainerAppSystemLogs","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]'

az monitor diagnostic-settings create \
  --name "containerapp-frontend-diagnostics" \
  --resource "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.App/containerApps/$FRONTEND_CONTAINERAPP_NAME" \
  --workspace "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.OperationalInsights/workspaces/$LOG_ANALYTICS_NAME" \
  --logs '[{"category":"ContainerAppConsoleLogs","enabled":true},{"category":"ContainerAppSystemLogs","enabled":true}]' \
  --metrics '[{"category":"AllMetrics","enabled":true}]'
```

### 8.3 Configurar Alertas para Application Gateway y Container Apps
```bash
# Crear grupo de acciones (para notificaciones por email)
az monitor action-group create \
  --name "ag-containerapp-critical" \
  --resource-group $RESOURCE_GROUP \
  --short-name "Critical" \
  --email-receiver name="Admin" email="admin@example.com"

# Alerta para latencia alta en Application Gateway
az monitor metrics alert create \
  --name "appgw-high-latency" \
  --resource-group $RESOURCE_GROUP \
  --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Network/applicationGateways/$APPGW_NAME" \
  --condition "avg LatencyInMilliSeconds > 1000" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Insights/actionGroups/ag-containerapp-critical" \
  --description "Alert when Application Gateway latency is high"

# Alerta para alta utilización de CPU en API Container App
az monitor metrics alert create \
  --name "api-high-cpu" \
  --resource-group $RESOURCE_GROUP \
  --scopes "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.App/containerApps/$API_CONTAINERAPP_NAME" \
  --condition "avg CpuUtilization > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Insights/actionGroups/ag-containerapp-critical" \
  --description "Alert when API CPU usage is high"
```

---

## Consideraciones adicionales importantes

### Seguridad
- **Managed Identity:** Usar para conectar Container Apps con otros servicios de Azure
- **Key Vault:** Almacenar connection strings y secretos
- **Network Security Groups:** Configurar reglas específicas

### Escalabilidad
- **Auto-scaling:** Container Apps escala automáticamente basado en CPU/memoria
- **Application Gateway:** Configurar auto-scaling según tráfico
- **SQL Database:** Considerar DTU auto-scaling

### Costo optimization
- **Container Apps:** Usar escalado a cero para ambientes de desarrollo
- **SQL Database:** Considerar serverless tier para cargas de trabajo variables
- **Application Gateway:** Evaluar SKU según necesidades de tráfico

### Backup y DR
- **SQL Database:** Configurar geo-replication si es crítico
- **Container Images:** Implementar pipelines CI/CD para deployments automatizados
- **Infrastructure as Code:** Usar Bicep/ARM templates para deployments reproducibles

---

## Recursos adicionales

### Documentación oficial:
- [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Application Gateway Documentation](https://learn.microsoft.com/en-us/azure/application-gateway/)
- [Azure SQL Database Documentation](https://learn.microsoft.com/en-us/azure/azure-sql/)

### Troubleshooting común:
1. **502 Bad Gateway:** Verificar health probes y connectivity
2. **Timeout errors:** Ajustar timeout settings en Application Gateway
3. **SSL issues:** Verificar certificate configuration
4. **DNS resolution:** Confirmar FQDN resolution dentro de VNET