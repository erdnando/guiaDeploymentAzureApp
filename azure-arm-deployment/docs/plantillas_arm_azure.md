# Plantillas ARM - Azure Container Apps + Application Gateway + PostgreSQL

## ⚠️ **GUÍA DE COMANDOS PARA INGENIEROS**

**🔍 ANTES DE EJECUTAR CUALQUIER COMANDO:**
- **📖 SOLO LECTURA**: Los comandos marcados con 📖 son **EJEMPLOS EDUCATIVOS** - NO los ejecutes
- **▶️ EJECUTAR**: Los comandos marcados con ▶️ son **PARA EJECUTAR REALMENTE**
- **⚠️ PRECAUCIÓN**: Los comandos marcados con ⚠️ requieren **CONFIRMACIÓN ANTES** de ejecutar
- **🚫 NO EJECUTAR**: Los comandos marcados con 🚫 son **DESTRUCTIVOS** - solo para referencia

**📋 RESUMEN DE FLUJO:**
1. **Secciones 1-7**: Principalmente educativas con comandos de verificación ▶️
2. **Sección 8+**: Instrucciones reales de despliegue ▶️
3. **Solo ejecuta comandos de despliegue** cuando llegues a "Instrucciones de Despliegue"

---

## Tabla de Contenidos

1. [Introducción a Azure Resource Manager (ARM)](#introducción-a-azure-resource-manager-arm)
2. [¿Qué son las Plantillas ARM?](#qué-son-las-plantillas-arm)
3. [Prerequisitos Detallados](#prerequisitos-detallados)
4. [Preparación del Entorno](#preparación-del-entorno)
5. [Conceptos Fundamentales](#conceptos-fundamentales)
6. [Estructura de una Plantilla ARM](#estructura-de-una-plantilla-arm)
7. [Instrucciones de Implementación](#instrucciones-de-implementación)
8. [Índice de Plantillas por Orden de Ejecución](#índice-de-plantillas-por-orden-de-ejecución)
9. [Plantillas ARM](#plantillas-arm)
10. [Troubleshooting y Mejores Prácticas](#troubleshooting-y-mejores-prácticas)

---

## Introducción a Azure Resource Manager (ARM)

### ¿Qué es Azure Resource Manager?

Azure Resource Manager (ARM) es la **capa de administración** nativa de Microsoft Azure que permite crear, actualizar y eliminar recursos en tu suscripción de Azure de manera declarativa y consistente.

**Imagínalo como el "director de orquesta"** que:
- Recibe tus instrucciones (plantillas)
- Coordina la creación de todos los recursos
- Garantiza que todo se despliegue en el orden correcto
- Mantiene el estado deseado de tu infraestructura

### Beneficios Clave de ARM:

1. **Consistencia**: Despliegues idénticos en diferentes entornos
2. **Repetibilidad**: Ejecutar el mismo despliegue múltiples veces
3. **Declarativo**: Describes "qué quieres" en lugar de "cómo hacerlo"
4. **Gestión de dependencias**: ARM maneja automáticamente el orden de creación
5. **Rollback**: Capacidad de revertir cambios si algo sale mal
6. **Paralelización**: Crea recursos simultáneamente cuando es posible

### Analogía Práctica:
Piensa en ARM como una **receta de cocina detallada**:
- La receta (plantilla) especifica todos los ingredientes (recursos) necesarios
- Los pasos (dependencias) están en orden correcto
- El cocinero (ARM) sigue la receta exactamente
- El resultado final es siempre el mismo plato (infraestructura)

---

## ¿Qué son las Plantillas ARM?

### Definición Simple:
Una **plantilla ARM** es un archivo JSON que define la infraestructura de Azure que quieres crear. Es como un "plano arquitectónico" para tu proyecto en la nube.

### Estructura Básica:
```json
{
  "parámetros": "Valores que puedes cambiar (como variables)",
  "variables": "Cálculos internos de la plantilla",
  "recursos": "Los servicios de Azure que quieres crear",
  "outputs": "Información que quieres obtener después del despliegue"
}
```

### Ventajas sobre Crear Recursos Manualmente:

| **Método Manual (Portal/CLI)** | **Plantillas ARM** |
|--------------------------------|-------------------|
| ❌ Propenso a errores humanos | ✅ Consistente y repetible |
| ❌ Difícil de replicar | ✅ Fácil de versionar y compartir |
| ❌ No documenta la arquitectura | ✅ Autodocumentado |
| ❌ Difícil de mantener | ✅ Fácil de actualizar |
| ❌ Sin control de dependencias | ✅ Dependencias automáticas |

### Casos de Uso Ideales:
- **Desarrollo a Producción**: Mismo entorno en diferentes suscripciones
- **Disaster Recovery**: Recrear infraestructura rápidamente
- **Testing**: Crear y destruir entornos de prueba
- **Cumplimiento**: Garantizar configuraciones estándar
- **Escalamiento**: Replicar arquitectura en diferentes regiones

---

## Arquitectura del Proyecto

### Descripción General
Este proyecto implementa un **sistema completo de Container Apps** con Application Gateway, PostgreSQL y monitoreo integrado, diseñado para aplicaciones modernas en contenedores.

### Flujo de Arquitectura
```
Internet → Application Gateway (WAF v2) → Container Apps (Frontend/Backend) → PostgreSQL Flexible Server
                    ↓
              Log Analytics ← Application Insights
```

### Componentes Principales
1. **🌐 Application Gateway**: Load balancer con WAF integrado para seguridad
2. **📦 Container Apps**: Hosting serverless para aplicaciones containerizadas
3. **🗄️ PostgreSQL Flexible Server**: Base de datos managed con alta disponibilidad
4. **📊 Monitoring Stack**: Log Analytics + Application Insights para observabilidad completa
5. **🛡️ Security**: Network Security Groups, Private networking, Managed Identity

### Plantillas Desplegadas (Orden Secuencial)
1. **01-infrastructure.json** - VNET, subnets, NSG
2. **02-postgresql.json** - PostgreSQL Flexible Server
3. **03-containerenv.json** - Container Apps Environment
4. **04-appgateway.json** - Application Gateway + WAF
5. **05-monitoring.json** - Log Analytics + Application Insights
6. **06-containerapps.json** - Container Apps (Frontend + Backend)

### Características de Seguridad
- WAF (Web Application Firewall) habilitado
- Private networking para PostgreSQL
- Network Security Groups configurados
- Managed Identity para autenticación

### Optimización de Costos
- Container Apps con scaling a cero
- Pay-per-use para recursos activos
- **Desarrollo**: ~$54-310/mes según configuración
- **Producción**: ~$650/mes

---

## Prerequisitos Detallados

### 1. Cuenta y Suscripción de Azure

**Qué necesitas:**
- Una suscripción de Azure activa (puedes usar una [cuenta gratuita](https://azure.microsoft.com/free/))
- Permisos de **Propietario** o **Colaborador** en la suscripción

**Cómo verificar tus permisos:**
```bash
# ▶️ EJECUTAR: Verificar tu suscripción actual
az account show --output table

# ▶️ EJECUTAR: Listar todas tus suscripciones
az account list --output table

# ▶️ EJECUTAR: Verificar tus permisos en el grupo de recursos
az role assignment list --assignee $(az account show --query user.name -o tsv) --output table
```

### 2. Azure CLI Instalado y Configurado

**Instalación según tu sistema operativo:**

**Windows:**
```powershell
# 📖 SOLO LECTURA: Ejemplos de instalación - elige UNA opción
# Opción 1: Descarga el instalador MSI
# https://aka.ms/installazurecliwindows

# Opción 2: Usando Chocolatey
choco install azure-cli

# Opción 3: Usando winget
winget install Microsoft.AzureCLI
```

**macOS:**
```bash
# 📖 SOLO LECTURA: Ejemplos de instalación - elige UNA opción
# Usando Homebrew (recomendado)
brew install azure-cli

# Usando el script de instalación
curl -L https://aka.ms/InstallAzureCli | bash
```

**Linux (Ubuntu/Debian):**
```bash
# 📖 SOLO LECTURA: Ejemplos de instalación - elige UNA opción
# Instalación rápida
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# O instalación manual paso a paso
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt update
sudo apt install azure-cli
```

**Verificación de instalación:**
```bash
# ▶️ EJECUTAR: Verificar versión (mínimo 2.40.0 recomendado)
az --version

# 📖 EJEMPLO OUTPUT: Debería mostrar algo como:
# azure-cli    2.50.0
# core         2.50.0
```

### 3. Autenticación en Azure

**Paso a paso para autenticarte:**

```bash
# ▶️ EJECUTAR: Iniciar sesión en Azure
az login

# ▶️ EJECUTAR: Si tienes múltiples suscripciones, selecciona la correcta
az account list --output table
az account set --subscription "tu-subscription-id"

# ▶️ EJECUTAR: Verificar que estás autenticado correctamente
az account show --query "{subscriptionId:id, tenantId:tenantId, user:user.name}" --output table
```

**Nota importante sobre autenticación:**
- El comando `az login` abrirá tu navegador web para autenticarte
- Si estás en un servidor sin interfaz gráfica, usa `az login --use-device-code`
- Para automatización, considera usar Service Principals (fuera del alcance de esta guía)

### 4. Editor de Código y Extensiones

**Visual Studio Code (Recomendado):**
```bash
# 📖 SOLO LECTURA: Instalar VS Code desde https://code.visualstudio.com/

# 📖 SOLO LECTURA: Extensiones recomendadas:
# 1. Azure Resource Manager Tools (ms-azuretools.vscode-azureresourcemanager)
# 2. Azure CLI Tools (ms-vscode.azurecli)
# 3. JSON Language Features (built-in)
```

**Ventajas de VS Code para ARM:**
- ✅ Sintaxis highlighting para JSON
- ✅ IntelliSense para propiedades de recursos
- ✅ Validación en tiempo real de plantillas
- ✅ Snippets predefinidos para recursos comunes
- ✅ Integración directa con Azure CLI

### 5. Conocimientos Básicos Requeridos

**Conceptos que debes entender:**

1. **JSON Básico:**
   - Estructura de objetos `{}`
   - Arrays `[]`
   - Strings, números, booleans
   - Anidación de objetos

2. **Conceptos de Azure:**
   - Qué es un Grupo de Recursos
   - Regiones de Azure
   - Modelos de suscripción
   - Conceptos básicos de redes (VNET, subredes)

3. **Línea de Comandos Básica:**
   - Navegación de directorios
   - Ejecución de comandos
   - Variables de entorno

---

## Preparación del Entorno

### 1. Crear Estructura de Directorios

Organizaremos nuestro proyecto de manera profesional:

```bash
# ▶️ EJECUTAR: Crear estructura de directorios
mkdir -p azure-arm-deployment/{templates,parameters,scripts,docs}
cd azure-arm-deployment

# 📖 EJEMPLO ESTRUCTURA: Así debería verse tu directorio
# azure-arm-deployment/
# ├── templates/          # Plantillas ARM (.json)
# ├── parameters/         # Archivos de parámetros (.json)
# ├── scripts/           # Scripts de despliegue (.sh/.ps1)
# └── docs/              # Documentación adicional
```

### 2. Configurar Variables de Entorno

⚠️ **IMPORTANTE**: Estos son archivos de configuración que DEBES personalizar, NO ejecutar directamente.

Crea un archivo `variables.sh` (Linux/macOS) o `variables.ps1` (Windows):

**variables.sh:**
```bash
#!/bin/bash

# Variables principales del proyecto
export PROJECT_NAME="paymentapp"
export RESOURCE_GROUP="rg-${PROJECT_NAME}-prod"
export LOCATION="eastus"
export ENVIRONMENT="production"

# Variables de PostgreSQL
export POSTGRES_ADMIN_USER="pgadmin"
export POSTGRES_DB_NAME="paymentdb"

# Variables de Container Registry (GitHub)
export REGISTRY_SERVER="ghcr.io"
export REGISTRY_USERNAME="tu-usuario-github"
export BACKEND_IMAGE="${REGISTRY_SERVER}/${REGISTRY_USERNAME}/payment-api:latest"
export FRONTEND_IMAGE="${REGISTRY_SERVER}/${REGISTRY_USERNAME}/payment-frontend:latest"

# Variables de monitoreo
export ALERT_EMAIL="admin@tuempresa.com"

# Generar nombres únicos para recursos que lo requieren
export UNIQUE_SUFFIX=$(date +%s)
export POSTGRES_SERVER_NAME="pg-${PROJECT_NAME}-${UNIQUE_SUFFIX}"

echo "Variables configuradas para el proyecto: $PROJECT_NAME"
echo "Grupo de recursos: $RESOURCE_GROUP"
echo "Región: $LOCATION"
```

**variables.ps1:**
```powershell
# Variables principales del proyecto
$env:PROJECT_NAME = "paymentapp"
$env:RESOURCE_GROUP = "rg-$($env:PROJECT_NAME)-prod"
$env:LOCATION = "eastus"
$env:ENVIRONMENT = "production"

# Variables de PostgreSQL
$env:POSTGRES_ADMIN_USER = "pgadmin"
$env:POSTGRES_DB_NAME = "paymentdb"

# Variables de Container Registry (GitHub)
$env:REGISTRY_SERVER = "ghcr.io"
$env:REGISTRY_USERNAME = "tu-usuario-github"
$env:BACKEND_IMAGE = "$($env:REGISTRY_SERVER)/$($env:REGISTRY_USERNAME)/payment-api:latest"
$env:FRONTEND_IMAGE = "$($env:REGISTRY_SERVER)/$($env:REGISTRY_USERNAME)/payment-frontend:latest"

# Variables de monitoreo
$env:ALERT_EMAIL = "admin@tuempresa.com"

# Generar nombres únicos para recursos que lo requieren
$env:UNIQUE_SUFFIX = [int](Get-Date -UFormat %s)
$env:POSTGRES_SERVER_NAME = "pg-$($env:PROJECT_NAME)-$($env:UNIQUE_SUFFIX)"

Write-Host "Variables configuradas para el proyecto: $($env:PROJECT_NAME)"
Write-Host "Grupo de recursos: $($env:RESOURCE_GROUP)"
Write-Host "Región: $($env:LOCATION)"
```

**Cómo usar las variables:**
```bash
# ▶️ EJECUTAR: Linux/macOS - cargar variables
source variables.sh

# ▶️ EJECUTAR: Windows PowerShell - cargar variables
.\variables.ps1

# ▶️ EJECUTAR: Verificar que las variables están cargadas
echo $PROJECT_NAME        # Linux/macOS
Write-Host $env:PROJECT_NAME  # Windows
```

### 3. Crear Grupo de Recursos

```bash
# ▶️ EJECUTAR: Crear el grupo de recursos principal
az group create \
  --name $RESOURCE_GROUP \
  --location $LOCATION \
  --tags Environment=$ENVIRONMENT Project=$PROJECT_NAME

# ▶️ EJECUTAR: Verificar que se creó correctamente
az group show --name $RESOURCE_GROUP --output table
```

---

## Conceptos Fundamentales

### 1. Ciclo de Vida de una Plantilla ARM

```
1. [Diseño] → 2. [Escritura] → 3. [Validación] → 4. [Despliegue] → 5. [Monitoreo]
     ↑                                                                      ↓
     ←──────────────────── 6. [Mantenimiento] ←─────────────────────────────
```

**Explicación de cada fase:**

1. **Diseño**: Planificar qué recursos necesitas y cómo se conectan
2. **Escritura**: Crear el archivo JSON con la plantilla
3. **Validación**: Verificar que la sintaxis y lógica sean correctas
4. **Despliegue**: Ejecutar la plantilla para crear los recursos
5. **Monitoreo**: Supervisar que todo funcione correctamente
6. **Mantenimiento**: Actualizar y evolucionar la infraestructura

### 2. Modos de Despliegue

Azure ARM templates soporta dos modos de despliegue que determinan cómo se comporta el Resource Manager al procesar los recursos.

#### **Modo Incremental (Incremental Mode)**

**¿Cómo funciona?**
- Azure compara el estado actual del Resource Group con lo definido en la plantilla
- **Solo modifica recursos que están explícitamente definidos** en la plantilla actual
- Los recursos existentes que **NO están en la plantilla se mantienen intactos**
- Si un recurso existe y está en la plantilla, verifica si necesita actualización

**Comportamiento detallado:**
```
Estado Actual RG: [VM1, Storage1, VNET1, NSG1]
Template Define:  [VM1, Storage2, VNET1]

Resultado:
✅ VM1 - Se verifica y actualiza si hay cambios
✅ Storage2 - Se crea (nuevo recurso)
✅ VNET1 - Se verifica y actualiza si hay cambios
⏸️ Storage1 - Se mantiene sin cambios (no está en template)
⏸️ NSG1 - Se mantiene sin cambios (no está en template)
```

**Casos de uso ideales:**
- **Actualizaciones progresivas** de infraestructura existente
- **Adición de nuevos recursos** sin afectar los existentes
- **Entornos de desarrollo** donde se experimentan cambios graduales
- **Proyectos en equipo** donde diferentes templates manejan diferentes recursos

**Ejemplo práctico:**
```bash
# 📖 EJEMPLO: Primera ejecución - Despliega VNET + Subnet
az deployment group create \
  --resource-group "rg-proyecto" \
  --template-file "network-template.json" \
  --mode Incremental

# 📖 EJEMPLO: Segunda ejecución - Agrega VM sin tocar networking
az deployment group create \
  --resource-group "rg-proyecto" \
  --template-file "vm-template.json" \
  --mode Incremental
# Resultado: VNET se mantiene, VM se agrega
```

#### **Modo Completo (Complete Mode)**

**¿Cómo funciona?**
- Azure trata la plantilla como **la verdad absoluta** del estado deseado
- **Elimina todos los recursos** del Resource Group que no están definidos en la plantilla
- Solo conserva recursos que están explícitamente en la plantilla actual
- Es como "formatear" el Resource Group y recrear solo lo definido

**Comportamiento detallado:**
```
Estado Actual RG: [VM1, Storage1, VNET1, NSG1]
Template Define:  [VM1, Storage2, VNET1]

Resultado:
✅ VM1 - Se verifica y actualiza si hay cambios
✅ Storage2 - Se crea (nuevo recurso)
✅ VNET1 - Se verifica y actualiza si hay cambios
❌ Storage1 - Se ELIMINA (no está en template)
❌ NSG1 - Se ELIMINA (no está en template)
```

**Casos de uso ideales:**
- **Entornos temporales** (testing, staging) que necesitan limpieza
- **Despliegues de CI/CD** donde se quiere estado predecible
- **Migración de infraestructura** donde se quiere eliminar recursos obsoletos
- **Disaster Recovery** donde se necesita recrear todo desde cero

**⚠️ Precauciones importantes:**
- **NUNCA usar en producción** sin verificación exhaustiva
- **Verificar siempre** qué recursos se eliminarán antes de ejecutar
- **Hacer backup** de datos críticos antes del despliegue
- **Probar primero** en entornos no críticos

**Ejemplo práctico:**
```bash
# � EJEMPLO: Verificar qué se eliminará primero
az deployment group validate \
  --resource-group "rg-testing" \
  --template-file "complete-infrastructure.json" \
  --mode Complete

# 📖 EJEMPLO: Ver recursos que serían eliminados
az deployment group what-if \
  --resource-group "rg-testing" \
  --template-file "complete-infrastructure.json" \
  --mode Complete
```

#### **Comparación Práctica**

| Aspecto | Modo Incremental | Modo Completo |
|---------|------------------|---------------|
| **Recursos no en template** | Se mantienen | Se eliminan |
| **Riesgo de pérdida de datos** | Bajo | Alto |
| **Predictibilidad** | Media | Alta |
| **Uso en producción** | ✅ Seguro | ⚠️ Peligroso |
| **Casos típicos** | Actualizaciones, adiciones | Recreación completa |
| **Rollback** | Fácil | Difícil/Imposible |

#### **Comandos de Despliegue**

```bash
# 📖 EJEMPLO: Modo Incremental (por defecto, no necesita especificarse)
az deployment group create \
  --resource-group "mi-rg" \
  --template-file "template.json" \
  --parameters @parameters.json \
  --mode Incremental

# 🚫 NO EJECUTAR SIN VERIFICAR: Modo Completo (especificar explícitamente)
az deployment group create \
  --resource-group "mi-rg" \
  --template-file "template.json" \
  --parameters @parameters.json \
  --mode Complete

# 📖 EJEMPLO: Verificar cambios antes de aplicar (What-If)
az deployment group what-if \
  --resource-group "mi-rg" \
  --template-file "template.json" \
  --parameters @parameters.json \
  --mode Complete
```

#### **Recomendaciones según el escenario:**

**Usa Modo Incremental cuando:**
- 🔄 Actualizas infraestructura existente
- 🆕 Agregas nuevos recursos a un entorno
- 👥 Trabajas en equipo con múltiples templates
- 🛡️ Necesitas máxima seguridad contra eliminaciones accidentales

**Usa Modo Completo cuando:**
- 🧹 Necesitas limpiar completamente un entorno
- 🔄 Migras de una configuración antigua a una nueva
- 🧪 Recrear entornos de testing desde cero
- 📦 Implementas Infrastructure as Code estricto

### 3. Gestión de Dependencias

ARM maneja automáticamente las dependencias entre recursos. Existen dos tipos:

**Dependencias Implícitas:**
```json
{
  "type": "Microsoft.Network/virtualNetworks/subnets",
  "properties": {
    "virtualNetwork": {
      "id": "[resourceId('Microsoft.Network/virtualNetworks', 'myVNet')]"
    }
  }
}
```

**Dependencias Explícitas:**
```json
{
  "type": "Microsoft.Compute/virtualMachines",
  "dependsOn": [
    "[resourceId('Microsoft.Network/virtualNetworks', 'myVNet')]",
    "[resourceId('Microsoft.Storage/storageAccounts', 'myStorage')]"
  ]
}
```

### 4. Funciones ARM Esenciales

**Funciones de String:**
- `concat()`: Unir strings
- `substring()`: Extraer parte de un string
- `replace()`: Reemplazar texto

**Funciones de Recursos:**
- `resourceId()`: Obtener ID completo de un recurso
- `reference()`: Obtener propiedades de un recurso existente
- `listKeys()`: Obtener claves de acceso

**Funciones de Arrays:**
- `length()`: Obtener longitud
- `first()`: Primer elemento
- `last()`: Último elemento

**Ejemplo práctico:**
```json
{
  "variables": {
    "storageAccountName": "[concat(parameters('projectName'), 'storage', uniqueString(resourceGroup().id))]",
    "subnetId": "[resourceId('Microsoft.Network/virtualNetworks/subnets', parameters('vnetName'), 'default')]"
  }
}
```

---

## Estructura de una Plantilla ARM

### Anatomía Completa de una Plantilla

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "apiProfile": "opcional",
  "parameters": { "Valores de entrada configurables" },
  "variables": { "Valores calculados internamente" },
  "functions": [ "Funciones personalizadas (opcional)" ],
  "resources": [ "Recursos de Azure a crear" ],
  "outputs": { "Valores a devolver después del despliegue" }
}
```

### 1. Schema y ContentVersion

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0"
}
```

**Explicación:**
- `$schema`: Define qué versión del formato ARM usar
- `contentVersion`: Tu propio versionado de la plantilla (útil para control de cambios)

### 2. Parameters (Parámetros)

Los parámetros hacen que tu plantilla sea reutilizable:

```json
{
  "parameters": {
    "projectName": {
      "type": "string",
      "defaultValue": "myproject",
      "minLength": 3,
      "maxLength": 15,
      "metadata": {
        "description": "Nombre base del proyecto"
      }
    },
    "environment": {
      "type": "string",
      "defaultValue": "dev",
      "allowedValues": ["dev", "test", "prod"],
      "metadata": {
        "description": "Entorno de despliegue"
      }
    },
    "adminPassword": {
      "type": "securestring",
      "metadata": {
        "description": "Contraseña del administrador"
      }
    }
  }
}
```

**Tipos de parámetros disponibles:**
- `string`: Texto
- `securestring`: Texto cifrado (contraseñas)
- `int`: Números enteros
- `bool`: Verdadero/falso
- `object`: Objetos JSON complejos
- `array`: Listas de valores

### 3. Variables

Las variables almacenan valores calculados:

```json
{
  "variables": {
    "uniqueSuffix": "[uniqueString(resourceGroup().id)]",
    "storageAccountName": "[concat(parameters('projectName'), 'storage', variables('uniqueSuffix'))]",
    "tags": {
      "Environment": "[parameters('environment')]",
      "Project": "[parameters('projectName')]",
      "CreatedBy": "ARM Template"
    }
  }
}
```

### 4. Resources (Recursos)

El corazón de tu plantilla - define qué crear:

```json
{
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2023-01-01",
      "name": "[variables('storageAccountName')]",
      "location": "[resourceGroup().location]",
      "tags": "[variables('tags')]",
      "sku": {
        "name": "Standard_LRS"
      },
      "kind": "StorageV2",
      "properties": {
        "encryption": {
          "services": {
            "blob": {
              "enabled": true
            }
          },
          "keySource": "Microsoft.Storage"
        }
      }
    }
  ]
}
```

### 5. Outputs

Los outputs devuelven información útil después del despliegue:

```json
{
  "outputs": {
    "storageAccountName": {
      "type": "string",
      "value": "[variables('storageAccountName')]"
    },
    "storageAccountId": {
      "type": "string",
      "value": "[resourceId('Microsoft.Storage/storageAccounts', variables('storageAccountName'))]"
    },
    "primaryEndpoints": {
      "type": "object",
      "value": "[reference(variables('storageAccountName')).primaryEndpoints]"
    }
  }
}
```

---

## Instrucciones de Implementación

### Paso 1: Validación Previa al Despliegue

La validación es un paso **crítico** que puede ahorrarte tiempo, dinero y problemas en producción. Azure proporciona dos herramientas principales para validar antes de desplegar.

#### **1.1 Validación de Sintaxis y Parámetros**

La validación básica verifica que tu template tenga sintaxis correcta y que todos los parámetros requeridos estén presentes.

```bash
# ▶️ EJECUTAR: Validación básica
az deployment group validate \
  --resource-group $RESOURCE_GROUP \
  --template-file plantilla.json \
  --parameters @parametros.json
```

**¿Qué verifica la validación básica?**
- ✅ **Sintaxis JSON** correcta del template
- ✅ **Parámetros requeridos** están presentes
- ✅ **Tipos de datos** coinciden (string, int, bool, etc.)
- ✅ **Valores permitidos** están dentro de rangos válidos
- ✅ **Referencias de recursos** son correctas
- ✅ **Permisos RBAC** suficientes para crear recursos

**Ejemplo de output exitoso:**
```json
{
  "error": null,
  "properties": {
    "correlationId": "12345678-1234-1234-1234-123456789012",
    "debugSetting": null,
    "dependencies": [...],
    "duration": "PT2.1234567S",
    "mode": "Incremental",
    "outputResources": [...],
    "outputs": {...},
    "parameters": {...},
    "parametersLink": null,
    "providers": [...],
    "provisioningState": "Succeeded",
    "template": {...},
    "templateLink": null,
    "timestamp": "2025-07-29T20:30:00.123456Z",
    "validatedResources": [...]
  }
}
```

**Ejemplo de output con errores:**
```json
{
  "error": {
    "code": "InvalidTemplate",
    "message": "Deployment template validation failed: 'The template parameter 'adminPassword' is not found. Please see https://aka.ms/arm-template/#parameters for usage details.'.",
    "details": [
      {
        "code": "InvalidTemplateDeployment",
        "message": "The template parameter 'adminPassword' is not found."
      }
    ]
  }
}
```

#### **1.2 What-If Analysis (Análisis de Cambios)**

El comando `what-if` es **la herramienta más valiosa** para entender exactamente qué va a cambiar antes de ejecutar el despliegue.

```bash
# ▶️ EJECUTAR: What-if básico
az deployment group what-if \
  --resource-group $RESOURCE_GROUP \
  --template-file plantilla.json \
  --parameters @parametros.json

# ▶️ EJECUTAR: What-if con output detallado
az deployment group what-if \
  --resource-group $RESOURCE_GROUP \
  --template-file plantilla.json \
  --parameters @parametros.json \
  --result-format FullResourcePayloads

# What-if en modo Complete (para ver qué se eliminaría)
az deployment group what-if \
  --resource-group $RESOURCE_GROUP \
  --template-file plantilla.json \
  --parameters @parametros.json \
  --mode Complete
```

#### **1.3 Interpretando el Output de What-If**

El output de what-if usa un sistema de colores y símbolos específicos:

**Tipos de Cambios:**

```bash
# 🟢 CREAR - Recursos nuevos que se crearán
+ Create
  └─ Microsoft.Storage/storageAccounts/mystorageaccount
      ├─ Location: "eastus"
      ├─ SKU: "Standard_LRS"
      └─ Kind: "StorageV2"

# 🔵 MODIFICAR - Recursos existentes que cambiarán
~ Modify
  └─ Microsoft.Compute/virtualMachines/myvm
      ├─ Properties.storageProfile.imageReference.version:
      │   ├─ "18.04-LTS" → "20.04-LTS"
      └─ Properties.storageProfile.osDisk.diskSizeGB:
          ├─ 30 → 64

# 🔴 ELIMINAR - Recursos que se eliminarán (solo modo Complete)
- Delete
  └─ Microsoft.Network/networkSecurityGroups/old-nsg
      └─ (Este recurso se eliminará porque no está en el template)

# ⚪ SIN CAMBIOS - Recursos que no cambiarán
= NoChange
  └─ Microsoft.Network/virtualNetworks/myvnet
      └─ (Este recurso ya existe con la configuración correcta)

# 🟡 IGNORAR - Recursos fuera del scope del template
* Ignore
  └─ Microsoft.Resources/resourceGroups/my-rg
      └─ (Los resource groups no se gestionan en templates de grupo)
```

**Ejemplo de Output Real Detallado:**

```bash
Note: The result may contain false positive predictions (noise).
You can help us improve the accuracy of the result by opening an issue here: https://aka.ms/WhatIfIssues

Resource and property changes are indicated with these symbols:
  - Delete
  + Create
  ~ Modify
  * Ignore
  = NoChange

The deployment will update the following scope:

Scope: /subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-paymentapp-dev

  + Microsoft.Network/virtualNetworks/vnet-paymentapp-dev [2021-02-01]

      apiVersion:                       "2021-02-01"
      location:                         "eastus"
      name:                             "vnet-paymentapp-dev"
      properties.addressSpace.addressPrefixes: [
        0: "10.0.0.0/16"
      ]
      properties.subnets: [
        0:

          name:                                   "subnet-appgateway"
          properties.addressPrefix:               "10.0.1.0/24"
          properties.delegations:                 []
          properties.privateEndpointNetworkPolicies: "Enabled"
          properties.privateLinkServiceNetworkPolicies: "Enabled"

        1:

          name:                                   "subnet-containerapp"
          properties.addressPrefix:               "10.0.2.0/24"
          properties.delegations: [
            0:

              name:                                       "Microsoft.App/environments"
              properties.serviceName:                     "Microsoft.App/environments"

          ]
          properties.privateEndpointNetworkPolicies: "Enabled"
          properties.privateLinkServiceNetworkPolicies: "Enabled"
      ]
      type:                             "Microsoft.Network/virtualNetworks"

  ~ Microsoft.Storage/storageAccounts/mystorageaccount123 [2021-04-01]

    ~ properties.minimumTlsVersion: "TLS1_0" => "TLS1_2"

Resource changes: 1 to create, 1 to modify.
```

#### **1.4 Análisis Avanzado de What-If**

**Cómo leer cambios complejos:**

```bash
# Cambio en propiedades anidadas
~ Modify
  └─ Microsoft.Compute/virtualMachines/myvm
      └─ Properties.storageProfile.dataDisks:
          ├─ [0].diskSizeGB: 128 → 256          # Disco existente aumenta tamaño
          ├─ [1]: <nuevo disco>                 # Se agrega segundo disco
          │   ├─ diskSizeGB: 512
          │   ├─ lun: 1
          │   └─ createOption: "Empty"
          └─ [2]: <eliminado>                   # Se elimina tercer disco
```

**Cambios en arrays y objetos:**
```bash
# Adición de elementos a un array
~ Modify
  └─ Microsoft.Network/networkSecurityGroups/my-nsg
      └─ Properties.securityRules:
          ├─ [0]: = NoChange                    # Regla existente sin cambios
          ├─ [1]: + Create                      # Nueva regla de seguridad
          │   ├─ name: "AllowHTTPS"
          │   ├─ protocol: "Tcp"
          │   ├─ sourcePortRange: "*"
          │   ├─ destinationPortRange: "443"
          │   ├─ access: "Allow"
          │   └─ priority: 120
          └─ [2]: - Delete                      # Regla que se eliminará
```

#### **1.5 Casos Prácticos de Validación**

**Escenario 1: Primera implementación**
```bash
# Para un Resource Group vacío
az deployment group what-if \
  --resource-group rg-new-project \
  --template-file complete-infrastructure.json \
  --parameters @dev.parameters.json

# Output esperado: Todo con "+ Create"
# Verificar: Que no hay "- Delete" inesperados
```

**Escenario 2: Actualización de infraestructura**
```bash
# Para actualizar recursos existentes
az deployment group what-if \
  --resource-group rg-existing-project \
  --template-file updated-infrastructure.json \
  --parameters @prod.parameters.json

# Output esperado: Mix de "~ Modify" y "= NoChange"
# Verificar: Que los cambios son los esperados
```

**Escenario 3: Limpieza completa**
```bash
# Para ver qué se eliminaría en modo Complete
az deployment group what-if \
  --resource-group rg-test-environment \
  --template-file minimal-template.json \
  --parameters @test.parameters.json \
  --mode Complete

# Output esperado: Muchos "- Delete"
# Verificar: Que realmente quieres eliminar todo lo listado
```

#### **1.6 Interpretación de Errores Comunes**

**Error de permisos:**
```json
{
  "error": {
    "code": "AuthorizationFailed",
    "message": "The client 'user@domain.com' with object id '12345' does not have authorization to perform action 'Microsoft.Compute/virtualMachines/write' over scope '/subscriptions/subscription-id/resourceGroups/rg-name'."
  }
}
```
**Solución**: Verificar permisos RBAC en la suscripción/resource group.

**Error de quotas:**
```json
{
  "error": {
    "code": "OperationNotAllowed",
    "message": "Operation could not be completed as it results in exceeding approved quota. Additional details - Deployment Model: Resource Manager, Location: East US, Current Limit: 4, Current Usage: 4, Additional Required: 2, (Minimum) New Limit Required: 6."
  }
}
```
**Solución**: Solicitar aumento de quota o cambiar región/SKU.

**Error de recursos conflictivos:**
```json
{
  "error": {
    "code": "ResourceNameAlreadyExists",
    "message": "The storage account named 'mystorageaccount' is already taken."
  }
}
```
**Solución**: Usar nombres únicos o funciones como `uniqueString()`.

#### **1.7 Best Practices para Validación**

1. **Siempre valida antes de desplegar** en cualquier entorno
2. **Usa what-if** especialmente en modo Complete
3. **Revisa cada línea** del output de what-if cuidadosamente
4. **Prueba en dev** antes de ir a producción
5. **Documenta cambios esperados** antes de ejecutar
6. **Verifica permisos** con tiempo suficiente
7. **Considera el timing** - algunos recursos tardan tiempo en crearse

### Paso 2: Crear Archivos de Parámetros

En lugar de pasar parámetros en la línea de comandos, usa archivos JSON:

**parameters/dev.parameters.json:**
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "projectName": {
      "value": "paymentapp"
    },
    "environment": {
      "value": "dev"
    },
    "skuName": {
      "value": "Standard_B1ms"
    },
    "adminPassword": {
      "value": "YourSecurePassword123!"
    }
  }
}
```

**parameters/prod.parameters.json:**
```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "projectName": {
      "value": "paymentapp"
    },
    "environment": {
      "value": "prod"
    },
    "skuName": {
      "value": "Standard_D2s_v3"
    },
    "adminPassword": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.KeyVault/vaults/{vault}"
        },
        "secretName": "adminPassword"
      }
    }
  }
}
```

### Paso 3: Scripts de Despliegue Automatizado

**scripts/deploy.sh:**
```bash
#!/bin/bash

# Cargar variables
source ../variables.sh

# Función para mostrar mensajes
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Función para manejar errores
handle_error() {
    log "ERROR: $1"
    exit 1
}

# Validar que estamos autenticados
az account show > /dev/null 2>&1 || handle_error "No estás autenticado en Azure. Ejecuta 'az login'"

# Array de plantillas en orden de ejecución
declare -a templates=(
    "01-infrastructure"
    "02-postgresql"
    "03-containerenv"
    "04-appgateway"
    "05-monitoring"
    "06-containerapps"
)

# Desplegar cada plantilla
for template in "${templates[@]}"; do
    log "Desplegando plantilla: $template"
    
    # Validar primero
    az deployment group validate \
        --resource-group $RESOURCE_GROUP \
        --template-file "templates/${template}.json" \
        --parameters "@parameters/${ENVIRONMENT}.parameters.json" \
        || handle_error "Validación falló para $template"
    
    # Desplegar
    az deployment group create \
        --resource-group $RESOURCE_GROUP \
        --template-file "templates/${template}.json" \
        --parameters "@parameters/${ENVIRONMENT}.parameters.json" \
        --name "${template}-$(date +%Y%m%d-%H%M%S)" \
        || handle_error "Despliegue falló para $template"
    
    log "Plantilla $template desplegada exitosamente"
done

log "Todos los despliegues completados exitosamente"
```

### Paso 4: Monitoreo del Despliegue

```bash
# Ver el estado de los despliegues
az deployment group list \
  --resource-group $RESOURCE_GROUP \
  --output table

# Ver detalles de un despliegue específico
az deployment group show \
  --resource-group $RESOURCE_GROUP \
  --name "deployment-name" \
  --output json

# Ver operaciones detalladas de un despliegue
az deployment operation group list \
  --resource-group $RESOURCE_GROUP \
  --name "deployment-name" \
  --output table
```

---

## Índice de Plantillas por Orden de Ejecución

1. [Plantilla 1: Infraestructura Base](#plantilla-1-infraestructura-base)
2. [Plantilla 2: PostgreSQL Database](#plantilla-2-postgresql-database)
3. [Plantilla 3: Container Apps Environment](#plantilla-3-container-apps-environment)
4. [Plantilla 4: Application Gateway](#plantilla-4-application-gateway)
5. [Plantilla 5: Monitoreo y Alertas](#plantilla-5-monitoreo-y-alertas)
6. [Plantilla 6: Container Apps Deployment](#plantilla-6-container-apps-deployment)

---

## Plantilla 1: Infraestructura Base
**Orden de ejecución: 1**
**Descripción: Red virtual, subredes y grupo de recursos base**

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "projectName": {
      "type": "string",
      "defaultValue": "paymentapp",
      "metadata": {
        "description": "Nombre base del proyecto para nombrado de recursos"
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "Ubicación para todos los recursos"
      }
    },
    "vnetAddressPrefix": {
      "type": "string",
      "defaultValue": "10.0.0.0/16",
      "metadata": {
        "description": "Prefijo de direcciones para la VNET"
      }
    },
    "appGatewaySubnetPrefix": {
      "type": "string",
      "defaultValue": "10.0.0.0/24",
      "metadata": {
        "description": "Prefijo de subred para Application Gateway"
      }
    },
    "containerAppSubnetPrefix": {
      "type": "string",
      "defaultValue": "10.0.8.0/21",
      "metadata": {
        "description": "Prefijo de subred para Container Apps"
      }
    }
  },
  "variables": {
    "vnetName": "[concat('vnet-', parameters('projectName'))]",
    "appGatewaySubnetName": "subnet-appgw",
    "containerAppSubnetName": "subnet-containerapp",
    "nsgName": "[concat('nsg-', parameters('projectName'))]"
  },
  "resources": [
    {
      "type": "Microsoft.Network/networkSecurityGroups",
      "apiVersion": "2023-04-01",
      "name": "[variables('nsgName')]",
      "location": "[parameters('location')]",
      "properties": {
        "securityRules": [
          {
            "name": "AllowHTTPS",
            "properties": {
              "protocol": "Tcp",
              "sourcePortRange": "*",
              "destinationPortRange": "443",
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "access": "Allow",
              "priority": 100,
              "direction": "Inbound"
            }
          },
          {
            "name": "AllowHTTP",
            "properties": {
              "protocol": "Tcp",
              "sourcePortRange": "*",
              "destinationPortRange": "80",
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "access": "Allow",
              "priority": 110,
              "direction": "Inbound"
            }
          },
          {
            "name": "AllowAppGatewayPorts",
            "properties": {
              "protocol": "Tcp",
              "sourcePortRange": "*",
              "destinationPortRange": "65200-65535",
              "sourceAddressPrefix": "*",
              "destinationAddressPrefix": "*",
              "access": "Allow",
              "priority": 120,
              "direction": "Inbound"
            }
          }
        ]
      }
    },
    {
      "type": "Microsoft.Network/virtualNetworks",
      "apiVersion": "2023-04-01",
      "name": "[variables('vnetName')]",
      "location": "[parameters('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Network/networkSecurityGroups', variables('nsgName'))]"
      ],
      "properties": {
        "addressSpace": {
          "addressPrefixes": [
            "[parameters('vnetAddressPrefix')]"
          ]
        },
        "subnets": [
          {
            "name": "[variables('appGatewaySubnetName')]",
            "properties": {
              "addressPrefix": "[parameters('appGatewaySubnetPrefix')]",
              "networkSecurityGroup": {
                "id": "[resourceId('Microsoft.Network/networkSecurityGroups', variables('nsgName'))]"
              }
            }
          },
          {
            "name": "[variables('containerAppSubnetName')]",
            "properties": {
              "addressPrefix": "[parameters('containerAppSubnetPrefix')]",
              "delegations": [
                {
                  "name": "Microsoft.App.environments",
                  "properties": {
                    "serviceName": "Microsoft.App/environments"
                  }
                }
              ]
            }
          }
        ]
      }
    }
  ],
  "outputs": {
    "vnetName": {
      "type": "string",
      "value": "[variables('vnetName')]"
    },
    "vnetId": {
      "type": "string",
      "value": "[resourceId('Microsoft.Network/virtualNetworks', variables('vnetName'))]"
    },
    "appGatewaySubnetId": {
      "type": "string",
      "value": "[resourceId('Microsoft.Network/virtualNetworks/subnets', variables('vnetName'), variables('appGatewaySubnetName'))]"
    },
    "containerAppSubnetId": {
      "type": "string",
      "value": "[resourceId('Microsoft.Network/virtualNetworks/subnets', variables('vnetName'), variables('containerAppSubnetName'))]"
    }
  }
}
```

---

## Plantilla 2: PostgreSQL Database
**Orden de ejecución: 2**
**Descripción: Azure Database for PostgreSQL Flexible Server**

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "projectName": {
      "type": "string",
      "defaultValue": "paymentapp",
      "metadata": {
        "description": "Nombre base del proyecto"
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "Ubicación para todos los recursos"
      }
    },
    "administratorLogin": {
      "type": "string",
      "defaultValue": "pgadmin",
      "metadata": {
        "description": "Usuario administrador de PostgreSQL"
      }
    },
    "administratorLoginPassword": {
      "type": "securestring",
      "metadata": {
        "description": "Contraseña del administrador de PostgreSQL"
      }
    },
    "postgresVersion": {
      "type": "string",
      "defaultValue": "14",
      "allowedValues": [
        "13",
        "14",
        "15"
      ],
      "metadata": {
        "description": "Versión de PostgreSQL"
      }
    },
    "skuName": {
      "type": "string",
      "defaultValue": "Standard_B1ms",
      "metadata": {
        "description": "SKU del servidor PostgreSQL"
      }
    },
    "tier": {
      "type": "string",
      "defaultValue": "Burstable",
      "allowedValues": [
        "Burstable",
        "GeneralPurpose",
        "MemoryOptimized"
      ],
      "metadata": {
        "description": "Tier de PostgreSQL"
      }
    },
    "storageSizeGB": {
      "type": "int",
      "defaultValue": 32,
      "metadata": {
        "description": "Tamaño de almacenamiento en GB"
      }
    },
    "databaseName": {
      "type": "string",
      "defaultValue": "paymentdb",
      "metadata": {
        "description": "Nombre de la base de datos"
      }
    }
  },
  "variables": {
    "serverName": "[concat('pg-', parameters('projectName'), '-', uniqueString(resourceGroup().id))]"
  },
  "resources": [
    {
      "type": "Microsoft.DBforPostgreSQL/flexibleServers",
      "apiVersion": "2022-12-01",
      "name": "[variables('serverName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "[parameters('skuName')]",
        "tier": "[parameters('tier')]"
      },
      "properties": {
        "administratorLogin": "[parameters('administratorLogin')]",
        "administratorLoginPassword": "[parameters('administratorLoginPassword')]",
        "version": "[parameters('postgresVersion')]",
        "storage": {
          "storageSizeGB": "[parameters('storageSizeGB')]"
        },
        "backup": {
          "backupRetentionDays": 7,
          "geoRedundantBackup": "Disabled"
        },
        "highAvailability": {
          "mode": "Disabled"
        },
        "network": {
          "publicNetworkAccess": "Enabled"
        }
      }
    },
    {
      "type": "Microsoft.DBforPostgreSQL/flexibleServers/firewallRules",
      "apiVersion": "2022-12-01",
      "name": "[concat(variables('serverName'), '/AllowAzureServices')]",
      "dependsOn": [
        "[resourceId('Microsoft.DBforPostgreSQL/flexibleServers', variables('serverName'))]"
      ],
      "properties": {
        "startIpAddress": "0.0.0.0",
        "endIpAddress": "0.0.0.0"
      }
    },
    {
      "type": "Microsoft.DBforPostgreSQL/flexibleServers/databases",
      "apiVersion": "2022-12-01",
      "name": "[concat(variables('serverName'), '/', parameters('databaseName'))]",
      "dependsOn": [
        "[resourceId('Microsoft.DBforPostgreSQL/flexibleServers', variables('serverName'))]"
      ],
      "properties": {
        "charset": "utf8",
        "collation": "en_US.utf8"
      }
    }
  ],
  "outputs": {
    "serverName": {
      "type": "string",
      "value": "[variables('serverName')]"
    },
    "serverFQDN": {
      "type": "string",
      "value": "[reference(variables('serverName')).fullyQualifiedDomainName]"
    },
    "databaseName": {
      "type": "string",
      "value": "[parameters('databaseName')]"
    },
    "connectionString": {
      "type": "string",
      "value": "[concat('Host=', reference(variables('serverName')).fullyQualifiedDomainName, ';Database=', parameters('databaseName'), ';Username=', parameters('administratorLogin'), ';Password=', parameters('administratorLoginPassword'), ';SslMode=Require;')]"
    }
  }
}
```

---

## Plantilla 3: Container Apps Environment
**Orden de ejecución: 3**
**Descripción: Entorno de Container Apps con integración de VNET**

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "projectName": {
      "type": "string",
      "defaultValue": "paymentapp",
      "metadata": {
        "description": "Nombre base del proyecto"
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "Ubicación para todos los recursos"
      }
    },
    "vnetName": {
      "type": "string",
      "metadata": {
        "description": "Nombre de la VNET existente"
      }
    },
    "containerAppSubnetName": {
      "type": "string",
      "defaultValue": "subnet-containerapp",
      "metadata": {
        "description": "Nombre de la subred para Container Apps"
      }
    }
  },
  "variables": {
    "environmentName": "[concat('env-', parameters('projectName'))]",
    "logAnalyticsWorkspaceName": "[concat('log-', parameters('projectName'))]"
  },
  "resources": [
    {
      "type": "Microsoft.OperationalInsights/workspaces",
      "apiVersion": "2022-10-01",
      "name": "[variables('logAnalyticsWorkspaceName')]",
      "location": "[parameters('location')]",
      "properties": {
        "sku": {
          "name": "PerGB2018"
        },
        "retentionInDays": 30
      }
    },
    {
      "type": "Microsoft.App/managedEnvironments",
      "apiVersion": "2023-05-01",
      "name": "[variables('environmentName')]",
      "location": "[parameters('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.OperationalInsights/workspaces', variables('logAnalyticsWorkspaceName'))]"
      ],
      "properties": {
        "appLogsConfiguration": {
          "destination": "log-analytics",
          "logAnalyticsConfiguration": {
            "customerId": "[reference(variables('logAnalyticsWorkspaceName')).customerId]",
            "sharedKey": "[listKeys(variables('logAnalyticsWorkspaceName'), '2022-10-01').primarySharedKey]"
          }
        },
        "vnetConfiguration": {
          "infrastructureSubnetId": "[resourceId('Microsoft.Network/virtualNetworks/subnets', parameters('vnetName'), parameters('containerAppSubnetName'))]",
          "internal": true
        }
      }
    }
  ],
  "outputs": {
    "environmentName": {
      "type": "string",
      "value": "[variables('environmentName')]"
    },
    "environmentId": {
      "type": "string",
      "value": "[resourceId('Microsoft.App/managedEnvironments', variables('environmentName'))]"
    },
    "logAnalyticsWorkspaceName": {
      "type": "string",
      "value": "[variables('logAnalyticsWorkspaceName')]"
    },
    "defaultDomain": {
      "type": "string",
      "value": "[reference(variables('environmentName')).defaultDomain]"
    }
  }
}
```

---

## Plantilla 4: Application Gateway
**Orden de ejecución: 4**
**Descripción: Application Gateway con configuración WAF_v2**

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "projectName": {
      "type": "string",
      "defaultValue": "paymentapp",
      "metadata": {
        "description": "Nombre base del proyecto"
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "Ubicación para todos los recursos"
      }
    },
    "vnetName": {
      "type": "string",
      "metadata": {
        "description": "Nombre de la VNET existente"
      }
    },
    "appGatewaySubnetName": {
      "type": "string",
      "defaultValue": "subnet-appgw",
      "metadata": {
        "description": "Nombre de la subred para Application Gateway"
      }
    },
    "skuName": {
      "type": "string",
      "defaultValue": "WAF_v2",
      "allowedValues": [
        "Standard_v2",
        "WAF_v2"
      ],
      "metadata": {
        "description": "SKU del Application Gateway"
      }
    },
    "capacity": {
      "type": "int",
      "defaultValue": 2,
      "minValue": 1,
      "maxValue": 125,
      "metadata": {
        "description": "Número de instancias del Application Gateway"
      }
    },
    "apiBackendFQDN": {
      "type": "string",
      "metadata": {
        "description": "FQDN del backend API Container App"
      }
    },
    "frontendBackendFQDN": {
      "type": "string",
      "metadata": {
        "description": "FQDN del backend Frontend Container App"
      }
    }
  },
  "variables": {
    "applicationGatewayName": "[concat('appgw-', parameters('projectName'))]",
    "publicIPAddressName": "[concat('pip-', parameters('projectName'), '-appgw')]",
    "applicationGatewaySubnetId": "[resourceId('Microsoft.Network/virtualNetworks/subnets', parameters('vnetName'), parameters('appGatewaySubnetName'))]"
  },
  "resources": [
    {
      "type": "Microsoft.Network/publicIPAddresses",
      "apiVersion": "2023-04-01",
      "name": "[variables('publicIPAddressName')]",
      "location": "[parameters('location')]",
      "sku": {
        "name": "Standard"
      },
      "properties": {
        "publicIPAllocationMethod": "Static"
      }
    },
    {
      "type": "Microsoft.Network/applicationGateways",
      "apiVersion": "2023-04-01",
      "name": "[variables('applicationGatewayName')]",
      "location": "[parameters('location')]",
      "dependsOn": [
        "[resourceId('Microsoft.Network/publicIPAddresses', variables('publicIPAddressName'))]"
      ],
      "properties": {
        "sku": {
          "name": "[parameters('skuName')]",
          "tier": "[parameters('skuName')]",
          "capacity": "[parameters('capacity')]"
        },
        "gatewayIPConfigurations": [
          {
            "name": "appGatewayIpConfig",
            "properties": {
              "subnet": {
                "id": "[variables('applicationGatewaySubnetId')]"
              }
            }
          }
        ],
        "frontendIPConfigurations": [
          {
            "name": "appGwPublicFrontendIp",
            "properties": {
              "publicIPAddress": {
                "id": "[resourceId('Microsoft.Network/publicIPAddresses', variables('publicIPAddressName'))]"
              }
            }
          }
        ],
        "frontendPorts": [
          {
            "name": "port_80",
            "properties": {
              "port": 80
            }
          },
          {
            "name": "port_443",
            "properties": {
              "port": 443
            }
          }
        ],
        "backendAddressPools": [
          {
            "name": "api-backend-pool",
            "properties": {
              "backendAddresses": [
                {
                  "fqdn": "[parameters('apiBackendFQDN')]"
                }
              ]
            }
          },
          {
            "name": "frontend-backend-pool",
            "properties": {
              "backendAddresses": [
                {
                  "fqdn": "[parameters('frontendBackendFQDN')]"
                }
              ]
            }
          }
        ],
        "backendHttpSettingsCollection": [
          {
            "name": "api-http-settings",
            "properties": {
              "port": 443,
              "protocol": "Https",
              "cookieBasedAffinity": "Disabled",
              "pickHostNameFromBackendAddress": true,
              "requestTimeout": 30,
              "probe": {
                "id": "[concat(resourceId('Microsoft.Network/applicationGateways', variables('applicationGatewayName')), '/probes/api-health-probe')]"
              }
            }
          },
          {
            "name": "frontend-http-settings",
            "properties": {
              "port": 443,
              "protocol": "Https",
              "cookieBasedAffinity": "Disabled",
              "pickHostNameFromBackendAddress": true,
              "requestTimeout": 30,
              "probe": {
                "id": "[concat(resourceId('Microsoft.Network/applicationGateways', variables('applicationGatewayName')), '/probes/frontend-health-probe')]"
              }
            }
          }
        ],
        "httpListeners": [
          {
            "name": "appGwHttpListener",
            "properties": {
              "frontendIPConfiguration": {
                "id": "[concat(resourceId('Microsoft.Network/applicationGateways', variables('applicationGatewayName')), '/frontendIPConfigurations/appGwPublicFrontendIp')]"
              },
              "frontendPort": {
                "id": "[concat(resourceId('Microsoft.Network/applicationGateways', variables('applicationGatewayName')), '/frontendPorts/port_80')]"
              },
              "protocol": "Http"
            }
          }
        ],
        "requestRoutingRules": [
          {
            "name": "api-routing-rule",
            "properties": {
              "ruleType": "PathBasedRouting",
              "httpListener": {
                "id": "[concat(resourceId('Microsoft.Network/applicationGateways', variables('applicationGatewayName')), '/httpListeners/appGwHttpListener')]"
              },
              "urlPathMap": {
                "id": "[concat(resourceId('Microsoft.Network/applicationGateways', variables('applicationGatewayName')), '/urlPathMaps/urlPathMap')]"
              }
            }
          }
        ],
        "urlPathMaps": [
          {
            "name": "urlPathMap",
            "properties": {
              "defaultBackendAddressPool": {
                "id": "[concat(resourceId('Microsoft.Network/applicationGateways', variables('applicationGatewayName')), '/backendAddressPools/frontend-backend-pool')]"
              },
              "defaultBackendHttpSettings": {
                "id": "[concat(resourceId('Microsoft.Network/applicationGateways', variables('applicationGatewayName')), '/backendHttpSettingsCollection/frontend-http-settings')]"
              },
              "pathRules": [
                {
                  "name": "api-path-rule",
                  "properties": {
                    "paths": [
                      "/api/*"
                    ],
                    "backendAddressPool": {
                      "id": "[concat(resourceId('Microsoft.Network/applicationGateways', variables('applicationGatewayName')), '/backendAddressPools/api-backend-pool')]"
                    },
                    "backendHttpSettings": {
                      "id": "[concat(resourceId('Microsoft.Network/applicationGateways', variables('applicationGatewayName')), '/backendHttpSettingsCollection/api-http-settings')]"
                    }
                  }
                }
              ]
            }
          }
        ],
        "probes": [
          {
            "name": "api-health-probe",
            "properties": {
              "protocol": "Https",
              "path": "/api/health",
              "interval": 30,
              "timeout": 30,
              "unhealthyThreshold": 3,
              "pickHostNameFromBackendHttpSettings": true
            }
          },
          {
            "name": "frontend-health-probe",
            "properties": {
              "protocol": "Https",
              "path": "/",
              "interval": 30,
              "timeout": 30,
              "unhealthyThreshold": 3,
              "pickHostNameFromBackendHttpSettings": true
            }
          }
        ],
        "webApplicationFirewallConfiguration": {
          "enabled": true,
          "firewallMode": "Prevention",
          "ruleSetType": "OWASP",
          "ruleSetVersion": "3.2"
        }
      }
    }
  ],
  "outputs": {
    "applicationGatewayName": {
      "type": "string",
      "value": "[variables('applicationGatewayName')]"
    },
    "publicIPAddress": {
      "type": "string",
      "value": "[reference(variables('publicIPAddressName')).ipAddress]"
    },
    "applicationGatewayFQDN": {
      "type": "string",
      "value": "[reference(variables('publicIPAddressName')).dnsSettings.fqdn]"
    }
  }
}
```

---

## Plantilla 5: Monitoreo y Alertas
**Orden de ejecución: 5**
**Descripción: Application Insights y alertas de monitoreo**

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "projectName": {
      "type": "string",
      "defaultValue": "paymentapp",
      "metadata": {
        "description": "Nombre base del proyecto"
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "Ubicación para todos los recursos"
      }
    },
    "logAnalyticsWorkspaceName": {
      "type": "string",
      "metadata": {
        "description": "Nombre del workspace de Log Analytics existente"
      }
    },
    "alertEmailAddress": {
      "type": "string",
      "metadata": {
        "description": "Email para recibir alertas"
      }
    }
  },
  "variables": {
    "applicationInsightsName": "[concat('appi-', parameters('projectName'))]",
    "actionGroupName": "[concat('ag-', parameters('projectName'))]"
  },
  "resources": [
    {
      "type": "Microsoft.Insights/components",
      "apiVersion": "2020-02-02",
      "name": "[variables('applicationInsightsName')]",
      "location": "[parameters('location')]",
      "kind": "web",
      "properties": {
        "Application_Type": "web",
        "WorkspaceResourceId": "[resourceId('Microsoft.OperationalInsights/workspaces', parameters('logAnalyticsWorkspaceName'))]"
      }
    },
    {
      "type": "Microsoft.Insights/actionGroups",
      "apiVersion": "2023-01-01",
      "name": "[variables('actionGroupName')]",
      "location": "Global",
      "properties": {
        "groupShortName": "[substring(variables('actionGroupName'), 0, 12)]",
        "enabled": true,
        "emailReceivers": [
          {
            "name": "Email Admin",
            "emailAddress": "[parameters('alertEmailAddress')]"
          }
        ]
      }
    },
    {
      "type": "Microsoft.Insights/metricAlerts",
      "apiVersion": "2018-03-01",
      "name": "[concat('High CPU Alert - ', parameters('projectName'))]",
      "location": "Global",
      "dependsOn": [
        "[resourceId('Microsoft.Insights/actionGroups', variables('actionGroupName'))]"
      ],
      "properties": {
        "description": "Alert when CPU usage is high",
        "severity": 2,
        "enabled": true,
        "scopes": [
          "[resourceGroup().id]"
        ],
        "evaluationFrequency": "PT5M",
        "windowSize": "PT15M",
        "criteria": {
          "odata.type": "Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria",
          "allOf": [
            {
              "name": "High CPU",
              "metricName": "Percentage CPU",
              "operator": "GreaterThan",
              "threshold": 80,
              "timeAggregation": "Average"
            }
          ]
        },
        "actions": [
          {
            "actionGroupId": "[resourceId('Microsoft.Insights/actionGroups', variables('actionGroupName'))]"
          }
        ]
      }
    },
    {
      "type": "Microsoft.Insights/metricAlerts",
      "apiVersion": "2018-03-01",
      "name": "[concat('High Memory Alert - ', parameters('projectName'))]",
      "location": "Global",
      "dependsOn": [
        "[resourceId('Microsoft.Insights/actionGroups', variables('actionGroupName'))]"
      ],
      "properties": {
        "description": "Alert when Memory usage is high",
        "severity": 2,
        "enabled": true,
        "scopes": [
          "[resourceGroup().id]"
        ],
        "evaluationFrequency": "PT5M",
        "windowSize": "PT15M",
        "criteria": {
          "odata.type": "Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria",
          "allOf": [
            {
              "name": "High Memory",
              "metricName": "MemoryWorkingSetBytes",
              "operator": "GreaterThan",
              "threshold": 1073741824,
              "timeAggregation": "Average"
            }
          ]
        },
        "actions": [
          {
            "actionGroupId": "[resourceId('Microsoft.Insights/actionGroups', variables('actionGroupName'))]"
          }
        ]
      }
    }
  ],
  "outputs": {
    "applicationInsightsName": {
      "type": "string",
      "value": "[variables('applicationInsightsName')]"
    },
    "instrumentationKey": {
      "type": "string",
      "value": "[reference(variables('applicationInsightsName')).InstrumentationKey]"
    },
    "connectionString": {
      "type": "string",
      "value": "[reference(variables('applicationInsightsName')).ConnectionString]"
    }
  }
}
```

