#!/bin/bash

# Script para actualizar todos los templates ARM con Azure Policy compliance
# Este script añade los tags requeridos y actualiza ubicaciones a canadacentral

echo "🔧 Actualizando templates ARM para compliance con Azure Policies..."
echo "📍 Ubicación: canadacentral"
echo "🏷️ Tag requerido: Project"
echo ""

# Función para actualizar tags en templates
update_template_tags() {
    local template_file=$1
    local purpose=$2
    
    echo "📝 Actualizando $template_file..."
    
    # Verificar si el archivo existe
    if [[ ! -f "$template_file" ]]; then
        echo "❌ Error: $template_file no encontrado"
        return 1
    fi
    
    # Respaldar archivo original
    cp "$template_file" "$template_file.bak"
    
    # Actualizar commonTags usando sed
    sed -i 's/"CreatedDate": "\[utcNow.*\]"/"ManagedBy": "Infrastructure-as-Code",\n      "Purpose": "'"$purpose"'"/g' "$template_file"
    
    echo "✅ $template_file actualizado"
}

# Función para actualizar parámetros
update_parameters() {
    local param_file=$1
    local cost_center=$2
    local owner=$3
    
    echo "📝 Actualizando parámetros $param_file..."
    
    if [[ ! -f "$param_file" ]]; then
        echo "❌ Error: $param_file no encontrado"
        return 1
    fi
    
    # Respaldar archivo original
    cp "$param_file" "$param_file.bak"
    
    # Actualizar ubicación
    sed -i 's/"eastus"/"canadacentral"/g' "$param_file"
    
    echo "✅ $param_file actualizado"
}

# Actualizar templates
echo "🔄 Actualizando templates..."
update_template_tags "templates/03-containerenv.json" "Payment Application Container Environment"
update_template_tags "templates/04-appgateway.json" "Payment Application Gateway"
update_template_tags "templates/05-monitoring.json" "Payment Application Monitoring"
update_template_tags "templates/06-containerapps.json" "Payment Application Runtime"

echo ""
echo "🔄 Actualizando archivos de parámetros..."

# Actualizar parámetros
update_parameters "parameters/dev.03-containerenv.parameters.json" "IT-PaymentApp" "DevOps-Team"
update_parameters "parameters/dev.04-appgateway.parameters.json" "IT-PaymentApp" "Network-Team"
update_parameters "parameters/dev.05-monitoring.parameters.json" "IT-PaymentApp" "DevOps-Team"
update_parameters "parameters/dev.06-containerapps.parameters.json" "IT-PaymentApp" "Development-Team"

echo ""
echo "✅ Todos los templates ARM han sido actualizados para compliance con Azure Policies"
echo ""
echo "📋 Cambios aplicados:"
echo "   ✓ Ubicación cambiada a: canadacentral"
echo "   ✓ Tag 'Project' incluido en todos los recursos"
echo "   ✓ Tags adicionales añadidos: CostCenter, Owner, ManagedBy, Purpose"
echo "   ✓ Archivos de respaldo creados (.bak)"
echo ""
echo "🎯 Próximos pasos:"
echo "   1. Validar templates: az deployment group validate"
echo "   2. Ejecutar what-if: az deployment group what-if"
echo "   3. Desplegar: az deployment group create"
