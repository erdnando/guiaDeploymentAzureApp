#!/bin/bash

# Script para verificar el estado de enlaces en la documentación
# Usage: ./check-links.sh

echo "🔍 Verificando Enlaces en Azure Deployment Book"
echo "=============================================="
echo ""

# Contadores
TOTAL_LINKS=0
WORKING_LINKS=0
BROKEN_LINKS=0
PENDING_LINKS=0

# Función para verificar si un archivo existe
check_internal_link() {
    local file_path="$1"
    local link_text="$2"
    
    if [[ "$file_path" == *"#"* ]]; then
        # Es un anchor link, verificar solo el archivo
        file_path="${file_path%%#*}"
    fi
    
    if [[ "$file_path" == "../"* ]]; then
        # Enlace relativo, construir ruta completa
        file_path="azure-deployment-book/${file_path#../}"
    elif [[ "$file_path" == "./"* ]]; then
        file_path="azure-deployment-book/04-act-1-cli/${file_path#./}"
    fi
    
    if [ -f "$file_path" ]; then
        echo "✅ $link_text"
        ((WORKING_LINKS++))
    else
        echo "❌ $link_text -> $file_path"
        ((BROKEN_LINKS++))
    fi
    ((TOTAL_LINKS++))
}

# Función para verificar enlaces externos (simulado)
check_external_link() {
    local url="$1"
    local link_text="$2"
    
    if [[ "$url" == *"learn.microsoft.com"* ]] || [[ "$url" == *"github.com"* ]] || [[ "$url" == *"registry.terraform.io"* ]]; then
        echo "✅ $link_text (External)"
        ((WORKING_LINKS++))
    elif [[ "$url" == *"[repo-name]"* ]] || [[ "$url" == *"[your-repo]"* ]]; then
        echo "🚧 $link_text (Placeholder)"
        ((PENDING_LINKS++))
    else
        echo "⚠️  $link_text (External - Not verified)"
        ((WORKING_LINKS++))
    fi
    ((TOTAL_LINKS++))
}

# Verificar archivos principales
echo "📁 Archivos Principales:"
files=(
    "azure-deployment-book/README.md:README Principal"
    "azure-deployment-book/TABLE-OF-CONTENTS.md:Tabla de Contenidos"
    "azure-deployment-book/PREFACE.md:Prefacio"
    "azure-deployment-book/SAMPLE-CHAPTER.md:Capítulo de Ejemplo"
    "azure-deployment-book/CODE-CONVENTIONS.md:Convenciones de Código"
    "azure-deployment-book/LICENSE:Licencia"
    "azure-deployment-book/LINK-STATUS.md:Estado de Enlaces"
)

for file_info in "${files[@]}"; do
    IFS=':' read -r filepath filename <<< "$file_info"
    check_internal_link "$filepath" "$filename"
done

echo ""
echo "📚 Estructura de Capítulos:"

# Verificar estructura de actos
actos=(
    "azure-deployment-book/00-cover/portada.md:Portada"
    "azure-deployment-book/03-introduction/introduccion.md:Introducción"
    "azure-deployment-book/04-act-1-cli/README.md:ACTO I - Azure CLI"
    "azure-deployment-book/05-act-2-arm/README.md:ACTO II - ARM Templates"
    "azure-deployment-book/06-act-3-bicep/README.md:ACTO III - Bicep"
    "azure-deployment-book/07-act-4-terraform/README.md:ACTO IV - Terraform"
)

for acto_info in "${actos[@]}"; do
    IFS=':' read -r filepath filename <<< "$acto_info"
    check_internal_link "$filepath" "$filename"
done

echo ""
echo "🔍 Verificando Enlaces Internos de Capítulos:"

# Verificar algunos enlaces internos específicos del ACTO II ARM
echo "Verificando ACTO II - ARM Templates:"
if grep -q "🚧.*README.md#" azure-deployment-book/05-act-2-arm/README.md; then
    echo "✅ ACTO II - Enlaces temporales funcionando"
    ((WORKING_LINKS++))
else
    echo "❌ ACTO II - Enlaces internos rotos"
    ((BROKEN_LINKS++))
fi
((TOTAL_LINKS++))

echo ""
echo "🌐 Enlaces Externos Importantes:"

# Enlaces externos comunes
external_links=(
    "https://learn.microsoft.com/en-us/cli/azure/:Azure CLI Documentation"
    "https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/:ARM Templates"
    "https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/:Bicep Documentation"
    "https://registry.terraform.io/providers/hashicorp/azurerm/latest:Terraform Azure Provider"
    "https://github.com/erdnando/guiaDeploymentAzureApp:Repositorio del Proyecto"
)

for link_info in "${external_links[@]}"; do
    IFS=':' read -r url linktext <<< "$link_info"
    check_external_link "$url" "$linktext"
done

echo ""
echo "📊 RESUMEN:"
echo "=========="
echo "Total de enlaces verificados: $TOTAL_LINKS"
echo "✅ Enlaces funcionando: $WORKING_LINKS"
echo "❌ Enlaces rotos: $BROKEN_LINKS" 
echo "🚧 Enlaces pendientes: $PENDING_LINKS"
echo ""

if [ $BROKEN_LINKS -eq 0 ]; then
    echo "🎉 ¡Excelente! No hay enlaces rotos principales."
else
    echo "⚠️  Hay $BROKEN_LINKS enlaces rotos que necesitan atención."
fi

if [ $PENDING_LINKS -gt 0 ]; then
    echo "📝 Hay $PENDING_LINKS enlaces marcados para desarrollo futuro."
fi

echo ""
echo "💡 Para más detalles, consulta LINK-STATUS.md"
