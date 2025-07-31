#!/bin/bash

# Script simple para encontrar enlaces rotos en archivos markdown
echo "🔍 Búsqueda Rápida de Enlaces Rotos"
echo "==================================="
echo ""

# Función simple para verificar un archivo
check_simple() {
    local file="$1"
    echo "📄 $file:"
    
    # Buscar enlaces a archivos .md que no existen
    grep -n '\[.*\](.*\.md)' "$file" 2>/dev/null | while read -r line_num line_content; do
        # Extraer la URL del enlace
        url=$(echo "$line_content" | sed 's/.*\[.*\](\([^)]*\)).*/\1/')
        
        # Construir ruta del archivo
        if [[ "$url" =~ ^\.\. ]]; then
            target_file="azure-deployment-book/${url#../}"
        elif [[ "$url" =~ ^\. ]]; then
            dir=$(dirname "$file")
            target_file="$dir/${url#./}"
        else
            dir=$(dirname "$file")
            target_file="$dir/$url"
        fi
        
        # Quitar anchor si existe
        target_file="${target_file%%#*}"
        
        # Verificar si existe
        if [ ! -f "$target_file" ] && [[ ! "$line_content" =~ 🚧 ]]; then
            echo "  ❌ Línea $line_num: $url -> $target_file (no existe)"
        fi
    done
    echo ""
}

# Verificar archivos principales
echo "Verificando archivos principales..."
for file in azure-deployment-book/*.md; do
    if [ -f "$file" ]; then
        check_simple "$file"
    fi
done

# Verificar directorios de actos
echo "Verificando capítulos..."
for dir in azure-deployment-book/0*; do
    if [ -d "$dir" ]; then
        for file in "$dir"/*.md; do
            if [ -f "$file" ]; then
                check_simple "$file"
            fi
        done
    fi
done

echo "✅ Verificación completada"
echo ""
echo "💡 Los enlaces con 🚧 son temporales y funcionan correctamente"