---

## Plantilla 6: Container Apps Deployment
**Orden de ejecución: 6**
**Descripción: Despliegue de aplicaciones en Container Apps**

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "projectName": {
      "type": "string",
      "defaultValue": "paymentapp",
      "metadata": {
        "description": "Nombre base del proyecto"
      }
    },
    "location": {
      "type": "string",
      "defaultValue": "[resourceGroup().location]",
      "metadata": {
        "description": "Ubicación para todos los recursos"
      }
    },
    "environmentName": {
      "type": "string",
      "metadata": {
        "description": "Nombre del entorno de Container Apps existente"
      }
    },
    "backendImageName": {
      "type": "string",
      "metadata": {
        "description": "Nombre completo de la imagen Docker del backend"
      }
    },
    "frontendImageName": {
      "type": "string",
      "metadata": {
        "description": "Nombre completo de la imagen Docker del frontend"
      }
    },
    "registryServer": {
      "type": "string",
      "metadata": {
        "description": "Servidor del registro de contenedores"
      }
    },
    "registryUsername": {
      "type": "string",
      "metadata": {
        "description": "Usuario del registro de contenedores"
      }
    },
    "registryPassword": {
      "type": "securestring",
      "metadata": {
        "description": "Contraseña del registro de contenedores"
      }
    },
    "postgresConnectionString": {
      "type": "securestring",
      "metadata": {
        "description": "Cadena de conexión a PostgreSQL"
      }
    },
    "applicationInsightsConnectionString": {
      "type": "string",
      "metadata": {
        "description": "Connection string de Application Insights"
      }
    }
  },
  "variables": {
    "apiContainerAppName": "[concat('app-', parameters('projectName'), '-api')]",
    "frontendContainerAppName": "[concat('app-', parameters('projectName'), '-frontend')]"
  },
  "resources": [
    {
      "type": "Microsoft.App/containerApps",
      "apiVersion": "2023-05-01",
      "name": "[variables('apiContainerAppName')]",
      "location": "[parameters('location')]",
      "properties": {
        "managedEnvironmentId": "[resourceId('Microsoft.App/managedEnvironments', parameters('environmentName'))]",
        "configuration": {
          "secrets": [
            {
              "name": "postgres-connection-string",
              "value": "[parameters('postgresConnectionString')]"
            },
            {
              "name": "registry-password",
              "value": "[parameters('registryPassword')]"
            }
          ],
          "registries": [
            {
              "server": "[parameters('registryServer')]",
              "username": "[parameters('registryUsername')]",
              "passwordSecretRef": "registry-password"
            }
          ],
          "ingress": {
            "external": false,
            "targetPort": 8080,
            "transport": "auto",
            "traffic": [
              {
                "weight": 100,
                "latestRevision": true
              }
            ]
          }
        },
        "template": {
          "containers": [
            {
              "image": "[parameters('backendImageName')]",
              "name": "[variables('apiContainerAppName')]",
              "env": [
                {
                  "name": "ConnectionStrings__DefaultConnection",
                  "secretRef": "postgres-connection-string"
                },
                {
                  "name": "ASPNETCORE_ENVIRONMENT",
                  "value": "Production"
                },
                {
                  "name": "APPLICATIONINSIGHTS_CONNECTION_STRING",
                  "value": "[parameters('applicationInsightsConnectionString')]"
                }
              ],
              "resources": {
                "cpu": 0.5,
                "memory": "1Gi"
              }
            }
          ],
          "scale": {
            "minReplicas": 1,
            "maxReplicas": 5,
            "rules": [
              {
                "name": "http-scaling",
                "http": {
                  "metadata": {
                    "concurrentRequests": "100"
                  }
                }
              }
            ]
          }
        }
      }
    },
    {
      "type": "Microsoft.App/containerApps",
      "apiVersion": "2023-05-01",
      "name": "[variables('frontendContainerAppName')]",
      "location": "[parameters('location')]",
      "properties": {
        "managedEnvironmentId": "[resourceId('Microsoft.App/managedEnvironments', parameters('environmentName'))]",
        "configuration": {
          "secrets": [
            {
              "name": "registry-password",
              "value": "[parameters('registryPassword')]"
            }
          ],
          "registries": [
            {
              "server": "[parameters('registryServer')]",
              "username": "[parameters('registryUsername')]",
              "passwordSecretRef": "registry-password"
            }
          ],
          "ingress": {
            "external": false,
            "targetPort": 80,
            "transport": "auto",
            "traffic": [
              {
                "weight": 100,
                "latestRevision": true
              }
            ]
          }
        },
        "template": {
          "containers": [
            {
              "image": "[parameters('frontendImageName')]",
              "name": "[variables('frontendContainerAppName')]",
              "env": [
                {
                  "name": "REACT_APP_API_BASE_URL",
                  "value": "/api"
                },
                {
                  "name": "NODE_ENV",
                  "value": "production"
                }
              ],
              "resources": {
                "cpu": 0.25,
                "memory": "0.5Gi"
              }
            }
          ],
          "scale": {
            "minReplicas": 0,
            "maxReplicas": 3,
            "rules": [
              {
                "name": "http-scaling",
                "http": {
                  "metadata": {
                    "concurrentRequests": "50"
                  }
                }
              }
            ]
          }
        }
      }
    }
  ],
  "outputs": {
    "apiContainerAppName": {
      "type": "string",
      "value": "[variables('apiContainerAppName')]"
    },
    "frontendContainerAppName": {
      "type": "string",
      "value": "[variables('frontendContainerAppName')]"
    },
    "apiContainerAppFQDN": {
      "type": "string",
      "value": "[reference(variables('apiContainerAppName')).configuration.ingress.fqdn]"
    },
    "frontendContainerAppFQDN": {
      "type": "string",
      "value": "[reference(variables('frontendContainerAppName')).configuration.ingress.fqdn]"
    }
  }
}
```

---

## Instrucciones de Despliegue

⚠️ **¡ATENCIÓN! AQUÍ COMIENZA EL DESPLIEGUE REAL**

**🔴 PUNTO DE NO RETORNO**: Los comandos de esta sección **SÍ CREARÁN RECURSOS REALES** en Azure y **GENERARÁN COSTOS**.

**✅ ANTES DE CONTINUAR, ASEGÚRATE DE:**
1. Haber leído y entendido todas las secciones anteriores
2. Tener configuradas correctamente las variables en `variables.sh`
3. Haber ejecutado `az login` y estar autenticado
4. Haber creado el Resource Group con `az group create`
5. Haber validado las plantillas con `az deployment group validate`

**💡 RECOMENDACIÓN**: Ejecuta primero en un entorno de development/testing.

### Verificaciones Finales Pre-Despliegue:

```bash
# ▶️ EJECUTAR: Verificar variables críticas están definidas
echo "PROJECT_NAME: $PROJECT_NAME"
echo "RESOURCE_GROUP: $RESOURCE_GROUP"
echo "LOCATION: $LOCATION"
echo "POSTGRES_ADMIN_USER: $POSTGRES_ADMIN_USER"
echo "REGISTRY_USERNAME: $REGISTRY_USERNAME"
echo "BACKEND_IMAGE: $BACKEND_IMAGE"
echo "FRONTEND_IMAGE: $FRONTEND_IMAGE"

