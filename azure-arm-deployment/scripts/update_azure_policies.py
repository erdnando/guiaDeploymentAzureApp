#!/usr/bin/env python3
"""
Script para actualizar templates ARM para compliance con Azure Policies
- Añadir parámetros costCenter y owner
- Actualizar commonTags
- Cambiar ubicación a canadacentral en parámetros
"""

import json
import os
import glob
import shutil

def update_arm_template(template_path, purpose):
    """Actualiza un template ARM con los parámetros y tags requeridos"""
    print(f"📝 Actualizando {template_path}...")
    
    # Crear respaldo
    shutil.copy2(template_path, template_path + '.bak')
    
    with open(template_path, 'r', encoding='utf-8') as f:
        template = json.load(f)
    
    # Añadir nuevos parámetros
    if 'costCenter' not in template['parameters']:
        template['parameters']['costCenter'] = {
            "type": "string",
            "defaultValue": "IT-Development",
            "metadata": {
                "description": "Centro de costos para facturación"
            }
        }
    
    if 'owner' not in template['parameters']:
        template['parameters']['owner'] = {
            "type": "string",
            "defaultValue": "DevOps-Team",
            "metadata": {
                "description": "Responsable del recurso"
            }
        }
    
    # Actualizar commonTags
    if 'commonTags' in template['variables']:
        template['variables']['commonTags'] = {
            "Environment": "[parameters('environment')]",
            "Project": "[parameters('projectName')]",
            "CostCenter": "[parameters('costCenter')]",
            "Owner": "[parameters('owner')]",
            "CreatedBy": "ARM Template",
            "ManagedBy": "Infrastructure-as-Code",
            "Purpose": purpose
        }
    
    # Guardar archivo actualizado
    with open(template_path, 'w', encoding='utf-8') as f:
        json.dump(template, f, indent=2, ensure_ascii=False)
    
    print(f"✅ {template_path} actualizado")

def update_parameters_file(param_path, cost_center="IT-PaymentApp", owner="DevOps-Team"):
    """Actualiza archivo de parámetros"""
    print(f"📝 Actualizando parámetros {param_path}...")
    
    if not os.path.exists(param_path):
        print(f"❌ {param_path} no encontrado")
        return
    
    # Crear respaldo
    shutil.copy2(param_path, param_path + '.bak')
    
    with open(param_path, 'r', encoding='utf-8') as f:
        params = json.load(f)
    
    # Actualizar ubicación
    if 'location' in params['parameters']:
        params['parameters']['location']['value'] = 'canadacentral'
    
    # Añadir nuevos parámetros
    if 'costCenter' not in params['parameters']:
        params['parameters']['costCenter'] = {"value": cost_center}
    
    if 'owner' not in params['parameters']:
        params['parameters']['owner'] = {"value": owner}
    
    # Guardar archivo actualizado
    with open(param_path, 'w', encoding='utf-8') as f:
        json.dump(params, f, indent=2, ensure_ascii=False)
    
    print(f"✅ {param_path} actualizado")

def main():
    print("🔧 Actualizando templates ARM para compliance con Azure Policies...")
    print("📍 Ubicación: canadacentral")
    print("🏷️ Tag requerido: Project")
    print("")
    
    # Mapeo de templates y sus propósitos
    templates_config = {
        'templates/04-appgateway.json': 'Payment Application Gateway',
        'templates/05-monitoring.json': 'Payment Application Monitoring', 
        'templates/06-containerapps.json': 'Payment Application Runtime'
    }
    
    # Actualizar templates
    print("🔄 Actualizando templates...")
    for template_path, purpose in templates_config.items():
        if os.path.exists(template_path):
            update_arm_template(template_path, purpose)
        else:
            print(f"❌ {template_path} no encontrado")
    
    # Actualizar parámetros
    print("\n🔄 Actualizando archivos de parámetros...")
    params_config = [
        ('parameters/dev.03-containerenv.parameters.json', 'IT-PaymentApp', 'DevOps-Team'),
        ('parameters/dev.04-appgateway.parameters.json', 'IT-PaymentApp', 'Network-Team'),
        ('parameters/dev.05-monitoring.parameters.json', 'IT-PaymentApp', 'DevOps-Team'),
        ('parameters/dev.06-containerapps.parameters.json', 'IT-PaymentApp', 'Development-Team')
    ]
    
    for param_path, cost_center, owner in params_config:
        update_parameters_file(param_path, cost_center, owner)
    
    print("\n✅ Todos los templates ARM han sido actualizados para compliance con Azure Policies")
    print("\n📋 Cambios aplicados:")
    print("   ✓ Ubicación cambiada a: canadacentral")
    print("   ✓ Tag 'Project' incluido en todos los recursos")
    print("   ✓ Tags adicionales añadidos: CostCenter, Owner, ManagedBy, Purpose")
    print("   ✓ Archivos de respaldo creados (.bak)")
    print("\n🎯 Próximos pasos:")
    print("   1. Validar templates: az deployment group validate")
    print("   2. Ejecutar what-if: az deployment group what-if")
    print("   3. Desplegar: az deployment group create")

if __name__ == "__main__":
    main()
