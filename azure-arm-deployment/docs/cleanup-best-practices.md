# 🧹 Guía de Cleanup y Gestión de Recursos

## 🎯 Importancia del Cleanup

Mantener el ambiente Azure limpio es crucial para:
- **💰 Control de costos**: Evitar cargos por recursos no utilizados
- **🔒 Seguridad**: Reducir superficie de ataque
- **📊 Governance**: Mantener visibilidad clara de recursos activos
- **🎯 Organización**: Facilitar la gestión y monitoreo

## 🗂️ Categorías de Recursos

### 1. **Recursos de Producción** 🔴
- **NO eliminar nunca sin autorización**
- Naming: `rg-[app]-prod-[region]`
- Tags obligatorios: `Environment: prod`

### 2. **Recursos de Testing** 🟡
- **Eliminar después de pruebas**
- Naming: `rg-[app]-test-[region]`
- Lifecycle: Temporal

### 3. **Recursos de Validación** 🟢
- **Eliminar inmediatamente después de validar**
- Naming: `rg-[app]-validation-[region]`, `rg-whatif-test`
- Solo para `az deployment validate` y `what-if`

### 4. **Recursos de Desarrollo** 🔵
- **Revisar semanalmente**
- Naming: `rg-[app]-dev-[region]`
- Auto-shutdown recomendado

## 🛠️ Scripts de Cleanup Disponibles

### 1. Cleanup Automático
```bash
# Ejecutar cleanup completo
./scripts/cleanup-test-resources.sh
```

### 2. Cleanup Manual por Tipo
```bash
# Solo resource groups de validación
az group delete --name rg-paymentapp-validation-canada --yes

# Solo deployments huérfanos
az deployment group delete --resource-group [rg-name] --name [deployment-name]
```

### 3. Cleanup con Filtros
```bash
# Todos los RGs que contienen "test"
az group list --query "[?contains(name, 'test')].name" --output tsv | \
  xargs -I {} az group delete --name {} --yes --no-wait

# Todos los RGs que contienen "validation"
az group list --query "[?contains(name, 'validation')].name" --output tsv | \
  xargs -I {} az group delete --name {} --yes --no-wait
```

## 📋 Checklist de Cleanup

### ✅ Después de Validaciones
- [ ] Eliminar resource groups de prueba
- [ ] Verificar deployments huérfanos
- [ ] Confirmar que no hay recursos facturables activos

### ✅ Semanal (Ambiente Dev)
- [ ] Revisar recursos dev no utilizados
- [ ] Eliminar storage accounts temporales
- [ ] Limpiar logs antiguos

### ✅ Mensual (Governance)
- [ ] Audit completo de recursos
- [ ] Verificar compliance de tags
- [ ] Revisar costos por centro de costo

## 🔍 Comandos de Auditoria

### Verificar Recursos Sin Tags
```bash
# Recursos sin tag 'Project'
az resource list --query "[?tags.Project == null].{Name:name, Type:type, ResourceGroup:resourceGroup}" --output table

# Recursos sin tag 'Environment'  
az resource list --query "[?tags.Environment == null].{Name:name, Type:type, ResourceGroup:resourceGroup}" --output table
```

### Verificar Costos por Tag
```bash
# Costos por centro de costos
az consumption usage list --query "[].{Resource:instanceName, Cost:pretaxCost, CostCenter:tags.CostCenter}" --output table

# Costos por proyecto
az consumption usage list --query "[].{Resource:instanceName, Cost:pretaxCost, Project:tags.Project}" --output table
```

### Encontrar Recursos Huérfanos
```bash
# Resource groups vacíos
for rg in $(az group list --query "[].name" --output tsv); do
  count=$(az resource list --resource-group $rg --query "length(@)")
  if [ "$count" -eq 0 ]; then
    echo "RG vacío: $rg"
  fi
done
```

## ⚠️ Recursos que Requieren Atención Especial

### 1. **Bases de Datos**
```bash
# Verificar backups antes de eliminar
az postgres flexible-server list --query "[].{Name:name, State:state}" --output table

# Verificar conexiones activas
az postgres flexible-server show --resource-group [rg] --name [server] --query "connectionState"
```

### 2. **Storage Accounts**
```bash
# Verificar contenido antes de eliminar
az storage account list --query "[].{Name:name, Kind:kind, AccessTier:accessTier}" --output table

# Verificar blobs importantes
az storage blob list --account-name [account] --container-name [container] --output table
```

### 3. **Application Gateways**
```bash
# Verificar tráfico activo
az network application-gateway list --query "[].{Name:name, State:operationalState}" --output table
```

## 🚨 Alertas de Cleanup Recomendadas

### 1. Alerta de Costos Inesperados
```bash
# Configurar alerta cuando costos > umbral
az monitor metrics alert create \
  --name "Unexpected-Costs-Alert" \
  --resource-group monitoring-rg \
  --condition "total cost > 50 USD" \
  --description "Recursos de prueba generando costos"
```

### 2. Alerta de Recursos Sin Tags
```bash
# Policy para requerir tags
az policy assignment create \
  --name "require-project-tag" \
  --policy "Require a tag on resources" \
  --params '{"tagName":{"value":"Project"}}'
```

## 🎯 Mejores Prácticas

### ✅ Naming Conventions
```
Producción:    rg-paymentapp-prod-canadacentral
Testing:       rg-paymentapp-test-canadacentral  
Development:   rg-paymentapp-dev-canadacentral
Validation:    rg-paymentapp-validation-canadacentral
Temporal:      rg-paymentapp-temp-[timestamp]
```

### ✅ Lifecycle Management
- **Validation**: Eliminar inmediatamente
- **Testing**: Eliminar después de 48h
- **Development**: Revisar semanalmente
- **Production**: Proceso formal de cambios

### ✅ Automation
```bash
# Cron job para cleanup automático (cuidado con producción)
0 2 * * 0 /path/to/cleanup-test-resources.sh >> /var/log/azure-cleanup.log 2>&1
```

## 📞 Contactos de Emergencia

- **Recursos eliminados por error**: Azure Support + Backup Team
- **Costos inesperados**: FinOps Team
- **Compliance violations**: Cloud Governance Team

---

**⚠️ IMPORTANTE**: Siempre verificar el contenido antes de eliminar recursos. Cuando tengas dudas, consulta con el equipo responsable.

**🔄 Última actualización**: Julio 2025