# ▶️ EJECUTAR: Verificar que existen los archivos de plantillas
ls -la templates/01-infrastructure.json
ls -la templates/02-postgresql.json
ls -la templates/03-containerenv.json
ls -la templates/04-appgateway.json
ls -la templates/05-monitoring.json
ls -la templates/06-containerapps.json

# ▶️ EJECUTAR: Verificar que existen los archivos de parámetros
ls -la parameters/01-infrastructure.$ENVIRONMENT.json
ls -la parameters/02-postgresql.$ENVIRONMENT.json
ls -la parameters/03-containerenv.$ENVIRONMENT.json
ls -la parameters/04-appgateway.$ENVIRONMENT.json
ls -la parameters/05-monitoring.$ENVIRONMENT.json
ls -la parameters/06-containerapps.$ENVIRONMENT.json

# ▶️ EJECUTAR: Validación final del Resource Group
az group show --name $RESOURCE_GROUP --output table
```

### ⚠️ Verificación Final Antes del Despliegue

```bash
# ▶️ EJECUTAR: Verificar que todas las variables críticas estén definidas
echo "📋 Verificando variables críticas..."
echo "PROJECT_NAME: ${PROJECT_NAME:?Variable PROJECT_NAME no está definida}"
echo "RESOURCE_GROUP: ${RESOURCE_GROUP:?Variable RESOURCE_GROUP no está definida}"
echo "LOCATION: ${LOCATION:?Variable LOCATION no está definida}"
echo "POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?Variable POSTGRES_PASSWORD no está definida}"

