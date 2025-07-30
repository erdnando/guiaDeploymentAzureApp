# =============================================================================
# Variables de Entorno para Azure ARM Deployment (Windows PowerShell)
# =============================================================================
# Este archivo contiene todas las variables necesarias para el despliegue
# Asegúrate de personalizar estos valores antes de ejecutar los scripts

# Variables principales del proyecto
$env:PROJECT_NAME = "paymentapp"
$env:ENVIRONMENT = "dev"  # Opciones: dev, test, prod
$env:RESOURCE_GROUP = "rg-$($env:PROJECT_NAME)-$($env:ENVIRONMENT)"
$env:LOCATION = "eastus"   # Cambiar según tu región preferida

# Variables de PostgreSQL
$env:POSTGRES_ADMIN_USER = "pgadmin"
$env:POSTGRES_DB_NAME = "paymentdb"
$env:POSTGRES_VERSION = "14"

# Variables de Container Registry (GitHub Container Registry)
$env:REGISTRY_SERVER = "ghcr.io"
$env:REGISTRY_USERNAME = "tu-usuario-github"          # CAMBIAR POR TU USUARIO
$env:REGISTRY_PASSWORD = "tu-github-token"            # CAMBIAR POR TU TOKEN
$env:BACKEND_IMAGE = "$($env:REGISTRY_SERVER)/$($env:REGISTRY_USERNAME)/payment-api:latest"
$env:FRONTEND_IMAGE = "$($env:REGISTRY_SERVER)/$($env:REGISTRY_USERNAME)/payment-frontend:latest"

# Variables de monitoreo
$env:ALERT_EMAIL = "admin@tuempresa.com"              # CAMBIAR POR TU EMAIL

# Variables calculadas automáticamente
$env:UNIQUE_SUFFIX = [int](Get-Date -UFormat %s)
$env:POSTGRES_SERVER_NAME = "pg-$($env:PROJECT_NAME)-$($env:ENVIRONMENT)-$($env:UNIQUE_SUFFIX)"
$env:VNET_NAME = "vnet-$($env:PROJECT_NAME)-$($env:ENVIRONMENT)"
$env:CONTAINERAPP_ENV_NAME = "env-$($env:PROJECT_NAME)-$($env:ENVIRONMENT)"
$env:LOG_ANALYTICS_WORKSPACE = "log-$($env:PROJECT_NAME)-$($env:ENVIRONMENT)"

# Función para mostrar todas las variables configuradas
function Show-Variables {
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "Variables de entorno configuradas:" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "PROJECT_NAME: $($env:PROJECT_NAME)"
    Write-Host "ENVIRONMENT: $($env:ENVIRONMENT)"
    Write-Host "RESOURCE_GROUP: $($env:RESOURCE_GROUP)"
    Write-Host "LOCATION: $($env:LOCATION)"
    Write-Host "POSTGRES_SERVER_NAME: $($env:POSTGRES_SERVER_NAME)"
    Write-Host "VNET_NAME: $($env:VNET_NAME)"
    Write-Host "BACKEND_IMAGE: $($env:BACKEND_IMAGE)"
    Write-Host "FRONTEND_IMAGE: $($env:FRONTEND_IMAGE)"
    Write-Host "ALERT_EMAIL: $($env:ALERT_EMAIL)"
    Write-Host "==========================================" -ForegroundColor Cyan
}

# Función para validar variables requeridas
function Test-Variables {
    $errors = 0
    
    if ($env:REGISTRY_USERNAME -eq "tu-usuario-github") {
        Write-Host "❌ ERROR: Debes cambiar REGISTRY_USERNAME por tu usuario real de GitHub" -ForegroundColor Red
        $errors++
    }
    
    if ($env:REGISTRY_PASSWORD -eq "tu-github-token") {
        Write-Host "❌ ERROR: Debes cambiar REGISTRY_PASSWORD por tu token real de GitHub" -ForegroundColor Red
        $errors++
    }
    
    if ($env:ALERT_EMAIL -eq "admin@tuempresa.com") {
        Write-Host "⚠️  ADVERTENCIA: Considera cambiar ALERT_EMAIL por tu email real" -ForegroundColor Yellow
    }
    
    if ($errors -gt 0) {
        Write-Host ""
        Write-Host "❌ Se encontraron $errors errores en la configuración." -ForegroundColor Red
        Write-Host "Por favor, edita el archivo variables.ps1 antes de continuar." -ForegroundColor Red
        return $false
    }
    
    Write-Host "✅ Todas las variables están configuradas correctamente" -ForegroundColor Green
    return $true
}

# Función para verificar autenticación en Azure
function Test-AzureAuth {
    Write-Host "🔍 Verificando autenticación en Azure..." -ForegroundColor Blue
    try {
        $account = az account show | ConvertFrom-Json -ErrorAction Stop
        $subscriptionName = $account.name
        $subscriptionId = $account.id
        Write-Host "✅ Autenticado en Azure" -ForegroundColor Green
        Write-Host "   Suscripción: $subscriptionName"
        Write-Host "   ID: $subscriptionId"
        return $true
    }
    catch {
        Write-Host "❌ No estás autenticado en Azure. Ejecuta 'az login' primero." -ForegroundColor Red
        return $false
    }
}

# Ejecutar validaciones automáticamente
Write-Host "🚀 Configurando variables de entorno para Azure ARM Deployment" -ForegroundColor Green
Write-Host ""
Show-Variables
Write-Host ""
$variablesValid = Test-Variables
Write-Host ""
$azureAuthValid = Test-AzureAuth
Write-Host ""

if ($variablesValid -and $azureAuthValid) {
    Write-Host "💡 Variables cargadas exitosamente. Puedes proceder con el despliegue." -ForegroundColor Green
}
else {
    Write-Host "⚠️  Corrige los errores antes de continuar con el despliegue." -ForegroundColor Yellow
}
