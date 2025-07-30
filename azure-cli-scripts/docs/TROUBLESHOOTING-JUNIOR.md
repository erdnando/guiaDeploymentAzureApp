# 🆘 Guía de Resolución de Problemas para Ingenieros Junior

## 🎯 Propósito
Esta guía te ayudará a resolver los problemas más comunes que pueden ocurrir durante la implementación del sistema de pagos con Azure CLI.

## 🚨 ¿Tienes un problema? EMPIEZA AQUÍ

### 1. 🔍 PRIMER PASO SIEMPRE
```bash
# Ejecuta SIEMPRE esto primero
./scripts/00-debug-setup.sh
```
Este script verificará automáticamente la mayoría de problemas comunes.

### 2. ⚡ PROBLEMA URGENTE - SOLUCIONES RÁPIDAS

| Síntoma | Solución Inmediata |
|---------|-------------------|
| 🚫 "az: command not found" | `curl -sL https://aka.ms/InstallAzureCLIDeb \| sudo bash` |
| 🔑 "Please run 'az login'" | `az login` |
| 💰 "Insufficient permissions" | Contacta admin para permisos Contributor |
| 📂 "File not found" | Verifica que estés en directorio correcto |
| 🌐 "Location not available" | Cambia LOCATION a "canadacentral" |

---

## 📋 Problemas Comunes y Soluciones Detalladas

### ❌ Error: "Azure CLI not found"

**Síntoma:**
```bash
bash: az: command not found
```

**Causa:** Azure CLI no está instalado.

**Solución:**
```bash
# Ubuntu/Debian
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# macOS
brew install azure-cli

# Windows (PowerShell como admin)
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
```

### ❌ Error: "Please run 'az login'"

**Síntoma:**
```bash
Please run 'az login' to setup account.
```

**Causa:** No estás autenticado en Azure.

**Solución:**
```bash
# Opción 1: Login normal
az login

# Opción 2: Si tienes problemas con el navegador
az login --use-device-code

# Opción 3: Con service principal
az login --service-principal -u <app-id> -p <password> --tenant <tenant>
```

**Verificación:**
```bash
az account show
```

### ❌ Error: "Subscription not found"

**Síntoma:**
```bash
The subscription 'xxxx' could not be found.
```

**Causa:** No tienes acceso a la subscription o está mal configurada.

**Solución:**
```bash
# Ver subscriptions disponibles
az account list --output table

# Establecer subscription correcta
az account set --subscription "nombre-o-id-correcto"

# Verificar
az account show
```

### ❌ Error: "Insufficient permissions"

**Síntoma:**
```bash
The client does not have authorization to perform action 'Microsoft.Resources/subscriptions/resourceGroups/write'
```

**Causa:** No tienes permisos suficientes.

**Solución:**
1. **Contacta al administrador** de Azure para que te asigne rol "Contributor" o "Owner"
2. **Mientras tanto**, puedes usar un Resource Group existente:
   ```bash
   # Editar parameters/dev.env
   export RESOURCE_GROUP="nombre-rg-existente"
   ```

### ❌ Error: "Location not available"

**Síntoma:**
```bash
Location 'xxx' is not available for subscription
```

**Causa:** La región no está disponible o no soporta Container Apps.

**Solución:**
```bash
# Ver regiones disponibles
az account list-locations --output table

# Cambiar a región recomendada en parameters/dev.env
export LOCATION="canadacentral"  # O eastus2, westeurope
```

### ❌ Error: "Resource already exists"

**Síntoma:**
```bash
Resource group 'xxx' already exists
```

**Causa:** Ya existe un resource group con ese nombre.

**Solución:**
```bash
# Opción 1: Usar RG existente (MUY CUIDADOSO)
# Solo si estás 100% seguro que está vacío

# Opción 2: Cambiar nombre en parameters/dev.env
export RESOURCE_GROUP="rg-PaymentSystem-dev-$(date +%m%d)"

# Opción 3: Limpiar RG existente (PELIGROSO)
az group delete --name "rg-existente" --yes
```

### ❌ Error: Scripts no ejecutables

**Síntoma:**
```bash
bash: ./scripts/01-setup-environment.sh: Permission denied
```

**Causa:** Scripts no tienen permisos de ejecución.

**Solución:**
```bash
# Dar permisos a todos los scripts
chmod +x scripts/*.sh

# Verificar
ls -la scripts/
```

### ❌ Error: "Container Apps not available"

**Síntoma:**
```bash
Container Apps is not available in location 'xxx'
```

**Causa:** Container Apps no está disponible en tu región.

**Solución:**
```bash
# Cambiar a región que soporte Container Apps
# En parameters/dev.env:
export LOCATION="canadacentral"  # Siempre funciona
# O "eastus2", "westeurope", "australiaeast"
```

### ❌ Error: "Database connection failed"

**Síntoma:**
```bash
FATAL: no pg_hba.conf entry for host
```

**Causa:** Firewall de PostgreSQL bloqueando conexión.

**Solución:**
```bash
# Obtener tu IP pública
curl ifconfig.me

# Agregar tu IP al firewall
az postgres flexible-server firewall-rule create \
  --resource-group $RESOURCE_GROUP \
  --name $DB_SERVER_NAME \
  --rule-name "AllowMyIP" \
  --start-ip-address "TU-IP-AQUI" \
  --end-ip-address "TU-IP-AQUI"
```

### ❌ Error: "Application Gateway creation failed"

**Síntoma:**
```bash
Application Gateway deployment failed
```

**Causa:** Usualmente subnet muy pequeña o conflictos de IP.