# ▶️ EJECUTAR: Verificar que estamos en el directorio correcto
pwd
ls -la templates/ 2>/dev/null || echo "❌ ERROR: No se encuentra el directorio templates/"

# ▶️ EJECUTAR: Verificar autenticación con Azure
az account show --query name -o tsv
```

### Orden de Ejecución Recomendado:

### ⚠️ PASO CRÍTICO: Validación What-if Antes de Cada Despliegue

```bash
# ▶️ EJECUTAR: What-if para cada plantilla ANTES del despliegue real
az deployment group what-if \
  --resource-group $RESOURCE_GROUP \
  --template-file templates/01-infrastructure.json \
  --parameters projectName=$PROJECT_NAME location=$LOCATION
```

1. **Plantilla 1**: Infraestructura Base
   ```bash
   # ▶️ EJECUTAR: Desplegar infraestructura base
   az deployment group create \
     --resource-group $RESOURCE_GROUP \
     --template-file templates/01-infrastructure.json \
     --parameters projectName=$PROJECT_NAME location=$LOCATION
   ```

2. **Plantilla 2**: PostgreSQL Database
   ```bash
   # ▶️ EJECUTAR: Desplegar base de datos PostgreSQL
   az deployment group create \
     --resource-group $RESOURCE_GROUP \
     --template-file templates/02-postgresql.json \
     --parameters projectName=$PROJECT_NAME administratorLoginPassword=$POSTGRES_PASSWORD
   ```

3. **Plantilla 3**: Container Apps Environment
   ```bash
   # ▶️ EJECUTAR: Desplegar entorno de Container Apps
   az deployment group create \
     --resource-group $RESOURCE_GROUP \
     --template-file templates/03-containerenv.json \
     --parameters projectName=$PROJECT_NAME vnetName=$VNET_NAME
   ```

⚠️ **PAUSA OBLIGATORIA**: Antes de continuar con la Plantilla 4, ejecutar:

```bash
# ▶️ EJECUTAR: Obtener FQDNs necesarios para Application Gateway
API_FQDN=$(az containerapp show --name "${PROJECT_NAME}-api" --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)
FRONTEND_FQDN=$(az containerapp show --name "${PROJECT_NAME}-frontend" --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)

