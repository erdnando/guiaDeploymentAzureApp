#!/bin/bash

# =============================================================================
# Script: setup-client-governance.sh
# Descripción: Configuración automatizada del framework de governance para cliente
# Autor: Sistema de Deployment Azure
# Fecha: $(date)
# =============================================================================

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables de configuración
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/governance-setup-$(date +%Y%m%d-%H%M%S).log"
SUBSCRIPTION_ID=""
TENANT_ID=""
RESOURCE_GROUP=""
LOCATION="eastus"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}❌ ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$LOG_FILE"
}

# Función para verificar prerrequisitos
check_prerequisites() {
    info "Verificando prerrequisitos..."
    
    # Verificar Azure CLI
    if ! command -v az &> /dev/null; then
        error "Azure CLI no está instalado. Instale Azure CLI antes de continuar."
    fi
    
    # Verificar login
    if ! az account show &> /dev/null; then
        error "No hay sesión activa en Azure CLI. Ejecute 'az login' primero."
    fi
    
    # Verificar permisos
    local current_user_role=$(az role assignment list --assignee $(az account show --query user.name -o tsv) --query "[?roleDefinitionName=='Owner' || roleDefinitionName=='Contributor' || roleDefinitionName=='User Access Administrator'].roleDefinitionName" -o tsv)
    
    if [[ -z "$current_user_role" ]]; then
        warning "El usuario actual podría no tener permisos suficientes para crear roles y asignaciones."
    fi
    
    success "Prerrequisitos verificados"
}

# Función para obtener configuración
get_configuration() {
    info "Obteniendo configuración del entorno..."
    
    # Obtener subscription actual
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    TENANT_ID=$(az account show --query tenantId -o tsv)
    
    info "Subscription ID: $SUBSCRIPTION_ID"
    info "Tenant ID: $TENANT_ID"
    
    # Solicitar Resource Group si no está definido
    if [[ -z "$RESOURCE_GROUP" ]]; then
        read -p "Ingrese el nombre del Resource Group principal: " RESOURCE_GROUP
    fi
    
    # Verificar si el RG existe
    if ! az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        read -p "El Resource Group '$RESOURCE_GROUP' no existe. ¿Crearlo? (y/n): " create_rg
        if [[ $create_rg =~ ^[Yy]$ ]]; then
            az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
            success "Resource Group '$RESOURCE_GROUP' creado"
        else
            error "Resource Group requerido para continuar"
        fi
    fi
}

# Función para crear grupos de seguridad en Entra ID
create_security_groups() {
    info "Creando grupos de seguridad en Entra ID..."
    
    local groups=(
        "Azure-Administrators:Administradores de Azure con acceso completo"
        "Azure-Developers:Desarrolladores con acceso a recursos de desarrollo"
        "Azure-FinOps:Equipo financiero para gestión de costos"
        "Azure-Security:Equipo de seguridad para auditoría y compliance"
        "Azure-ReadOnly:Usuarios con acceso de solo lectura"
    )
    
    for group_info in "${groups[@]}"; do
        IFS=':' read -r group_name group_description <<< "$group_info"
        
        # Verificar si el grupo ya existe
        if az ad group show --group "$group_name" &> /dev/null; then
            warning "El grupo '$group_name' ya existe"
        else
            az ad group create \
                --display-name "$group_name" \
                --mail-nickname "$group_name" \
                --description "$group_description"
            success "Grupo '$group_name' creado"
        fi
    done
}

