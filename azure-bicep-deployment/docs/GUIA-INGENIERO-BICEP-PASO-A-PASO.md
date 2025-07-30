# 🎓 Guía PASO A PASO: BICEP Azure para Ingenieros Principiantes

## 🎯 **OBJETIVO GENERAL**
> **Al finalizar esta guía, serás capaz de:**
> - ✅ Entender qué es BICEP y por qué es mejor que ARM Templates
> - ✅ Desplegar una aplicación completa de pagos en Azure usando BICEP
> - ✅ Cumplir con Azure Policies empresariales (governance)
> - ✅ Validar que todo funciona correctamente
> - ✅ Hacer troubleshooting básico con BICEP
> - ✅ Tener confianza para modificar y expandir templates BICEP

## 🧠 **CARACTERÍSTICAS DE APRENDIZAJE:**

### ✅ **"¿Qué estamos haciendo?"** - Explicación del objetivo
### ✅ **"¿Por qué?"** - Justificación pedagógica  
### ✅ **"¿Qué esperar?"** - Resultados esperados
### ✅ **"✅ CHECKPOINT"** - Validación de comprensión
### ✅ **"🎓 APRENDIZAJE"** - Conceptos clave
### ✅ **"🎉 LOGRO"** - Celebración de progreso

## 📚 **CONOCIMIENTOS QUE APRENDERÁS**
- 🏗️ **Infrastructure as Code** con BICEP DSL
- 🏛️ **Azure Policy compliance** empresarial
- 🐳 **Container Apps** y microservicios
- 📊 **Monitoring** y observabilidad
- 🔐 **Security** y networking en Azure
- 🎨 **BICEP sintaxis** moderna y limpia

---

