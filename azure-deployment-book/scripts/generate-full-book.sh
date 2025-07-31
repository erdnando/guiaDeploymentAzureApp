#!/bin/bash

# =============================================================================
# 📚 GENERADOR DE LIBRO COMPLETO - Azure Deployment Mastery
# =============================================================================
# Este script consolida todos los capítulos modulares en un solo archivo
# para una experiencia de lectura continua tipo libro tradicional.
#
# Autor: GitHub Copilot & Usuario
# Fecha: $(date +"%Y-%m-%d")
# =============================================================================

# Configuración
BOOK_DIR="/home/erdnando/proyectos/azure/GuiaAzureApp/azure-deployment-book"
OUTPUT_FILE="$BOOK_DIR/LIBRO-COMPLETO.md"
TEMP_FILE="/tmp/libro-completo.tmp"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Función para limpiar enlaces internos y convertirlos a anclas
clean_internal_links() {
    local file="$1"
    # Convertir enlaces a otros archivos del libro en anclas internas
    sed -i.bak 's|\.\./[^/)]*/README\.md#|\#|g' "$file"
    sed -i.bak 's|\./[^/)]*/README\.md#|\#|g' "$file"
    sed -i.bak 's|README\.md#|\#|g' "$file"
    # Limpiar referencias a archivos del proyecto (mantener enlaces externos)
    # Nota: Los enlaces a scripts y templates se mantienen como están
}

# Función para eliminar secciones de navegación (libro completo debe ser lineal)
remove_navigation_sections() {
    local file="$1"
    info "Limpiando secciones de navegación..."
    
    # Eliminar secciones completas de navegación
    sed -i '/## 🧭 Navegación del Libro/,/---$/d' "$file"
    
    # Eliminar menciones de opciones alternativas
    sed -i '/### 🎯 \*\*Rutas Alternativas:\*\*/,/---$/d' "$file"
    
    # Limpiar backup files
    rm -f "${file}.bak" 2>/dev/null
}