echo "API FQDN: $API_FQDN"
echo "Frontend FQDN: $FRONTEND_FQDN"

# ⚠️ VERIFICAR: Que ambos FQDNs no estén vacíos antes de continuar
if [ -z "$API_FQDN" ] || [ -z "$FRONTEND_FQDN" ]; then
  echo "❌ ERROR: No se pudieron obtener los FQDNs. Verificar despliegue de Container Apps."
  exit 1
fi
```

4. **Plantilla 4**: Application Gateway
   ```bash
   # ▶️ EJECUTAR: Desplegar Application Gateway
   az deployment group create \
     --resource-group $RESOURCE_GROUP \
     --template-file templates/04-appgateway.json \
     --parameters projectName=$PROJECT_NAME vnetName=$VNET_NAME \
                  apiBackendFQDN=$API_FQDN frontendBackendFQDN=$FRONTEND_FQDN
   ```

5. **Plantilla 5**: Monitoreo y Alertas
   ```bash
   # ▶️ EJECUTAR: Desplegar monitoreo y alertas
   az deployment group create \
     --resource-group $RESOURCE_GROUP \
     --template-file templates/05-monitoring.json \
     --parameters projectName=$PROJECT_NAME logAnalyticsWorkspaceName=$LOG_WORKSPACE \
                  alertEmailAddress=$ALERT_EMAIL
   ```

6. **Plantilla 6**: Container Apps Deployment
   ```bash
   # ▶️ EJECUTAR: Desplegar Container Apps
   az deployment group create \
     --resource-group $RESOURCE_GROUP \
     --template-file templates/06-containerapps.json \
     --parameters projectName=$PROJECT_NAME environmentName=$ENV_NAME \
                  backendImageName=$BACKEND_IMAGE frontendImageName=$FRONTEND_IMAGE \
                  registryServer=$REGISTRY_SERVER registryUsername=$REGISTRY_USER \
                  registryPassword=$REGISTRY_PASSWORD postgresConnectionString=$POSTGRES_CONN_STRING \
                  applicationInsightsConnectionString=$APPINSIGHTS_CONN_STRING
   ```

### Variables Requeridas:

```bash
# 📖 SOLO LECTURA: Variables principales (ya configuradas en variables.sh)
PROJECT_NAME="paymentapp"
RESOURCE_GROUP="rg-containerapp-demo"
LOCATION="eastus"