## 📋 Índice Detallado
1. [🚀 FASE 0: Setup y Preparación](#fase-0-setup-y-preparación)
2. [🎯 FASE 1: Tu Primer "Hello BICEP"](#fase-1-tu-primer-hello-bicep)
3. [🔍 FASE 2: Entender la Estructura BICEP](#fase-2-entender-la-estructura-bicep)
4. [🏗️ FASE 3: Deploy Paso a Paso por Módulos](#fase-3-deploy-paso-a-paso-por-módulos)
5. [🚀 FASE 4: Deploy Completo del Sistema](#fase-4-deploy-completo-del-sistema)
6. [✅ FASE 5: Validación y Testing](#fase-5-validación-y-testing)
7. [🔧 FASE 6: Troubleshooting y Debugging](#fase-6-troubleshooting-y-debugging)
8. [🧹 FASE 7: Cleanup y Mejores Prácticas](#fase-7-cleanup-y-mejores-prácticas)

---

## 🚀 FASE 0: Setup y Preparación

### 📋 **Checklist Pre-Requisitos**

#### ✅ **Paso 0.1: Verificar Acceso a Azure**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Verificar que tenemos acceso a Azure
# ¿POR QUÉ? Sin acceso no podemos crear recursos con BICEP

# Login a Azure
az login

# ¿Qué esperar? Una ventana de browser se abre para login
# Resultado esperado: "You have logged in. Now let us find all the subscriptions..."

# Verificar subscription
az account show

# ¿Qué buscar? Que aparezca tu subscription ID y que "state": "Enabled"
```

**🎯 OBJETIVO LOGRADO:** Tienes acceso confirmado a Azure ✅

#### ✅ **Paso 0.2: Verificar BICEP CLI**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Verificar que BICEP está disponible
# ¿POR QUÉ? BICEP viene incluido con Azure CLI moderna

# Verificar Azure CLI version (debe ser reciente)
az --version

# ¿Qué esperar? azure-cli 2.20.0 o superior

# Verificar BICEP
az bicep version

# ¿Qué esperar? 
# Bicep CLI version X.X.X (algo como 0.15.x o superior)
# Si no está disponible: az bicep install
```

**🎯 OBJETIVO LOGRADO:** BICEP CLI instalado y funcionando ✅

#### ✅ **Paso 0.3: Configurar VS Code (Opcional pero Recomendado)**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Instalar extensions útiles para BICEP
# ¿POR QUÉ? VS Code tiene el MEJOR soporte para BICEP con IntelliSense

# Extensions ESENCIALES para BICEP:
# 1. Bicep - Syntax highlighting, validation, IntelliSense
# 2. Azure Resource Manager (ARM) Tools - Helpers adicionales
# 3. Azure Account - Login integrado
```

**🎯 OBJETIVO LOGRADO:** Environment de desarrollo listo ✅

---

## 🎯 FASE 1: Tu Primer "Hello BICEP"

### 🎓 **OBJETIVO DE APRENDIZAJE**
> Entender la sintaxis BICEP y el flujo: escribir código → compilar → desplegar → verificar

### ✅ **Paso 1.1: Crear tu Primer Resource Group con BICEP**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Crear el recurso más simple en Azure con BICEP
# ¿POR QUÉ? Para entender la sintaxis BICEP sin complejidad

# 1. Crear directorio de práctica
mkdir bicep-hello
cd bicep-hello

# 2. Crear archivo hello.bicep
cat > hello.bicep << 'EOF'
// Tu primer template BICEP - ¡Qué limpio comparado con ARM JSON!

targetScope = 'subscription'  // Nivel de despliegue

// Parámetros - ¡Mucho más limpio que ARM!
@description('Nombre del proyecto')
param projectName string = 'HelloBICEP'

@description('Ubicación para recursos')
@allowed(['canadacentral', 'eastus'])  // Azure Policy compliance
param location string = 'canadacentral'

// Variable computada - ¡Sintaxis súper clara!
var resourceGroupName = 'rg-${projectName}-hello'

// Resource Group - ¡Compara esto con ARM JSON!
resource helloRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: {
    Project: projectName        // IMPORTANTE: Azure Policy requiere este tag
    Purpose: 'Learning-BICEP'
    CreatedBy: 'BICEP-Template'
  }
}

// Output - Para ver el resultado
output resourceGroupName string = helloRG.name
output resourceGroupId string = helloRG.id
EOF

echo "🎓 APRENDIZAJE: ¡Mira qué limpio es BICEP comparado con ARM JSON!"
echo "- Parámetros con @description"
echo "- Variables con 'var'"  
echo "- Resources con sintaxis clara"
echo "- No más JSON verboso"
```

### ✅ **Paso 1.2: El Flujo Mágico de BICEP**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Seguir el flujo: build → validate → deploy
# ¿POR QUÉ? BICEP se compila a ARM y luego se despliega

# 1. BUILD (compilar BICEP a ARM)
az bicep build --file hello.bicep

# ¿Qué esperar?
# Se crea hello.json - ¡Mira qué complejo es el ARM generado!
# BICEP es 70% menos código que ARM equivalent

echo "✅ CHECKPOINT: ¿Se creó hello.json? Ese es el ARM compilado desde BICEP."

# 2. VALIDATE (validar el template)
az deployment sub validate \
  --location canadacentral \
  --template-file hello.bicep \
  --parameters projectName=HelloBICEP

# ¿Qué esperar?
# Validación exitosa con detalles del deployment

echo "✅ CHECKPOINT: ¿La validación dice que es exitosa? BICEP está bien escrito."

# 3. DEPLOY (crear recursos reales)
az deployment sub create \
  --location canadacentral \
  --template-file hello.bicep \
  --parameters projectName=HelloBICEP

# ¿Qué esperar?
# Deploy que toma 1-2 minutos
# Output con resourceGroupName

echo "✅ CHECKPOINT: ¿Ves el output con resourceGroupName? ¡Creaste tu primer recurso con BICEP!"
```

### ✅ **Paso 1.3: Verificar en Azure Portal**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Confirmar que el recurso existe en Azure
# ¿POR QUÉ? Para verificar que BICEP realmente creó algo

# Verificar con Azure CLI
az group show --name "rg-HelloBICEP-hello"

# ¿Qué esperar?
# JSON con información del resource group
# "provisioningState": "Succeeded"
# Tags incluyendo Project: "HelloBICEP"

echo "🎓 APRENDIZAJE: BICEP compiló a ARM y ARM creó el recurso"
echo "También puedes ir a Azure Portal → Resource Groups → buscar 'rg-HelloBICEP-hello'"
```

### ✅ **Paso 1.4: Comparar BICEP vs ARM Generado**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Entender la magia de BICEP
# ¿POR QUÉ? Para apreciar por qué BICEP es mejor que ARM directo

echo "🎓 APRENDIZAJE: Comparación BICEP vs ARM"

# Ver tu BICEP limpio
echo "=== TU CÓDIGO BICEP (limpio) ==="
wc -l hello.bicep
echo "Líneas en BICEP: $(wc -l < hello.bicep)"

# Ver el ARM generado (complejo)
echo -e "\n=== ARM GENERADO (complejo) ==="
wc -l hello.json
echo "Líneas en ARM: $(wc -l < hello.json)"

echo -e "\n🎉 LOGRO: ¡BICEP es ~70% menos código que ARM equivalent!"
```

### ✅ **Paso 1.5: Limpiar (Importante para Costos)**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Eliminar el recurso de prueba
# ¿POR QUÉ? Para evitar costos innecesarios

az group delete --name "rg-HelloBICEP-hello" --yes --no-wait

echo "✅ CHECKPOINT: ¿Ejecutaste el delete? El RG se eliminará en background."

# Limpiar archivos locales
cd ..
rm -rf bicep-hello

echo "🎉 LOGRO: Limpiaste correctamente y aprendiste el flujo básico BICEP"
```

**🎯 OBJETIVO LOGRADO:** Entiendes el flujo básico de BICEP ✅

---

## 🔍 FASE 2: Entender la Estructura BICEP

### 🎓 **OBJETIVO DE APRENDIZAJE**
> Navegar y entender la organización del proyecto real de pagos en BICEP

### ✅ **Paso 2.1: Explorar la Estructura**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Familiarizarnos con la organización del proyecto
# ¿POR QUÉ? Para no perdernos en la complejidad del sistema real

cd /home/erdnando/proyectos/azure/GuiaAzureApp/azure-bicep-deployment

# Ver estructura general
tree -L 2

# ¿Qué esperar?
# ├── main.bicep              <- Orquestador principal
# ├── modules/                <- Módulos reutilizables  
# ├── parameters/             <- Configuración por ambiente
# └── scripts/                <- Automatización

echo "✅ CHECKPOINT: ¿Ves 4 elementos principales? main.bicep, modules, parameters, scripts"
```

### ✅ **Paso 2.2: Entender el Archivo Principal**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Leer y entender main.bicep
# ¿POR QUÉ? Es el punto de entrada que coordina todo

# Ver las primeras líneas
head -20 main.bicep

echo "🎓 APRENDIZAJE: main.bicep es como un 'director de orquesta' que llama a cada módulo"

# Buscar las llamadas a módulos
grep -n "module " main.bicep

# ¿Qué esperar?
# module infrastructure
# module database
# module monitoring
# module containerApps
# module applicationGateway

echo "✅ CHECKPOINT: ¿Ves varios módulos listados? Estos son los componentes del sistema"
```

### ✅ **Paso 2.3: Explorar un Módulo Simple**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Entender cómo está organizado un módulo BICEP
# ¿POR QUÉ? Los módulos son como "LEGO blocks" reutilizables

# Explorar el módulo de infrastructure
ls -la modules/infrastructure/

# ¿Qué esperar?
# main.bicep      <- Recursos del módulo

echo "🎓 APRENDIZAJE: En BICEP, cada módulo es un archivo .bicep que puedes reutilizar"

# Ver qué crea este módulo
grep -n "resource " modules/infrastructure/main.bicep

echo "✅ CHECKPOINT: ¿Ves varios recursos que empiezan con 'resource'? Son recursos de Azure"
```

### ✅ **Paso 2.4: Entender Configuración por Ambientes**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Ver diferencias entre dev y prod
# ¿POR QUÉ? Para entender cómo se configura cada ambiente

# Comparar configuraciones
echo "=== DESARROLLO ==="
cat parameters/parameters-dev.json | jq .

echo -e "\n=== PRODUCCIÓN ==="  
cat parameters/parameters-prod.json | jq .

echo "🎓 APRENDIZAJE: Dev usa recursos pequeños/baratos, Prod usa recursos grandes/robustos"

echo "✅ CHECKPOINT: ¿Ves diferencias en valores entre dev y prod?"
```

### ✅ **Paso 2.5: La Magia de la Sintaxis BICEP**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Apreciar por qué BICEP es mejor que ARM
# ¿POR QUÉ? Para entender las ventajas de BICEP

echo "🎓 APRENDIZAJE: Ventajas de BICEP vs ARM Templates"

# Mostrar ejemplos de sintaxis limpia
echo "=== BICEP (limpio) ==="
echo "resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {"
echo "  name: 'myStorageAccount'"
echo "  location: location"
echo "}"

echo -e "\n=== ARM Equivalent (verboso) ==="
echo "\"resources\": ["
echo "  {"
echo "    \"type\": \"Microsoft.Storage/storageAccounts\","
echo "    \"apiVersion\": \"2021-02-01\","
echo "    \"name\": \"myStorageAccount\","
echo "    \"location\": \"[parameters('location')]\""
echo "  }"
echo "]"

echo -e "\n🎉 LOGRO: ¡Entiendes por qué BICEP es más fácil de escribir y leer!"
```

**🎯 OBJETIVO LOGRADO:** Entiendes la organización del proyecto BICEP ✅

---

## 🏗️ FASE 3: Deploy Paso a Paso por Módulos

### 🎓 **OBJETIVO DE APRENDIZAJE**
> Desplegar cada componente individualmente para entender dependencias

### ✅ **Paso 3.1: Preparar el Ambiente**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Preparar Azure para recibir nuestro deployment
# ¿POR QUÉ? Necesitamos un Resource Group destino para BICEP

# Asegurar que estamos en el directorio correcto
cd azure-bicep-deployment
pwd

# Crear Resource Group para el proyecto
az group create \
  --name "rg-PaymentSystem-dev" \
  --location "canadacentral"

# ¿Qué esperar?
# "provisioningState": "Succeeded"

echo "✅ CHECKPOINT: ¿El RG se creó exitosamente? Ahora tenemos destino para deployment."
```

### ✅ **Paso 3.2: Validar Azure Policy Compliance**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Verificar que cumplimos con las políticas organizacionales
# ¿POR QUÉ? Para evitar errores de compliance al desplegar

# Ejecutar script de validación
./scripts/validate-bicep-azure-policies.sh

# ¿Qué esperar?
# ✅ Project tag validation: PASSED
# ✅ Location policy validation: PASSED
# ✅ All governance tags present: PASSED
# ✅ BICEP syntax validation: PASSED

echo "✅ CHECKPOINT: ¿Todos los checks aparecen como PASSED? Si no, revisar la configuración"
```

### ✅ **Paso 3.3: Deploy Sistema Completo (BICEP es Más Simple)**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Desplegar todo el sistema de pagos
# ¿POR QUÉ? En BICEP es más simple hacer deploy completo que módulo por módulo

echo "🎯 OBJETIVO: Crear sistema completo de pagos con BICEP"

# Validar template primero
az deployment group validate \
  --resource-group "rg-PaymentSystem-dev" \
  --template-file main.bicep \
  --parameters @parameters/parameters-dev.json

# ¿Qué esperar?
# Validación exitosa sin errores

echo "✅ CHECKPOINT: ¿La validación fue exitosa? El template BICEP está bien formado."

# Deploy completo
az deployment group create \
  --resource-group "rg-PaymentSystem-dev" \
  --template-file main.bicep \
  --parameters @parameters/parameters-dev.json \
  --name "payment-system-deployment"

# ¿Qué esperar?
# Deploy que toma 15-20 minutos
# ~25-30 recursos creados
# Outputs con información importante

echo "🎉 LOGRO: Sistema completo desplegado con BICEP en una sola ejecución"
```

### ✅ **Paso 3.4: Monitorear el Progreso del Deploy**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Seguir el progreso del deployment
# ¿POR QUÉ? Para entender qué se está creando y en qué orden

# Ver el progreso en tiempo real (en otra terminal)
watch -n 30 "az deployment group show \
  --resource-group 'rg-PaymentSystem-dev' \
  --name 'payment-system-deployment' \
  --query 'properties.provisioningState'"

# También puedes ver en Azure Portal:
echo "🎓 APRENDIZAJE: Ve a Azure Portal → Resource Groups → rg-PaymentSystem-dev → Deployments"
echo "Ahí puedes ver gráficamente cómo se despliegan los recursos"

echo "✅ CHECKPOINT: ¿Puedes ver el progreso del deployment en Azure Portal?"
```

**🎯 OBJETIVO LOGRADO:** Sistema completo desplegado con BICEP ✅

---

## 🚀 FASE 4: Deploy Completo del Sistema

### 🎓 **OBJETIVO DE APRENDIZAJE**
> Entender la potencia y simplicidad de BICEP para deployments complejos

### ✅ **Paso 4.1: Verificar Recursos Creados**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Inspeccionar qué se creó con nuestro template BICEP
# ¿POR QUÉ? Para entender la infraestructura que acabamos de desplegar

# Listar todos los recursos creados
az resource list \
  --resource-group "rg-PaymentSystem-dev" \
  --output table

# ¿Qué esperar?
# ~25-30 recursos incluyendo:
# - Virtual Network y subnets
# - Container App Environment
# - Container Apps
# - Application Gateway
# - PostgreSQL server
# - Log Analytics Workspace
# - Storage Account
# - Key Vault

echo "🎓 APRENDIZAJE: ¡BICEP creó toda esta infraestructura compleja con un solo comando!"

echo "✅ CHECKPOINT: ¿Ves todos estos tipos de recursos listados?"
```

### ✅ **Paso 4.2: Verificar Outputs del Template**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Obtener información clave del deployment
# ¿POR QUÉ? Los outputs nos dan URLs, IPs, y conexiones importantes

# Ver outputs del deployment
az deployment group show \
  --resource-group "rg-PaymentSystem-dev" \
  --name "payment-system-deployment" \
  --query "properties.outputs"

# ¿Qué esperar?
# Outputs con:
# - applicationGatewayPublicIP
# - postgresqlFQDN  
# - logAnalyticsWorkspaceId
# - containerAppEnvironmentId

echo "✅ CHECKPOINT: ¿Ves outputs con IPs, FQDNs, y IDs de recursos importantes?"
```

### ✅ **Paso 4.3: Verificar Azure Policy Compliance Post-Deploy**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Confirmar que todo cumple con governance post-deployment
# ¿POR QUÉ? Para asegurar que el deployment cumple políticas organizacionales

# Re-ejecutar validación post-deploy
./scripts/validate-bicep-azure-policies.sh

# Verificar tags en recursos específicos
az resource show \
  --resource-group "rg-PaymentSystem-dev" \
  --name "law-paymentsystem-dev" \
  --resource-type "Microsoft.OperationalInsights/workspaces" \
  --query "tags"

# ¿Qué esperar?
# Tags incluyendo:
# - Project: "PaymentSystem"
# - Environment: "dev"  
# - Compliance: "Azure-Policy-Compliant"

echo "🎉 LOGRO: Deployment completo y compliant con Azure Policies"
```

**🎯 OBJETIVO LOGRADO:** Sistema completo funcionando con BICEP ✅

---

## ✅ FASE 5: Validación y Testing

### 🎓 **OBJETIVO DE APRENDIZAJE**
> Verificar que todo funciona y entender cómo validar deployments BICEP

### ✅ **Paso 5.1: Testing de Conectividad**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Probar que los componentes se comunican
# ¿POR QUÉ? Para verificar que el networking y aplicaciones funcionan

echo "🎯 OBJETIVO: Verificar conectividad end-to-end"

# Obtener IP pública del Application Gateway
PUBLIC_IP=$(az deployment group show \
  --resource-group "rg-PaymentSystem-dev" \
  --name "payment-system-deployment" \
  --query "properties.outputs.applicationGatewayPublicIP.value" \
  --output tsv)

echo "IP Pública del sistema: $PUBLIC_IP"

# Test básico de conectividad
echo "Probando conectividad básica..."
curl -f -m 10 http://$PUBLIC_IP/ || echo "⚠️ App aún iniciando o endpoint no configurado"

echo "✅ CHECKPOINT: ¿Obtuviste una IP pública válida?"
```

### ✅ **Paso 5.2: Verificar Container Apps**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Verificar que las aplicaciones están ejecutándose
# ¿POR QUÉ? Para confirmar que Container Apps se desplegaron correctamente

# Listar Container Apps
az containerapp list \
  --resource-group "rg-PaymentSystem-dev" \
  --output table

# Ver estado de una app específica
az containerapp show \
  --name "ca-payment-api-dev" \
  --resource-group "rg-PaymentSystem-dev" \
  --query "properties.runningStatus"

# ¿Qué esperar?
# runningStatus: "Running"

echo "🎓 APRENDIZAJE: BICEP desplegó Container Apps que ahora están ejecutándose"

echo "✅ CHECKPOINT: ¿Las Container Apps muestran estado 'Running'?"
```

### ✅ **Paso 5.3: Verificar Base de Datos PostgreSQL**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Confirmar que la base de datos está disponible
# ¿POR QUÉ? Para verificar que el backend de datos funciona

# Verificar PostgreSQL server
az postgres flexible-server show \
  --name "psql-paymentsystem-dev" \
  --resource-group "rg-PaymentSystem-dev" \
  --query "state"

# ¿Qué esperar?
# state: "Ready"

# Verificar conectividad privada
az postgres flexible-server list \
  --resource-group "rg-PaymentSystem-dev" \
  --query "[].fullyQualifiedDomainName"

echo "🎉 LOGRO: Base de datos PostgreSQL lista y accesible"

echo "✅ CHECKPOINT: ¿PostgreSQL muestra estado 'Ready'?"
```

### ✅ **Paso 5.4: Verificar Monitoring**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Confirmar que monitoring está capturando datos
# ¿POR QUÉ? Para asegurar observabilidad del sistema

echo "🎯 OBJETIVO: Verificar que Log Analytics está funcionando"

# Verificar Log Analytics workspace
az monitor log-analytics workspace show \
  --workspace-name "law-paymentsystem-dev" \
  --resource-group "rg-PaymentSystem-dev" \
  --query "provisioningState"

# Query básico (puede tomar unos minutos en aparecer datos)
az monitor log-analytics query \
  --workspace "law-paymentsystem-dev" \
  --analytics-query "Usage | take 5" \
  --output table || echo "⚠️ Datos aún no disponibles, normal en deployments nuevos"

echo "✅ CHECKPOINT: Log Analytics workspace existe y acepta queries"
```

**🎯 OBJETIVO LOGRADO:** Sistema validado y funcionando ✅

---

## 🔧 FASE 6: Troubleshooting y Debugging

### 🎓 **OBJETIVO DE APRENDIZAJE**
> Desarrollar habilidades para diagnosticar y resolver problemas BICEP

### ✅ **Paso 6.1: Comandos de Diagnóstico BICEP**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Aprender a diagnosticar problemas BICEP
# ¿POR QUÉ? Para poder resolver issues cuando aparezcan

echo "🎯 OBJETIVO: Desarrollar habilidades de troubleshooting BICEP"

# Ver deployment history
echo "=== DEPLOYMENT HISTORY ==="
az deployment group list \
  --resource-group "rg-PaymentSystem-dev" \
  --output table

# Ver detalles de deployment específico
echo -e "\n=== DEPLOYMENT DETAILS ==="
az deployment group show \
  --resource-group "rg-PaymentSystem-dev" \
  --name "payment-system-deployment" \
  --query "properties.{state:provisioningState,timestamp:timestamp,duration:duration}"

echo "🎓 APRENDIZAJE: Estos comandos te ayudan a entender qué pasó en el deployment"
```

### ✅ **Paso 6.2: Validación de Sintaxis BICEP**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Verificar que el código BICEP está bien escrito
# ¿POR QUÉ? Para detectar errores antes de deployment

echo "🎯 OBJETIVO: Validar sintaxis y linting BICEP"

# Compilar BICEP para detectar errores
az bicep build --file main.bicep

# ¿Qué esperar?
# Sin errores: Se crea main.json
# Con errores: Mensajes específicos de qué corregir

echo "✅ CHECKPOINT: ¿La compilación fue exitosa sin errores?"

# Validar template compilado
az deployment group validate \
  --resource-group "rg-PaymentSystem-dev" \
  --template-file main.bicep \
  --parameters @parameters/parameters-dev.json

echo "🎓 APRENDIZAJE: 'bicep build' detecta errores de sintaxis, 'validate' detecta errores de Azure"
```

### ✅ **Paso 6.3: Simulacro de Error Común**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Simular un error típico para aprender a resolverlo
# ¿POR QUÉ? Para practicar troubleshooting sin presión

echo "🎯 OBJETIVO: Practicar resolución de un error común"

# Simular error de resource no encontrado
echo "Simulando error: buscar un deployment que no existe"
az deployment group show \
  --resource-group "rg-PaymentSystem-dev" \
  --name "deployment-inexistente" || echo "❌ Error esperado: deployment no existe"

echo "🎓 APRENDIZAJE: Este tipo de error indica que:"
echo "- El nombre del deployment está mal escrito"
echo "- El deployment no se ha ejecutado aún"
echo "- Estás en el resource group incorrecto"

echo "✅ SOLUCIÓN: Verificar con 'az deployment group list' qué deployments existen realmente"
```

### ✅ **Paso 6.4: Debugging con Azure Portal**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Usar Azure Portal para diagnosticar problemas
# ¿POR QUÉ? El portal tiene visualizaciones útiles para debugging

echo "🎯 OBJETIVO: Usar Azure Portal para debugging visual"

echo "🎓 APRENDIZAJE: Para debugging efectivo en Azure Portal:"
echo "1. Ve a Resource Groups → rg-PaymentSystem-dev"
echo "2. Click en 'Deployments' para ver historial visual"
echo "3. Click en un deployment para ver detalles"
echo "4. Ve a 'Activity Log' para ver operaciones recientes"
echo "5. Usa 'Resource Health' para verificar estado de recursos"

echo "✅ CHECKPOINT: ¿Puedes navegar a estas secciones en Azure Portal?"
```

**🎯 OBJETIVO LOGRADO:** Habilidades de troubleshooting BICEP desarrolladas ✅

---

## 🧹 FASE 7: Cleanup y Mejores Prácticas

### 🎓 **OBJETIVO DE APRENDIZAJE**
> Gestión responsable de recursos y mejores prácticas BICEP

### ✅ **Paso 7.1: Cleanup Responsable**
```bash
# ¿QUÉ ESTAMOS HACIENDO? Eliminar recursos para evitar costos
# ¿POR QUÉ? Los recursos Azure generan costos incluso sin usar

echo "🎯 OBJETIVO: Limpiar recursos de testing para evitar costos"

# Advertencia importante
echo "⚠️  IMPORTANTE: Esto eliminará TODOS los recursos creados"
echo "¿Estás seguro de continuar? (y/n)"
read -r response

if [[ "$response" == "y" || "$response" == "Y" ]]; then
    # Delete resource group (elimina todo dentro)
    az group delete \
      --name "rg-PaymentSystem-dev" \
      --yes \
      --no-wait
    
    echo "🎉 LOGRO: Recursos eliminados correctamente - no más costos"
    echo "El Resource Group se está eliminando en background"
else
    echo "ℹ️  Cleanup cancelado - recursos mantienen activos"
fi
```

### ✅ **Paso 7.2: Mejores Prácticas BICEP Aprendidas**
```bash
echo "🎓 RESUMEN DE MEJORES PRÁCTICAS BICEP QUE APRENDISTE:"

echo "✅ 1. Usar sintaxis BICEP en lugar de ARM JSON directo"
echo "✅ 2. Organizar en módulos reutilizables"
echo "✅ 3. Usar @description en parámetros para documentación"
echo "✅ 4. Validar templates antes de deploy con 'az deployment validate'"
echo "✅ 5. Usar parameters files para diferentes ambientes"
echo "✅ 6. Incluir outputs importantes para información post-deploy"
echo "✅ 7. Aplicar governance tags consistentemente"
echo "✅ 8. Compilar con 'az bicep build' para detectar errores"

echo "🎯 OBJETIVO LOGRADO: Entiendes las mejores prácticas BICEP ✅"
```

### ✅ **Paso 7.3: Comparación Final: BICEP vs ARM vs Terraform**
```bash
echo "🎓 COMPARACIÓN FINAL: BICEP en el Ecosistema IaC"

echo "🔷 BICEP VENTAJAS:"
echo "✅ Sintaxis 70% más limpia que ARM"
echo "✅ IntelliSense completo en VS Code"  
echo "✅ Compila a ARM nativo - máxima compatibilidad"
echo "✅ Zero learning curve si ya conoces Azure"
echo "✅ Mejor experiencia de desarrollo para Azure"

echo -e "\n🌍 TERRAFORM VENTAJAS:"
echo "✅ Multi-cloud (AWS, GCP, Azure)"
echo "✅ State management explícito"
echo "✅ Amplio ecosistema de providers"

echo -e "\n📋 ARM TEMPLATES:"
echo "✅ Control granular máximo"
echo "⚠️ Sintaxis verbosa y compleja"

echo -e "\n🎯 RECOMENDACIÓN:"
echo "🔷 BICEP para proyectos Azure-only nuevos"
echo "🌍 Terraform para estrategia multi-cloud"
echo "📋 ARM solo para legacy o casos muy específicos"
```

### ✅ **Paso 7.4: Próximos Pasos**
```bash
echo "🚀 ¿QUÉ PUEDES HACER AHORA?"

echo "📚 NIVEL BÁSICO COMPLETADO - Ahora puedes:"
echo "✅ Desplegar el sistema de pagos completo con BICEP"
echo "✅ Modificar parámetros por ambiente"
echo "✅ Hacer troubleshooting básico"
echo "✅ Entender por qué BICEP es mejor que ARM"

echo -e "\n🎯 PRÓXIMOS DESAFÍOS:"
echo "🔄 1. Modificar templates y hacer re-deploy"
echo "🏭 2. Deploy a ambiente de producción"
echo "🔧 3. Crear tus propios módulos BICEP"
echo "📊 4. Configurar CI/CD con Azure DevOps"
echo "🔐 5. Implementar BICEP Registry para módulos compartidos"

echo -e "\n📖 RECURSOS PARA CONTINUAR APRENDIENDO:"
echo "- BICEP Documentation: https://docs.microsoft.com/azure/azure-resource-manager/bicep/"
echo "- BICEP Examples: https://github.com/Azure/bicep"
echo "- Azure Architecture Center: https://docs.microsoft.com/azure/architecture/"
```

**🎯 OBJETIVO FINAL LOGRADO:** Ingeniero con confianza en BICEP ✅

---

## 📊 RESUMEN DE LOGROS

### ✅ **CONOCIMIENTOS ADQUIRIDOS**
- 🏗️ **Infrastructure as Code** con BICEP DSL
- 🏛️ **Azure Policy compliance** empresarial
- 🐳 **Container Apps** y arquitectura de microservicios
- 📊 **Monitoring** y observabilidad en Azure
- 🔐 **Security** y networking en la nube
- 🎨 **BICEP sintaxis** moderna y limpia

### ✅ **HABILIDADES DESARROLLADAS**
- ✅ Escribir templates BICEP limpios y legibles
- ✅ Compilar y validar templates antes de deploy
- ✅ Desplegar sistemas complejos con un solo comando
- ✅ Diagnosticar y resolver problemas BICEP
- ✅ Aplicar governance empresarial con tags
- ✅ Entender las ventajas de BICEP vs ARM/Terraform

### ✅ **PROYECTO COMPLETADO**
- 🏗️ **Sistema de Pagos** completo en Azure con BICEP
- 🏷️ **Governance Tags** aplicados consistentemente
- 📊 **Monitoring** configurado y funcionando
- 🔐 **Security** implementada con best practices
- 💰 **Cost Management** aplicado
- 🎨 **Código limpio** 70% menos verboso que ARM

---

## 🎉 ¡FELICIDADES!

**Has completado exitosamente el despliegue de un sistema de pagos enterprise-grade usando BICEP!**

### 🎯 **LO QUE LOGRASTE:**
- ✅ **Sintaxis limpia**: Escribes BICEP en lugar de JSON verboso
- ✅ **Deploy eficiente**: Sistema completo en una sola ejecución
- ✅ **Governance compliance**: Cumples políticas empresariales
- ✅ **Troubleshooting efectivo**: Puedes diagnosticar y resolver problemas
- ✅ **Confianza técnica**: Entiendes cuándo usar BICEP vs otras opciones

### 🚀 **AHORA PUEDES:**
- 🎨 Escribir templates BICEP limpios y mantenibles
- 🏭 Desplegar infraestructura Azure de nivel empresarial
- 🔧 Modificar y extender sistemas existentes
- 📊 Implementar monitoring y observabilidad
- 🏛️ Cumplir con governance y compliance organizacional

**¡Sigue practicando y explorando el poder de BICEP! 🚀**