# Función para agregar tabla de contenido dinámica
generate_toc() {
    local file="$1"
    info "Generando tabla de contenido dinámica..."
    
    # Extraer todos los encabezados y crear TOC
    echo -e "\n## 📋 Tabla de Contenido Dinámica\n" > /tmp/toc.tmp
    
    grep -n "^#" "$file" | head -50 | while IFS=: read -r line_num header; do
        # Limpiar el encabezado y crear ancla
        clean_header=$(echo "$header" | sed 's/^#*[ ]*//' | sed 's/[^a-zA-Z0-9 -]//g' | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
        level=$(echo "$header" | grep -o '^#*' | wc -c)
        indent=""
        for ((i=2; i<level; i++)); do indent="  $indent"; done
        
        echo "$indent- [$header](#$clean_header)" >> /tmp/toc.tmp
    done
    
    echo -e "\n---\n" >> /tmp/toc.tmp
}

# =============================================================================
# INICIO DEL SCRIPT
# =============================================================================

log "🚀 Iniciando generación del libro completo..."
log "📂 Directorio base: $BOOK_DIR"
log "📄 Archivo salida: $OUTPUT_FILE"

# Verificar que el directorio existe
if [ ! -d "$BOOK_DIR" ]; then
    error "El directorio del libro no existe: $BOOK_DIR"
    exit 1
fi

# Crear archivo temporal
> "$TEMP_FILE"

log "📝 Construyendo libro completo..."

# =============================================================================
# SECCIÓN 1: CABECERA Y METADATOS
# =============================================================================
info "Adding header and metadata..."

cat >> "$TEMP_FILE" << 'EOF'
# 📚 Azure Deployment Mastery
## *Domina Infrastructure as Code con CLI, ARM, Bicep y Terraform*

> **Libro Técnico Completo** - Estilo Packt Publishing  
> **Versión Consolidada** - Lectura continua sin interrupciones  
> **Fecha de generación:** $(date +"%d de %B de %Y")  
> **Autores:** GitHub Copilot & Equipo de Desarrollo

---

### 🎯 **Sobre Este Libro**

Este es el **libro completo consolidado** diseñado para una **experiencia de lectura lineal y progresiva**. 

Empezarás con los fundamentos de Azure CLI y avanzarás paso a paso hasta dominar las 4 tecnologías principales de Infrastructure as Code:

**🎯 Tu Journey Progresivo:**
1. **Azure CLI** → Fundamentos y scripting
2. **ARM Templates** → Infraestructura declarativa enterprise  
3. **Bicep** → Modernización del developer experience
4. **Terraform** → Platform engineering multi-cloud

**📚 Instrucciones:** Simplemente continúa leyendo de forma secuencial. Cada sección construye sobre la anterior.

---

EOF

# =============================================================================
# SECCIÓN 2: CONTENIDO PRINCIPAL DEL LIBRO
# =============================================================================

info "Agregando contenido principal..."

# Agregar PREFACE
if [ -f "$BOOK_DIR/PREFACE.md" ]; then
    log "📖 Agregando: PREFACE"
    echo -e "\n\n# 📖 PREFACIO\n" >> "$TEMP_FILE"
    cat "$BOOK_DIR/PREFACE.md" >> "$TEMP_FILE"
    echo -e "\n---\n" >> "$TEMP_FILE"
fi

# Agregar CODE CONVENTIONS (OMITIDO para experiencia lineal)
# if [ -f "$BOOK_DIR/CODE-CONVENTIONS.md" ]; then
#     log "📋 Agregando: CODE CONVENTIONS"
#     echo -e "\n\n# 📋 CONVENCIONES DE CÓDIGO\n" >> "$TEMP_FILE"
#     cat "$BOOK_DIR/CODE-CONVENTIONS.md" >> "$TEMP_FILE"
#     echo -e "\n---\n" >> "$TEMP_FILE"
# fi

# Agregar INTRODUCCIÓN
if [ -f "$BOOK_DIR/03-introduction/introduccion.md" ]; then
    log "🎯 Agregando: INTRODUCCIÓN"
    echo -e "\n\n# 🎯 INTRODUCCIÓN AL LIBRO\n" >> "$TEMP_FILE"
    cat "$BOOK_DIR/03-introduction/introduccion.md" >> "$TEMP_FILE"
    echo -e "\n---\n" >> "$TEMP_FILE"
fi

# =============================================================================
# SECCIÓN 3: LOS 4 ACTOS PRINCIPALES
# =============================================================================

log "🎭 Agregando los 4 ACTOS principales..."

# ACTO I - Azure CLI
if [ -f "$BOOK_DIR/04-act-1-cli/README.md" ]; then
    log "🎭 Agregando: ACTO I - Azure CLI"
    echo -e "\n\n# 🎭 ACTO I - Azure CLI Scripts\n" >> "$TEMP_FILE"
    echo "> **Domina Azure desde la línea de comandos**" >> "$TEMP_FILE"
    echo -e "\n" >> "$TEMP_FILE"
    cat "$BOOK_DIR/04-act-1-cli/README.md" >> "$TEMP_FILE"
    echo -e "\n---\n" >> "$TEMP_FILE"
fi

# ACTO II - ARM Templates
if [ -f "$BOOK_DIR/05-act-2-arm/README.md" ]; then
    log "🏛️ Agregando: ACTO II - ARM Templates"
    echo -e "\n\n# 🏛️ ACTO II - ARM Templates\n" >> "$TEMP_FILE"
    echo "> **Infrastructure as Code con JSON declarativo**" >> "$TEMP_FILE"
    echo -e "\n" >> "$TEMP_FILE"
    cat "$BOOK_DIR/05-act-2-arm/README.md" >> "$TEMP_FILE"
    echo -e "\n---\n" >> "$TEMP_FILE"
fi

# ACTO III - Bicep
if [ -f "$BOOK_DIR/06-act-3-bicep/README.md" ]; then
    log "🎨 Agregando: ACTO III - Bicep"
    echo -e "\n\n# 🎨 ACTO III - Bicep Modules\n" >> "$TEMP_FILE"
    echo "> **DSL moderno para Azure Resource Manager**" >> "$TEMP_FILE"
    echo -e "\n" >> "$TEMP_FILE"
    cat "$BOOK_DIR/06-act-3-bicep/README.md" >> "$TEMP_FILE"
    echo -e "\n---\n" >> "$TEMP_FILE"
fi

# ACTO IV - Terraform
if [ -f "$BOOK_DIR/07-act-4-terraform/README.md" ]; then
    log "🌍 Agregando: ACTO IV - Terraform"
    echo -e "\n\n# 🌍 ACTO IV - Terraform\n" >> "$TEMP_FILE"
    echo "> **Multi-cloud Infrastructure as Code**" >> "$TEMP_FILE"
    echo -e "\n" >> "$TEMP_FILE"
    cat "$BOOK_DIR/07-act-4-terraform/README.md" >> "$TEMP_FILE"
    echo -e "\n---\n" >> "$TEMP_FILE"
fi

# =============================================================================
# SECCIÓN 4: COMPARACIÓN Y CONCLUSIONES
# =============================================================================

# Agregar COMPARACIÓN
if [ -f "$BOOK_DIR/08-comparison/comparacion-final.md" ]; then
    log "⚖️ Agregando: COMPARACIÓN FINAL"
    echo -e "\n\n# ⚖️ COMPARACIÓN FINAL DE TECNOLOGÍAS\n" >> "$TEMP_FILE"
    cat "$BOOK_DIR/08-comparison/comparacion-final.md" >> "$TEMP_FILE"
    echo -e "\n---\n" >> "$TEMP_FILE"
fi

# Agregar CONCLUSIONES
if [ -f "$BOOK_DIR/09-conclusions/conclusiones.md" ]; then
    log "🎯 Agregando: CONCLUSIONES"
    echo -e "\n\n# 🎯 CONCLUSIONES Y RECOMENDACIONES\n" >> "$TEMP_FILE"
    cat "$BOOK_DIR/09-conclusions/conclusiones.md" >> "$TEMP_FILE"
    echo -e "\n---\n" >> "$TEMP_FILE"
fi

# Agregar PRÓXIMOS PASOS
if [ -f "$BOOK_DIR/10-next-steps/proximos-pasos.md" ]; then
    log "🚀 Agregando: PRÓXIMOS PASOS"
    echo -e "\n\n# 🚀 PRÓXIMOS PASOS Y RECURSOS\n" >> "$TEMP_FILE"
    cat "$BOOK_DIR/10-next-steps/proximos-pasos.md" >> "$TEMP_FILE"
    echo -e "\n---\n" >> "$TEMP_FILE"
fi

# =============================================================================
# SECCIÓN 5: POSTPROCESAMIENTO
# =============================================================================

log "🔧 Aplicando postprocesamiento..."

# Limpiar enlaces internos
info "Limpiando enlaces internos..."
clean_internal_links "$TEMP_FILE"

# Eliminar todas las secciones de navegación para experiencia lineal
remove_navigation_sections "$TEMP_FILE"

# Agregar metadatos finales
cat >> "$TEMP_FILE" << EOF

---

## 📊 Metadatos del Libro

- **📅 Generado:** $(date +"%d/%m/%Y a las %H:%M:%S")
- **🔗 Repositorio:** [GitHub - GuiaAzureApp](https://github.com/erdnando/guiaDeploymentAzureApp)
- **📝 Versión:** Consolidada automática
- **🛠️ Generado por:** generate-full-book.sh
- **📏 Líneas totales:** $(wc -l < "$TEMP_FILE") líneas
- **📄 Tamaño:** $(du -h "$TEMP_FILE" | cut -f1)

### 🔄 Regenerar este libro

Para regenerar este archivo con los cambios más recientes:

\`\`\`bash
cd azure-deployment-book
./scripts/generate-full-book.sh
\`\`\`

### 📂 Estructura modular para edición

Para editar contenido específico, usa estos archivos:

- \`04-act-1-cli/README.md\` - Azure CLI
- \`05-act-2-arm/README.md\` - ARM Templates  
- \`06-act-3-bicep/README.md\` - Bicep Modules
- \`07-act-4-terraform/README.md\` - Terraform

---

**¡Gracias por leer Azure Deployment Mastery!** 🚀

EOF

# =============================================================================
# SECCIÓN 6: FINALIZACIÓN
# =============================================================================

# Mover archivo temporal al destino final
mv "$TEMP_FILE" "$OUTPUT_FILE"

# Limpiar archivos temporales
rm -f /tmp/toc.tmp
rm -f "$OUTPUT_FILE.bak" 2>/dev/null

# Estadísticas finales
LINES=$(wc -l < "$OUTPUT_FILE")
SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)

log "✅ ¡Libro completo generado exitosamente!"
log "📄 Archivo: $OUTPUT_FILE"
log "📏 Líneas: $LINES"
log "📦 Tamaño: $SIZE"

info "🎉 El libro está listo para lectura continua"
info "🔧 Para editar, usa los archivos modulares individuales"
info "🔄 Para regenerar, ejecuta este script nuevamente"

echo
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}🎯 LIBRO COMPLETO GENERADO EXITOSAMENTE${NC}"
echo -e "${GREEN}===============================================${NC}"
echo -e "📚 Archivo: ${BLUE}$OUTPUT_FILE${NC}"
echo -e "📊 Líneas: ${YELLOW}$LINES${NC}"
echo -e "💾 Tamaño: ${YELLOW}$SIZE${NC}"
echo -e "${GREEN}===============================================${NC}"