# PostgreSQL
POSTGRES_PASSWORD="YourComplexPassword123!"

# Container Registry (GitHub o ACR)
REGISTRY_SERVER="ghcr.io"  # o "$ACR_NAME.azurecr.io"
REGISTRY_USER="your-github-username"  # o "$ACR_NAME"
REGISTRY_PASSWORD="your-github-token"  # o "$ACR_PASSWORD"

# Imágenes
BACKEND_IMAGE="ghcr.io/your-username/payment-api:latest"
FRONTEND_IMAGE="ghcr.io/your-username/payment-frontend:latest"

# Monitoreo
ALERT_EMAIL="admin@yourcompany.com"

# ⚠️ IMPORTANTE: Variables adicionales necesarias para el despliegue
# ▶️ EJECUTAR: Configurar variables derivadas (ejecutar después de cargar variables.sh)
export VNET_NAME="${PROJECT_NAME}-vnet"
export ENV_NAME="${PROJECT_NAME}-containerenv"
export LOG_WORKSPACE="${PROJECT_NAME}-logs"
export API_FQDN=""      # Se obtiene después del despliegue de Container Apps
export FRONTEND_FQDN="" # Se obtiene después del despliegue de Container Apps
export POSTGRES_CONN_STRING="" # Se construye después del despliegue de PostgreSQL
export APPINSIGHTS_CONN_STRING="" # Se obtiene después del despliegue de Application Insights
```

### ⚠️ NOTA IMPORTANTE: Variables Dinámicas

Algunas variables como `API_FQDN` y `FRONTEND_FQDN` se obtienen **DESPUÉS** de desplegar las Container Apps. **NO ejecutes la Plantilla 4 (Application Gateway) hasta obtener estos valores**.

```bash
# ▶️ EJECUTAR: Obtener FQDNs después del despliegue de Container Apps
API_FQDN=$(az containerapp show --name "${PROJECT_NAME}-api" --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)
FRONTEND_FQDN=$(az containerapp show --name "${PROJECT_NAME}-frontend" --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)