# Función para crear roles RBAC personalizados
create_custom_roles() {
    info "Creando roles RBAC personalizados..."
    
    # Crear directorio temporal para definiciones de roles
    local temp_dir=$(mktemp -d)
    
    # Rol para Desarrolladores
    cat > "$temp_dir/developer-role.json" << EOFROLE
{
    "Name": "Azure Developer Custom",
    "Id": null,
    "IsCustom": true,
    "Description": "Rol personalizado para desarrolladores con acceso limitado a recursos de desarrollo",
    "Actions": [
        "Microsoft.Resources/subscriptions/resourceGroups/read",
        "Microsoft.Resources/deployments/*",
        "Microsoft.Web/sites/*",
        "Microsoft.Storage/storageAccounts/read",
        "Microsoft.Storage/storageAccounts/listKeys/action",
        "Microsoft.ContainerRegistry/registries/read",
        "Microsoft.ContainerRegistry/registries/push/write",
        "Microsoft.ContainerRegistry/registries/pull/read",
        "Microsoft.Insights/alertRules/*",
        "Microsoft.Insights/components/*",
        "Microsoft.KeyVault/vaults/read",
        "Microsoft.KeyVault/vaults/secrets/read"
    ],
    "NotActions": [
        "Microsoft.Authorization/*/Delete",
        "Microsoft.Authorization/*/Write",
        "Microsoft.Authorization/elevateAccess/Action"
    ],
    "DataActions": [],
    "NotDataActions": [],
    "AssignableScopes": [
        "/subscriptions/$SUBSCRIPTION_ID"
    ]
}
EOFROLE
    
    # Rol para FinOps
    cat > "$temp_dir/finops-role.json" << EOFROLE
{
    "Name": "Azure FinOps Custom",
    "Id": null,
    "IsCustom": true,
    "Description": "Rol personalizado para gestión financiera y optimización de costos",
    "Actions": [
        "Microsoft.Consumption/*",
        "Microsoft.CostManagement/*",
        "Microsoft.Billing/*/read",
        "Microsoft.Resources/subscriptions/read",
        "Microsoft.Resources/subscriptions/resourceGroups/read",
        "Microsoft.Insights/metrics/read",
        "Microsoft.Advisor/recommendations/read",
        "Microsoft.Support/*"
    ],
    "NotActions": [],
    "DataActions": [],
    "NotDataActions": [],
    "AssignableScopes": [
        "/subscriptions/$SUBSCRIPTION_ID"
    ]
}
EOFROLE
    
    # Rol para Security
    cat > "$temp_dir/security-role.json" << EOFROLE
{
    "Name": "Azure Security Custom",
    "Id": null,
    "IsCustom": true,
    "Description": "Rol personalizado para equipo de seguridad con acceso de auditoría",
    "Actions": [
        "Microsoft.Security/*",
        "Microsoft.Authorization/*/read",
        "Microsoft.Resources/subscriptions/read",
        "Microsoft.Resources/subscriptions/resourceGroups/read",
        "Microsoft.Insights/alertRules/*",
        "Microsoft.OperationalInsights/workspaces/read",
        "Microsoft.OperationalInsights/workspaces/query/action",
        "Microsoft.KeyVault/vaults/read",
        "Microsoft.Network/networkSecurityGroups/read",
        "Microsoft.PolicyInsights/*"
    ],
    "NotActions": [
        "Microsoft.Authorization/*/Delete",
        "Microsoft.Authorization/*/Write"
    ],
    "DataActions": [],
    "NotDataActions": [],
    "AssignableScopes": [
        "/subscriptions/$SUBSCRIPTION_ID"
    ]
}
EOFROLE
    
    # Crear los roles
    local roles=("developer-role.json" "finops-role.json" "security-role.json")
    
    for role_file in "${roles[@]}"; do
        local role_name=$(jq -r '.Name' "$temp_dir/$role_file")
        
        # Verificar si el rol ya existe
        if az role definition list --name "$role_name" --query "[0]" &> /dev/null; then
            warning "El rol '$role_name' ya existe"
        else
            az role definition create --role-definition "$temp_dir/$role_file"
            success "Rol '$role_name' creado"
        fi
    done
    
    # Limpiar archivos temporales
    rm -rf "$temp_dir"
}

# Función para crear Azure Policies
create_azure_policies() {
    info "Creando Azure Policies..."
    
    # Policy para requerir tags obligatorios
    local policy_definition='{
        "mode": "All",
        "policyRule": {
            "if": {
                "allOf": [
                    {
                        "field": "type",
                        "equals": "Microsoft.Resources/subscriptions/resourceGroups"
                    },
                    {
                        "anyOf": [
                            {
                                "field": "tags['"'"'Environment'"'"']",
                                "exists": "false"
                            },
                            {
                                "field": "tags['"'"'Project'"'"']",
                                "exists": "false"
                            },
                            {
                                "field": "tags['"'"'CostCenter'"'"']",
                                "exists": "false"
                            }
                        ]
                    }
                ]
            },
            "then": {
                "effect": "deny"
            }
        },
        "parameters": {}
    }'
    
    # Crear policy definition
    if ! az policy definition show --name "require-mandatory-tags" &> /dev/null; then
        echo "$policy_definition" | az policy definition create \
            --name "require-mandatory-tags" \
            --display-name "Require Mandatory Tags" \
            --description "Require Environment, Project, and CostCenter tags on resource groups" \
            --rules @-
        success "Policy 'require-mandatory-tags' creada"
    else
        warning "Policy 'require-mandatory-tags' ya existe"
    fi
    
    # Asignar policy al subscription
    if ! az policy assignment show --name "mandatory-tags-assignment" &> /dev/null; then
        az policy assignment create \
            --name "mandatory-tags-assignment" \
            --display-name "Mandatory Tags Assignment" \
            --policy "require-mandatory-tags" \
            --scope "/subscriptions/$SUBSCRIPTION_ID"
        success "Policy assignment 'mandatory-tags-assignment' creada"
    else
        warning "Policy assignment 'mandatory-tags-assignment' ya existe"
    fi
}

