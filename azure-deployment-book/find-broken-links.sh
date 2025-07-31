#!/bin/bash

# Script para identificar y reportar todos los enlaces rotos en los capítulos
# Usage: ./find-broken-links.sh

echo "🔍 Buscando Enlaces Rotos en Todos los Capítulos"
echo "==============================================="
echo ""

TOTAL_BROKEN=0
TOTAL_FILES=0

# Función para verificar enlaces en un archivo
check_file_links() {
    local file="$1"
    local relative_path="${file#azure-deployment-book/}"
    
    if [ ! -f "$file" ]; then
        return
    fi
    
    ((TOTAL_FILES++))
    local broken_in_file=0
    
    echo "📄 Verificando: $relative_path"
    
    # Buscar enlaces markdown internos que no sean URLs externas
    while IFS= read -r line; do
        # Usar grep para extraer enlaces markdown
        if echo "$line" | grep -q '\[.*\](.*\.md)'; then
            # Extraer enlace usando sed
            link_text=$(echo "$line" | sed -n 's/.*\[\([^]]*\)\](.*/\1/p')
            link_url=$(echo "$line" | sed -n 's/.*\[[^]]*\](\([^)]*\)).*/\1/p')
            
            # Saltar URLs externas
            if [[ "$link_url" =~ ^https?:// ]]; then
                continue
            fi
            
            # Saltar anchors en el mismo archivo
            if [[ "$link_url" =~ ^# ]]; then
                continue
            fi
            
            # Saltar enlaces que ya fueron corregidos (contienen 🚧)
            if [[ "$link_text" =~ 🚧 ]]; then
                continue
            fi
            
            # Construir ruta del archivo
            local target_file=""
            if [[ "$link_url" =~ ^\.\. ]]; then
                # Enlace relativo hacia arriba
                target_file="azure-deployment-book/${link_url#../}"
            elif [[ "$link_url" =~ ^\. ]]; then
                # Enlace relativo en mismo directorio
                local dir=$(dirname "$file")
                target_file="$dir/${link_url#./}"
            else
                # Enlace relativo
                local dir=$(dirname "$file")
                target_file="$dir/$link_url"
            fi
            
            # Quitar anchors para verificar archivo
            target_file="${target_file%%#*}"
            
            # Verificar si el archivo existe
            if [ ! -f "$target_file" ]; then
                echo "  ❌ [$link_text]($link_url) -> $target_file"
                ((broken_in_file++))
                ((TOTAL_BROKEN++))
            fi
        fi
    done < "$file"
    
    if [ $broken_in_file -eq 0 ]; then
        echo "  ✅ Sin enlaces rotos"
    else
        echo "  🚨 $broken_in_file enlaces rotos encontrados"
    fi
    echo ""
}

# Verificar todos los archivos markdown en la estructura del libro
echo "🔍 Escaneando archivos markdown..."
echo ""

# Verificar archivos principales
check_file_links "azure-deployment-book/README.md"
check_file_links "azure-deployment-book/03-introduction/introduccion.md"

# Verificar cada acto
for act_dir in azure-deployment-book/0*-act-*; do
    if [ -d "$act_dir" ]; then
        check_file_links "$act_dir/README.md"
    fi
done

# Verificar otros archivos importantes
check_file_links "azure-deployment-book/00-cover/portada.md"
check_file_links "azure-deployment-book/PREFACE.md"
check_file_links "azure-deployment-book/TABLE-OF-CONTENTS.md"

echo "📊 RESUMEN FINAL:"
echo "================"
echo "Archivos verificados: $TOTAL_FILES"
echo "Enlaces rotos encontrados: $TOTAL_BROKEN"
echo ""

if [ $TOTAL_BROKEN -eq 0 ]; then
    echo "🎉 ¡Perfecto! No se encontraron enlaces rotos."
else
    echo "⚠️  Se encontraron $TOTAL_BROKEN enlaces rotos que necesitan corrección."
    echo ""
    echo "💡 Opciones para corregir:"
    echo "   1. Crear los archivos faltantes"
    echo "   2. Actualizar enlaces para que apunten a contenido existente"
    echo "   3. Usar enlaces temporales como se hizo en ACTO I y ACTO II"
fi

echo ""
echo "🔧 Para corregir automáticamente, puedes:"
echo "   • Ejecutar: ./fix-broken-links.sh (si está disponible)"
echo "   • Reportar específicos con: grep -r '\\[.*\\](.*)' azure-deployment-book/ --include='*.md'"