**Solución:**
```bash
# Verificar subnet de Application Gateway
az network vnet subnet show \
  --vnet-name "vnet-PaymentSystem-dev" \
  --name "subnet-appgw" \
  --resource-group $RESOURCE_GROUP

# Si la subnet es muy pequeña, recrear:
az network vnet subnet delete \
  --vnet-name "vnet-PaymentSystem-dev" \
  --name "subnet-appgw" \
  --resource-group $RESOURCE_GROUP

az network vnet subnet create \
  --vnet-name "vnet-PaymentSystem-dev" \
  --name "subnet-appgw" \
  --resource-group $RESOURCE_GROUP \
  --address-prefix "10.0.10.0/24"
```

---

## 🔧 Herramientas de Debugging

### 1. 🔍 Script de Troubleshooting Interactivo
```bash
./scripts/98-troubleshoot.sh
```
Este script tiene un menú interactivo para diagnosticar problemas específicos.

### 2. 📊 Verificar Estado de Recursos
```bash
# Ver todos los recursos
az resource list --resource-group $RESOURCE_GROUP --output table

# Ver solo Container Apps
az containerapp list --resource-group $RESOURCE_GROUP --output table

# Ver logs de una app específica
az containerapp logs show --name "ca-gateway-dev" --resource-group $RESOURCE_GROUP
```

### 3. 🌐 Test de Conectividad
```bash
# Test básico de conectividad
az network vnet show --name "vnet-PaymentSystem-dev" --resource-group $RESOURCE_GROUP

# Test Application Gateway
APPGW_IP=$(az network public-ip show --name "pip-agw-PaymentSystem-dev" --resource-group $RESOURCE_GROUP --query ipAddress -o tsv)
curl -I http://$APPGW_IP
```

### 4. 💾 Verificar Base de Datos
```bash
# Conectar a PostgreSQL
az postgres flexible-server connect \
  --name $DB_SERVER_NAME \
  --admin-user $DB_ADMIN_USER \
  --database-name postgres
```

---

## 📱 Códigos de Error Comunes

### HTTP Error Codes en Application Gateway
- **502 Bad Gateway**: Backend no responde → Verificar Container Apps
- **503 Service Unavailable**: No hay backends healthy → Verificar health probes
- **504 Gateway Timeout**: Timeout en backend → Verificar performance

### Azure CLI Error Codes
- **AuthorizationFailed**: Sin permisos → Contactar admin
- **ResourceNotFound**: Recurso no existe → Verificar nombres
- **QuotaExceeded**: Límite alcanzado → Limpiar recursos o contactar admin

---

## 🆘 Cuando Todo Falla - Plan de Emergencia

### 1. 🧹 Limpieza Completa y Restart
```bash
# CUIDADO: Esto elimina TODO
./scripts/99-cleanup.sh

# Esperar 5 minutos y empezar de nuevo
sleep 300
./scripts/00-debug-setup.sh
./scripts/01-setup-environment.sh
```

### 2. 🔄 Retry Individual de Scripts
```bash
# Si un script falla, reintentarlo:
./scripts/02-create-networking.sh  # Por ejemplo

# Ver logs detallados
./scripts/98-troubleshoot.sh  # Opción 2: Info de Container Apps
```

### 3. 📞 Pedir Ayuda - Información a Incluir
Cuando pidas ayuda, incluye SIEMPRE:

```bash
# Ejecuta esto y comparte el output:
echo "=== AZURE ACCOUNT ==="
az account show

echo "=== RESOURCE GROUP ==="
az group show --name $RESOURCE_GROUP

echo "=== VARIABLES ==="
env | grep -E "(PROJECT_NAME|ENVIRONMENT|LOCATION|RESOURCE_GROUP)"

echo "=== LAST ERROR ==="
# El último error que viste
```

---

## 🎯 Prevención de Problemas

### ✅ Checklist Pre-Implementación
- [ ] Azure CLI instalado y actualizado
- [ ] Autenticado en Azure (`az account show`)
- [ ] Permisos de Contributor/Owner
- [ ] Variables en `parameters/dev.env` configuradas
- [ ] Región soporta Container Apps
- [ ] Scripts tienen permisos de ejecución

### ✅ Checklist Post-Implementación
- [ ] Todos los recursos creados exitosamente
- [ ] Container Apps responden (URLs funcionan)
- [ ] Base de datos accesible
- [ ] Application Gateway tiene IP pública
- [ ] Monitoring configurado (logs visibles)

### ✅ Buenas Prácticas
1. **Ejecuta UN script a la vez** - No ejecutes múltiples en paralelo
2. **Lee los mensajes** - Cada script explica qué hace
3. **Verifica después de cada paso** - Usa checkpoints
4. **Guarda URLs importantes** - Se guardan en `parameters/`
5. **Limpia cuando termines** - Usa `./scripts/99-cleanup.sh`

---

## 🏆 Cuando Todo Funciona

### 🎉 Señales de Éxito
- [ ] ✅ `az account show` funciona
- [ ] ✅ Resource Group existe y tiene recursos
- [ ] ✅ Container Apps muestran URLs públicas
- [ ] ✅ Application Gateway responde con HTTP 200
- [ ] ✅ Base de datos acepta conexiones
- [ ] ✅ Logs aparecen en Log Analytics

### 🚀 Siguiente Nivel
Una vez que todo funciona:
1. **Experimenta** con diferentes configuraciones
2. **Modifica** las aplicaciones
3. **Añade** nuevos microservicios
4. **Aprende** Terraform/BICEP para comparar enfoques

---

**💡 Recuerda: Cada error es una oportunidad de aprendizaje. ¡No te desanimes!**
