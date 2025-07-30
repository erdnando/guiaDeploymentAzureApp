#!/usr/bin/env python3
"""
Script para actualizar todos los módulos BICEP con Azure Policy compliance
Añade parámetros de governance y tags requeridos
"""

import json
import os
import re
from typing import Dict, List

def update_bicep_module(module_path: str, purpose: str) -> bool:
    """Actualiza un módulo BICEP con parámetros de governance"""
    
    print(f"📝 Actualizando {module_path}...")
    
    if not os.path.exists(module_path):
        print(f"❌ Error: {module_path} no encontrado")
        return False
    
    # Leer archivo
    with open(module_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Crear backup
    backup_path = f"{module_path}.bak"
    with open(backup_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    # 1. Añadir parámetros de governance si no existen
    governance_params = """
@description('Centro de costos para facturación')
param costCenter string = 'IT-Development'

@description('Responsable del recurso')
param owner string = 'DevOps-Team'
"""
    
    # Buscar donde insertar los parámetros (antes de // Variables)
    if '@description(\'Centro de costos para facturación\')' not in content:
        # Buscar el último parámetro antes de // Variables
        pattern = r'(param [^=\n]+ = [^\n]+\n)(\n// Variables)'
        replacement = rf'\1{governance_params}\2'
        content = re.sub(pattern, replacement, content)
    
    # 2. Actualizar commonTags
    old_tags_pattern = r'var commonTags = \{[^}]+\}'
    new_tags = f"""var commonTags = {{
  Environment: environment
  Project: projectName
  CostCenter: costCenter
  Owner: owner
  CreatedBy: 'BICEP Template'
  ManagedBy: 'Infrastructure-as-Code'
  Purpose: '{purpose}'
}}"""
    
    content = re.sub(old_tags_pattern, new_tags, content, flags=re.DOTALL)
    
    # Escribir archivo actualizado
    with open(module_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ {module_path} actualizado")
    return True

def update_main_bicep() -> bool:
    """Actualiza main.bicep para pasar parámetros a todos los módulos"""
    
    main_path = 'main.bicep'
    print(f"📝 Actualizando {main_path}...")
    
    if not os.path.exists(main_path):
        print(f"❌ Error: {main_path} no encontrado")
        return False
    
    with open(main_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Crear backup
    with open(f"{main_path}.bak", 'w', encoding='utf-8') as f:
        f.write(content)
    
    # Actualizar llamadas a módulos para incluir costCenter y owner
    modules_to_update = [
        ('postgresql', 'Payment Application Database'),
        ('containerEnvironment', 'Payment Application Container Environment'),
        ('monitoring', 'Payment Application Monitoring'),
        ('containerApps', 'Payment Application Runtime'),
        ('applicationGateway', 'Payment Application Gateway')
    ]
    
    for module_name, purpose in modules_to_update:
        # Buscar la definición del módulo
        pattern = rf'(module {module_name}[^{{]+\{{[^}}]+params:\s*\{{[^}}]+)(\s*\}}\s*\}})'
        
        def add_governance_params(match):
            params_section = match.group(1)
            closing = match.group(2)
            
            # Verificar si ya tiene los parámetros
            if 'costCenter:' not in params_section:
                # Añadir antes del closing
                params_section += '\n    costCenter: costCenter\n    owner: owner'
            
            return params_section + closing
        
        content = re.sub(pattern, add_governance_params, content, flags=re.DOTALL)
    
    with open(main_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ {main_path} actualizado")
    return True

def update_parameters_file() -> bool:
    """Actualiza archivo de parámetros con nueva ubicación y tags"""
    
    params_path = 'parameters/dev-parameters.json'
    print(f"📝 Actualizando {params_path}...")
    
    if not os.path.exists(params_path):
        print(f"❌ Error: {params_path} no encontrado")
        return False
    
    # Crear backup
    backup_path = f"{params_path}.bak"
    
    with open(params_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    with open(backup_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
    
    # Actualizar ubicación
    if 'location' in data['parameters']:
        data['parameters']['location']['value'] = 'canadacentral'
    
    # Añadir nuevos parámetros si no existen
    if 'costCenter' not in data['parameters']:
        data['parameters']['costCenter'] = {'value': 'IT-PaymentApp'}
    
    if 'owner' not in data['parameters']:
        data['parameters']['owner'] = {'value': 'DevOps-Team'}
    
    # Escribir archivo actualizado
    with open(params_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
    
    print(f"✅ {params_path} actualizado")
    return True

def main():
    """Función principal"""
    print("🔧 Actualizando módulos BICEP para compliance con Azure Policies...")
    print("📍 Ubicación: canadacentral")
    print("🏷️ Tag requerido: Project")
    print("")
    
    # Módulos a actualizar
    modules = [
        ('bicep/modules/02-postgresql.bicep', 'Payment Application Database'),
        ('bicep/modules/03-containerenv.bicep', 'Payment Application Container Environment'),
        ('bicep/modules/04-appgateway.bicep', 'Payment Application Gateway'),
        ('bicep/modules/05-monitoring.bicep', 'Payment Application Monitoring'),
        ('bicep/modules/06-containerapps.bicep', 'Payment Application Runtime')
    ]
    
    print("🔄 Actualizando módulos...")
    for module_path, purpose in modules:
        update_bicep_module(module_path, purpose)
    
    print("")
    print("🔄 Actualizando main.bicep...")
    update_main_bicep()
    
    print("")
    print("🔄 Actualizando archivo de parámetros...")
    update_parameters_file()
    
    print("")
    print("✅ Todos los módulos BICEP han sido actualizados para compliance con Azure Policies")
    print("")
    print("📋 Cambios aplicados:")
    print("   ✓ Ubicación cambiada a: canadacentral")
    print("   ✓ Tag 'Project' incluido en todos los recursos")
    print("   ✓ Tags adicionales añadidos: CostCenter, Owner, ManagedBy, Purpose")
    print("   ✓ Archivos de respaldo creados (.bak)")
    print("")
    print("🎯 Próximos pasos:")
    print("   1. Validar templates: az deployment group validate")
    print("   2. Ejecutar what-if: az deployment group what-if")
    print("   3. Desplegar: az deployment group create")

if __name__ == "__main__":
    main()