echo "API FQDN: $API_FQDN"
echo "Frontend FQDN: $FRONTEND_FQDN"
```

---

## Troubleshooting y Mejores Prácticas

### Errores Comunes y Soluciones

#### 1. Error: "The template deployment failed because of policy violation"

**Síntoma:**
```
ERROR: {"error":{"code":"RequestDisallowedByPolicy","message":"Resource 'myresource' was disallowed by policy"}}
```

**Causas comunes:**
- Políticas organizacionales que restringen ciertos tipos de recursos
- Políticas de nombrado que no se están siguiendo
- Políticas de ubicación que restringen regiones

**Solución:**
```bash
# Verificar políticas aplicadas al grupo de recursos
az policy assignment list --resource-group $RESOURCE_GROUP --output table

# Contactar al administrador de Azure para revisar políticas
# O ajustar la plantilla para cumplir con las políticas existentes
```

#### 2. Error: "The resource name is invalid"

**Síntoma:**
```
ERROR: The storage account name 'MyStorage123!' is not valid. Storage account names must be between 3 and 24 characters in length and use numbers and lower-case letters only.
```

**Solución:**
```json
{
  "variables": {
    "storageAccountName": "[toLower(concat(parameters('projectName'), 'storage', substring(uniqueString(resourceGroup().id), 0, 8)))]"
  }
}
```

#### 3. Error: "Resource already exists"

**Síntoma:**
```
ERROR: The resource name 'myresource' already exists in the resource group.
```

**Solución:**
```json
{
  "variables": {
    "uniqueSuffix": "[uniqueString(resourceGroup().id)]",
    "resourceName": "[concat(parameters('baseName'), '-', variables('uniqueSuffix'))]"
  }
}
```

#### 4. Error: "Deployment template validation failed"

**Síntoma:**
```
ERROR: The template is not valid. Template language expression property 'reference' cannot be evaluated.
```

**Causa común:** Intentar usar `reference()` en variables antes de que el recurso exista.

**Solución:** Usar `reference()` solo en outputs o en recursos que tienen dependencia explícita.

#### 5. Error: "Insufficient permissions"

**Síntoma:**
```
ERROR: The client does not have authorization to perform action 'Microsoft.Resources/subscriptions/resourceGroups/write'
```

**Solución:**
```bash
# Verificar tus permisos actuales
az role assignment list --assignee $(az account show --query user.name -o tsv) --output table

