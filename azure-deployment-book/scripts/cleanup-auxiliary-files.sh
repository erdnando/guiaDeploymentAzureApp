#!/bin/bash

# =============================================================================
# 🧹 SCRIPT DE LIMPIEZA - Azure Deployment Book
# =============================================================================
# Este script elimina archivos auxiliares que ya no aportan valor al libro final
# Mantiene backups de seguridad antes de eliminar
#
# Autor: GitHub Copilot & Usuario
# Fecha: $(date +"%Y-%m-%d")
# =============================================================================

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

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =============================================================================
# CONFIGURACIÓN
# =============================================================================

BACKUP_DIR="./backup-$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false

# Archivos auxiliares para eliminar (reportes temporales)
AUXILIARY_FILES=(
    "ENLACES-CORREGIDOS.md"
    "ENLACES-REALES-COMPLETADO.md" 
    "ENLACES-TOTALMENTE-CORREGIDOS.md"
    "LINK-STATUS.md"
    "NAVEGACION-SECUENCIAL-COMPLETADA.md"
    "SOLUCION-HIBRIDA-COMPLETADA.md"
    "TABLE-OF-CONTENTS.md"
    "INDICE-GENERAL.md"
    "READING-SEQUENCE.md"
    "SAMPLE-CHAPTER.md"
    "ANALISIS-LIMPIEZA.md"
)

# Archivos opcionales (decisión del usuario)
OPTIONAL_FILES=(
    "00-cover/portada.md"
    "01-acknowledgments/agradecimientos.md"
    "02-author-notes/notas-autor.md"
)

# =============================================================================
# FUNCIONES
# =============================================================================

show_help() {
    echo "🧹 Azure Deployment Book - Cleanup Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --dry-run     Show what would be deleted without actually deleting"
    echo "  --all         Include optional files (cover, acknowledgments, author notes)"
    echo "  --help        Show this help message"
    echo ""
    echo "Files to be cleaned:"
    printf '%s\n' "${AUXILIARY_FILES[@]}" | sed 's/^/  - /'
    echo ""
    echo "Optional files (only with --all):"
    printf '%s\n' "${OPTIONAL_FILES[@]}" | sed 's/^/  - /'
}

create_backup() {
    log "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    local files_to_backup=("${AUXILIARY_FILES[@]}")
    if [[ "$INCLUDE_OPTIONAL" == "true" ]]; then
        files_to_backup+=("${OPTIONAL_FILES[@]}")
    fi
    
    for file in "${files_to_backup[@]}"; do
        if [[ -f "$file" ]]; then
            cp "$file" "$BACKUP_DIR/" 2>/dev/null
            info "Backed up: $file"
        fi
    done
}

cleanup_auxiliary_files() {
    log "Starting cleanup of auxiliary files..."
    
    local files_to_clean=("${AUXILIARY_FILES[@]}")
    if [[ "$INCLUDE_OPTIONAL" == "true" ]]; then
        files_to_clean+=("${OPTIONAL_FILES[@]}")
    fi
    
    local removed_count=0
    local total_size=0
    
    for file in "${files_to_clean[@]}"; do
        if [[ -f "$file" ]]; then
            local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
            total_size=$((total_size + size))
            
            if [[ "$DRY_RUN" == "true" ]]; then
                warning "Would delete: $file ($(numfmt --to=iec $size))"
            else
                rm "$file"
                log "Deleted: $file ($(numfmt --to=iec $size))"
            fi
            ((removed_count++))
        else
            info "File not found (skipping): $file"
        fi
    done
    
    if [[ "$DRY_RUN" == "true" ]]; then
        warning "DRY RUN: Would remove $removed_count files ($(numfmt --to=iec $total_size) total)"
    else
        log "Cleanup completed: $removed_count files removed ($(numfmt --to=iec $total_size) total)"
    fi
}

show_remaining_files() {
    log "Remaining essential files:"
    
    echo -e "${BLUE}📚 Core Book Files:${NC}"
    find . -maxdepth 1 -name "*.md" -type f | grep -E "(README|PREFACE|CODE-CONVENTIONS|LIBRO-COMPLETO)" | sort
    
    echo -e "${BLUE}📖 Content Files:${NC}"
    find . -name "README.md" -o -name "*.md" | grep -E "(03-introduction|04-act|05-act|06-act|07-act|08-comparison|09-conclusions|10-next-steps)" | sort
    
    echo -e "${BLUE}🔧 Utility Files:${NC}"
    find . -name "README.md" | grep scripts
}

# =============================================================================
# PROCESAMIENTO DE ARGUMENTOS
# =============================================================================

INCLUDE_OPTIONAL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --all)
            INCLUDE_OPTIONAL=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# =============================================================================
# EJECUCIÓN PRINCIPAL
# =============================================================================

log "🧹 Azure Deployment Book Cleanup Script"
log "========================================"

if [[ "$DRY_RUN" == "true" ]]; then
    warning "DRY RUN MODE - No files will actually be deleted"
fi

if [[ "$INCLUDE_OPTIONAL" == "true" ]]; then
    warning "INCLUDING OPTIONAL FILES (cover, acknowledgments, author notes)"
fi

echo

# Mostrar estado actual
info "Current directory contents:"
ls -la *.md 2>/dev/null | wc -l | xargs echo "  - Markdown files in root:"
find . -name "*.md" | wc -l | xargs echo "  - Total markdown files:"

echo

# Crear backup solo si no es dry run
if [[ "$DRY_RUN" == "false" ]]; then
    create_backup
    echo
fi

# Ejecutar limpieza
cleanup_auxiliary_files
echo

# Mostrar archivos restantes
show_remaining_files
echo

# Regenerar libro completo si no es dry run
if [[ "$DRY_RUN" == "false" ]]; then
    log "Regenerating complete book..."
    if [[ -f "./scripts/generate-full-book.sh" ]]; then
        ./scripts/generate-full-book.sh
    else
        warning "Book generation script not found"
    fi
fi

echo
log "🎉 Cleanup completed!"

if [[ "$DRY_RUN" == "false" ]]; then
    log "📦 Backup created in: $BACKUP_DIR"
    log "🔄 To restore files: cp $BACKUP_DIR/* ."
fi

echo
info "📚 Your book is now cleaner and more focused!"
echo -e "${GREEN}===============================================${NC}"