# Función para configurar monitoreo y alertas
setup_monitoring() {
    info "Configurando monitoreo y alertas..."
    
    # Crear Log Analytics Workspace si no existe
    local workspace_name="governance-monitoring-workspace"
    
    if ! az monitor log-analytics workspace show --resource-group "$RESOURCE_GROUP" --workspace-name "$workspace_name" &> /dev/null; then
        az monitor log-analytics workspace create \
            --resource-group "$RESOURCE_GROUP" \
            --workspace-name "$workspace_name" \
            --location "$LOCATION"
        success "Log Analytics Workspace '$workspace_name' creado"
    else
        warning "Log Analytics Workspace '$workspace_name' ya existe"
    fi
    
    # Configurar alertas de costo
    local budget_name="monthly-budget-alert"
    
    if ! az consumption budget show --budget-name "$budget_name" &> /dev/null; then
        az consumption budget create \
            --budget-name "$budget_name" \
            --amount 1000 \
            --category "Cost" \
            --time-grain "Monthly" \
            --start-date "$(date -d 'first day of this month' '+%Y-%m-01')" \
            --end-date "$(date -d 'first day of next year' '+%Y-01-01')"
        success "Budget alert '$budget_name' creado"
    else
        warning "Budget alert '$budget_name' ya existe"
    fi
}

# Función para asignar roles a grupos
assign_roles_to_groups() {
    info "Asignando roles a grupos de seguridad..."
    
    # Obtener IDs de los grupos
    local admin_group_id=$(az ad group show --group "Azure-Administrators" --query id -o tsv)
    local dev_group_id=$(az ad group show --group "Azure-Developers" --query id -o tsv)
    local finops_group_id=$(az ad group show --group "Azure-FinOps" --query id -o tsv)
    local security_group_id=$(az ad group show --group "Azure-Security" --query id -o tsv)
    local readonly_group_id=$(az ad group show --group "Azure-ReadOnly" --query id -o tsv)
    
    # Asignaciones de roles
    local assignments=(
        "$admin_group_id:Owner:/subscriptions/$SUBSCRIPTION_ID"
        "$dev_group_id:Azure Developer Custom:/subscriptions/$SUBSCRIPTION_ID"
        "$finops_group_id:Azure FinOps Custom:/subscriptions/$SUBSCRIPTION_ID"
        "$security_group_id:Azure Security Custom:/subscriptions/$SUBSCRIPTION_ID"
        "$readonly_group_id:Reader:/subscriptions/$SUBSCRIPTION_ID"
    )
    
    for assignment in "${assignments[@]}"; do
        IFS=':' read -r group_id role_name scope <<< "$assignment"
        
        # Verificar si la asignación ya existe
        if ! az role assignment list --assignee "$group_id" --role "$role_name" --scope "$scope" --query "[0]" &> /dev/null; then
            az role assignment create \
                --assignee "$group_id" \
                --role "$role_name" \
                --scope "$scope"
            success "Rol '$role_name' asignado al grupo"
        else
            warning "Asignación de rol '$role_name' ya existe para el grupo"
        fi
    done
}

# Función para generar reporte de configuración
generate_configuration_report() {
    info "Generando reporte de configuración..."
    
    local report_file="${SCRIPT_DIR}/governance-configuration-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << EOFREPORT
# Reporte de Configuración de Governance

**Fecha:** $(date)
**Subscription:** $SUBSCRIPTION_ID
**Tenant:** $TENANT_ID
**Resource Group:** $RESOURCE_GROUP

## Grupos de Seguridad Creados

EOFREPORT
    
    # Listar grupos creados
    local groups=("Azure-Administrators" "Azure-Developers" "Azure-FinOps" "Azure-Security" "Azure-ReadOnly")
    
    for group in "${groups[@]}"; do
        local group_id=$(az ad group show --group "$group" --query id -o tsv 2>/dev/null || echo "No encontrado")
        echo "- **$group:** $group_id" >> "$report_file"
    done
    
    cat >> "$report_file" << EOFREPORT

## Roles Personalizados Creados

EOFREPORT
    
    # Listar roles personalizados
    az role definition list --custom-role-only --query "[].{Name:roleName, Description:description}" -o table >> "$report_file"
    
    cat >> "$report_file" << EOFREPORT

## Policies Aplicadas

EOFREPORT
    
    # Listar policy assignments
    az policy assignment list --query "[].{Name:displayName, Policy:policyDefinitionId}" -o table >> "$report_file"
    
    success "Reporte generado: $report_file"
}

# Función principal
main() {
    info "=== Iniciando configuración de governance ==="
    
    check_prerequisites
    get_configuration
    create_security_groups
    create_custom_roles
    create_azure_policies
    setup_monitoring
    assign_roles_to_groups
    generate_configuration_report
    
    success "=== Configuración de governance completada ==="
    info "Log file: $LOG_FILE"
    info "Consulte la documentación en docs/GOVERNANCE-RBAC-SECURITY.md para más detalles"
}

# Verificar si el script se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