# Solicitar permisos de Contributor o Owner al administrador de la suscripción
```

#### 6. Error: "Quota exceeded"

**Síntoma:**
```
ERROR: Operation could not be completed as it results in exceeding approved quota.
```

**Solución:**
```bash
# Verificar uso actual de cuotas
az vm list-usage --location $LOCATION --output table

# Solicitar aumento de cuota a través del portal de Azure
# Support -> New support request -> Service and subscription limits (quotas)
```

### Mejores Prácticas

#### 1. Nomenclatura y Organización

**Convención de nombres recomendada:**
```json
{
  "variables": {
    "resourcePrefix": "[concat(parameters('projectName'), '-', parameters('environment'))]",
    "storageAccountName": "[toLower(concat(parameters('projectName'), parameters('environment'), 'storage', substring(uniqueString(resourceGroup().id), 0, 6)))]",
    "vmName": "[concat(variables('resourcePrefix'), '-vm')]",
    "vnetName": "[concat(variables('resourcePrefix'), '-vnet')]"
  }
}
```

**Estructura de archivos:**
```
azure-arm-project/
├── templates/
│   ├── main.json                    # Plantilla principal
│   ├── nested/
│   │   ├── networking.json          # Plantillas anidadas
│   │   ├── compute.json
│   │   └── storage.json
├── parameters/
│   ├── dev.parameters.json          # Parámetros por ambiente
│   ├── test.parameters.json
│   └── prod.parameters.json
├── scripts/
│   ├── deploy.sh                    # Scripts de despliegue
│   ├── validate.sh                  # Scripts de validación
│   └── cleanup.sh                   # Scripts de limpieza
└── docs/
    ├── architecture.md              # Documentación de arquitectura
    └── deployment-guide.md          # Guía de despliegue
```

#### 2. Seguridad y Secretos

**❌ NUNCA hagas esto:**
```json
{
  "parameters": {
    "adminPassword": {
      "defaultValue": "Password123!",
      "type": "string"
    }
  }
}
```

**✅ Haz esto en su lugar:**
```json
{
  "parameters": {
    "adminPassword": {
      "type": "securestring",
      "metadata": {
        "description": "Contraseña del administrador (debe cumplir políticas de complejidad)"
      }
    }
  }
}
```

**Usar Azure Key Vault para secretos:**
```json
{
  "parameters": {
    "adminPassword": {
      "reference": {
        "keyVault": {
          "id": "/subscriptions/{subscription-id}/resourceGroups/{rg}/providers/Microsoft.KeyVault/vaults/{vault}"
        },
        "secretName": "adminPassword"
      }
    }
  }
}
```

#### 3. Manejo de Dependencias

**Dependencias explícitas cuando sea necesario:**
```json
{
  "type": "Microsoft.Compute/virtualMachines",
  "dependsOn": [
    "[resourceId('Microsoft.Network/networkInterfaces', variables('nicName'))]",
    "[resourceId('Microsoft.Storage/storageAccounts', variables('storageAccountName'))]"
  ]
}
```

**Usar conditional deployment:**
```json
{
  "condition": "[equals(parameters('deployOptionalResource'), 'yes')]",
  "type": "Microsoft.Storage/storageAccounts",
  "name": "[variables('optionalStorageAccountName')]"
}
```

#### 4. Tagging y Metadata

**Implementar tags consistentes:**
```json
{
  "variables": {
    "commonTags": {
      "Environment": "[parameters('environment')]",
      "Project": "[parameters('projectName')]",
      "Owner": "[parameters('ownerEmail')]",
      "CostCenter": "[parameters('costCenter')]",
      "CreatedBy": "ARM Template",
      "CreatedDate": "[utcNow('yyyy-MM-dd')]"
    }
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "tags": "[variables('commonTags')]"
    }
  ]
}
```

#### 5. Outputs Útiles

**Proporciona información relevante:**
```json
{
  "outputs": {
    "resourceGroupName": {
      "type": "string",
      "value": "[resourceGroup().name]"
    },
    "deploymentName": {
      "type": "string",
      "value": "[deployment().name]"
    },
    "primaryEndpoint": {
      "type": "string",
      "value": "[reference(variables('storageAccountName')).primaryEndpoints.blob]"
    },
    "connectionStrings": {
      "type": "object",
      "value": {
        "storage": "[concat('DefaultEndpointsProtocol=https;AccountName=', variables('storageAccountName'), ';AccountKey=', listKeys(resourceId('Microsoft.Storage/storageAccounts', variables('storageAccountName')), '2023-01-01').keys[0].value)]"
      }
    }
  }
}
```

#### 6. Testing y Validación

**Script de validación completa:**
```bash
#!/bin/bash

# validate-template.sh
echo "🔍 Validando plantilla ARM..."

# Validar sintaxis JSON
echo "📋 Verificando sintaxis JSON..."
for template in templates/*.json; do
    echo "  Validando: $template"
    python -m json.tool "$template" > /dev/null || {
        echo "❌ Error de sintaxis JSON en $template"
        exit 1
    }
done

# Validar con Azure CLI
echo "☁️ Validando con Azure CLI..."
az deployment group validate \
    --resource-group $RESOURCE_GROUP \
    --template-file templates/main.json \
    --parameters @parameters/dev.parameters.json || {
    echo "❌ Validación de Azure falló"
    exit 1
}

# What-if analysis
echo "🔮 Ejecutando análisis what-if..."
az deployment group what-if \
    --resource-group $RESOURCE_GROUP \
    --template-file templates/main.json \
    --parameters @parameters/dev.parameters.json

echo "✅ Validación completada exitosamente"
```

#### 7. Monitoreo y Alertas

**Configurar alertas para despliegues:**
```bash
# Crear alerta para despliegues fallidos
az monitor activity-log alert create \
    --name "ARM Deployment Failed" \
    --resource-group $RESOURCE_GROUP \
    --condition category=Administrative operationName=Microsoft.Resources/deployments/write level=Error \
    --action-group "/subscriptions/{subscription}/resourceGroups/{rg}/providers/microsoft.insights/actionGroups/{ag}"
```

### Comandos Útiles para Debugging

#### Ver logs detallados de despliegue:
```bash
# Obtener detalles del último despliegue
LAST_DEPLOYMENT=$(az deployment group list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)

# Ver operaciones detalladas
az deployment operation group list \
    --resource-group $RESOURCE_GROUP \
    --name $LAST_DEPLOYMENT \
    --query "[?properties.provisioningState=='Failed'].{Resource:properties.targetResource.resourceName, Error:properties.statusMessage}" \
    --output table
```

#### Limpiar despliegues fallidos:
```bash
# Listar despliegues
az deployment group list --resource-group $RESOURCE_GROUP --output table

# Eliminar despliegue específico
az deployment group delete --resource-group $RESOURCE_GROUP --name "deployment-name"
```

#### Exportar recursos existentes como plantilla:
```bash
# Exportar grupo de recursos completo
az group export --resource-group $RESOURCE_GROUP > exported-template.json

# Exportar recursos específicos
az resource list --resource-group $RESOURCE_GROUP --query "[?type=='Microsoft.Storage/storageAccounts']" --output json
```

### Recursos Adicionales

1. **Documentación Oficial:**
   - [ARM Template Reference](https://docs.microsoft.com/azure/templates/)
   - [ARM Template Functions](https://docs.microsoft.com/azure/azure-resource-manager/templates/template-functions)
   - [Best Practices](https://docs.microsoft.com/azure/azure-resource-manager/templates/template-best-practices)

2. **Herramientas útiles:**
   - [ARM Template Visualizer](https://github.com/Azure/arm-visualizer)
   - [ARM TTK (Template Test Toolkit)](https://github.com/Azure/arm-ttk)
   - [Bicep](https://docs.microsoft.com/azure/azure-resource-manager/bicep/) - DSL más amigable para ARM

3. **Comunidad:**
   - [Azure Quickstart Templates](https://github.com/Azure/azure-quickstart-templates)
   - [Azure Resource Manager Forum](https://docs.microsoft.com/answers/topics/azure-resource-manager.html)

### Checklist Pre-Producción

Antes de desplegar en producción, verifica:

- [ ] ✅ **Seguridad**: Todos los secretos están en Key Vault
- [ ] ✅ **Naming**: Convenciones de nombres consistentes
- [ ] ✅ **Tags**: Tags apropiados para facturación y gestión
- [ ] ✅ **Regions**: Región correcta para compliance y latencia
- [ ] ✅ **Sizing**: SKUs apropiados para la carga esperada
- [ ] ✅ **Backup**: Estrategia de backup configurada
- [ ] ✅ **Monitoring**: Alertas y métricas configuradas
- [ ] ✅ **Testing**: Plantilla validada en entorno de test
- [ ] ✅ **Documentation**: Documentación actualizada
- [ ] ✅ **Rollback**: Plan de rollback preparado

¡Con esta guía completa, cualquier ingeniero con poca experiencia debería poder entender, implementar y mantener estas plantillas ARM exitosamente! 🚀

---

## 📝 **RESUMEN FINAL PARA INGENIEROS**

### **🔍 COMANDOS SOLO PARA LEER (No ejecutar)**
- Ejemplos marcados con 📖
- Plantillas JSON (código de las templates)
- Outputs de ejemplo
- Códigos de error de muestra

### **▶️ COMANDOS PARA EJECUTAR**
- Verificaciones: `az --version`, `az login`, `az account show`
- Preparación: `mkdir`, `source variables.sh`, `az group create`
- Validaciones: `az deployment group validate`, `az deployment group what-if`
- Despliegues: `az deployment group create` (solo en sección "Instrucciones de Despliegue")

### **🚫 COMANDOS PELIGROSOS (No ejecutar sin confirmación)**
- Modo Complete: `--mode Complete`
- Eliminaciones: `az group delete`
- Scripts de limpieza

### **⚠️ FLUJO RECOMENDADO**
1. **Leer secciones 1-7** → Solo comandos de verificación ▶️
2. **Configurar variables** → Personalizar `variables.sh`
3. **Validar plantillas** → `az deployment group validate` y `what-if`
4. **Sección 8+** → Ejecutar comandos de despliegue real ▶️

**💡 REGLA DE ORO**: Si tienes dudas sobre un comando, léelo primero como 📖 antes de ejecutarlo como ▶️
