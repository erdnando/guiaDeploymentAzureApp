# Framework de Governance, RBAC y Seguridad para Azure

## Introducción

Este documento describe el framework completo de governance, RBAC (Role-Based Access Control) y seguridad para la implementación Azure de la organización.

### Objetivos del Sistema de Governance

- **Segregación de responsabilidades** por equipos organizacionales
- **Principio de menor privilegio** en asignaciones de permisos
- **Compliance** con estándares de seguridad empresarial
- **Auditoría y monitoreo** automatizado
- **Gestión de costos** (FinOps) integrada

### Equipos Organizacionales

| Equipo | Responsabilidades | Nivel de Acceso |
|--------|------------------|-----------------|
| **Azure Administrators** | Gestión completa de infraestructura | Owner/Contributor |
| **Developers** | Desarrollo y deployment de aplicaciones | Limitado a recursos de desarrollo |
| **FinOps** | Gestión financiera y optimización de costos | Lectura de costos y billing |
| **Security** | Auditoría y compliance de seguridad | Lectura de logs y políticas |
| **ReadOnly** | Consulta general de recursos | Solo lectura |

## Configuración de Entra ID (Azure AD)

### Grupos de Seguridad

#### 1. Azure-Administrators
- **Descripción:** Administradores de Azure con acceso completo
- **Miembros:** Equipo de infraestructura y administradores de sistemas
- **Permisos:** Owner/Contributor a nivel de subscription

#### 2. Azure-Developers
- **Descripción:** Desarrolladores con acceso a recursos de desarrollo
- **Miembros:** Equipo de desarrollo de aplicaciones
- **Permisos:** Rol personalizado con acceso limitado

#### 3. Azure-FinOps
- **Descripción:** Equipo financiero para gestión de costos
- **Miembros:** Analistas financieros y gestores de presupuesto
- **Permisos:** Acceso completo a Cost Management y Billing

#### 4. Azure-Security
- **Descripción:** Equipo de seguridad para auditoría y compliance
- **Miembros:** Analistas de seguridad y compliance officers
- **Permisos:** Acceso de lectura a Security Center y logs

#### 5. Azure-ReadOnly
- **Descripción:** Usuarios con acceso de solo lectura
- **Miembros:** Stakeholders y personal con necesidad de consulta
- **Permisos:** Reader a nivel de subscription

## Roles RBAC Personalizados

### 1. Azure Developer Custom

**Descripción:** Rol personalizado para desarrolladores con acceso limitado a recursos de desarrollo.

**Permisos Incluidos:**
- Microsoft.Resources/subscriptions/resourceGroups/read
- Microsoft.Resources/deployments/*
- Microsoft.Web/sites/*
- Microsoft.Storage/storageAccounts/read
- Microsoft.ContainerRegistry/registries/read
- Microsoft.KeyVault/vaults/read
- Microsoft.KeyVault/vaults/secrets/read

**Permisos Denegados:**
- Microsoft.Authorization/*/Delete
- Microsoft.Authorization/*/Write
- Microsoft.Authorization/elevateAccess/Action

### 2. Azure FinOps Custom

**Descripción:** Rol personalizado para gestión financiera y optimización de costos.

**Permisos Incluidos:**
- Microsoft.Consumption/*
- Microsoft.CostManagement/*
- Microsoft.Billing/*/read
- Microsoft.Resources/subscriptions/read
- Microsoft.Advisor/recommendations/read

### 3. Azure Security Custom

**Descripción:** Rol personalizado para equipo de seguridad con acceso de auditoría.

**Permisos Incluidos:**
- Microsoft.Security/*
- Microsoft.Authorization/*/read
- Microsoft.PolicyInsights/*
- Microsoft.OperationalInsights/workspaces/read
- Microsoft.KeyVault/vaults/read

## Azure Policies

### Política de Tags Obligatorios

**Propósito:** Asegurar que todos los Resource Groups tengan tags obligatorios.

**Tags Requeridos:**
- Environment (dev, staging, prod)
- Project (nombre del proyecto)
- CostCenter (centro de costos)

### Política de Ubicaciones Permitidas

**Ubicaciones Permitidas:**
- East US
- West Europe
- Southeast Asia

## Key Vault - Políticas de Acceso

### Key Vault de Desarrollo
- **Grupos con Acceso:** Azure-Administrators, Azure-Developers, Azure-Security
- **Configuración:** Soft Delete habilitado, Purge Protection habilitado

### Key Vault de Producción
- **Grupos con Acceso:** Azure-Administrators, Azure-Security
- **Configuración:** Network ACLs restricitivos, solo redes corporativas

## Monitoreo y Auditoría

### Log Analytics Workspace
- **Retención:** 90 días (desarrollo), 365 días (producción)
- **Fuentes:** Azure Activity Logs, Security Center, Key Vault Audit Logs

### Alertas de Seguridad

#### Acceso No Autorizado a Key Vault
- **Query:** KeyVaultData | where ResultType != 'Success'
- **Frecuencia:** 5 minutos
- **Severidad:** Alta

#### Cambios en Asignaciones de Roles
- **Query:** AzureActivity | where OperationName contains 'roleAssignments'
- **Frecuencia:** 1 minuto
- **Severidad:** Media

## FinOps - Gestión de Costos

### Presupuestos por Ambiente

#### Desarrollo
- **Límite Mensual:** $1,000
- **Alertas:** 50%, 80%, 90%

#### Producción
- **Límite Mensual:** $10,000
- **Alertas:** 70%, 90%, 100%

### Optimización Automática

1. **Auto-shutdown de VMs de desarrollo:** 19:00 - 08:00
2. **Scaling automático de Container Apps**
3. **Archivado automático de logs:** >30 días a tier frío

## Implementación Automatizada

### Script de Configuración

El script `setup-client-governance.sh` automatiza la implementación completa:

```bash
./scripts/setup-client-governance.sh
```

**Funcionalidades:**
1. Creación de grupos de seguridad en Entra ID
2. Definición de roles RBAC personalizados
3. Implementación de Azure Policies
4. Configuración de monitoreo y alertas
5. Setup de presupuestos
6. Generación de reporte de configuración

## Procedimientos de Auditoría

### Auditoría Mensual

**Checklist de Compliance:**
- [ ] Revisar membresía de grupos de seguridad
- [ ] Validar asignaciones de roles RBAC
- [ ] Verificar compliance de tags en recursos
- [ ] Revisar alertas de seguridad
- [ ] Analizar utilización vs presupuesto

### Proceso de Incident Response

**Niveles de Severidad:**
- **Crítico (P0):** Compromiso de seguridad, acceso no autorizado a producción
- **Alto (P1):** Violación de políticas, acceso no autorizado a desarrollo
- **Medio (P2):** Recursos sin tags, uso de VM no autorizados
- **Bajo (P3):** Actividad fuera del horario laboral

## Contactos y Escalación

| Área | Equipo | Contacto |
|------|--------|----------|
| **Infrastructure** | Azure Administrators | admin@company.com |
| **Development** | Engineering Team | dev@company.com |
| **Security** | Security Team | security@company.com |
| **FinOps** | Finance Team | finance@company.com |

---

**Documentación generada:** $(date)  
**Versión:** 1.0  
**Próxima revisión:** $(date -d '+3 months')
