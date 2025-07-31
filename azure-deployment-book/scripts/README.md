# 🔧 Scripts del Libro

Este directorio contiene las herramientas de automatización para el mantenimiento del libro.

## 📜 Scripts Disponibles

### 🚀 `generate-full-book.sh`

**Propósito:** Consolida todos los capítulos modulares en un solo archivo para lectura continua.

```bash
# Ejecutar desde el directorio del libro
cd azure-deployment-book
./scripts/generate-full-book.sh
```

**Lo que hace:**
- ✅ Combina todos los capítulos en orden secuencial
- ✅ Limpia enlaces internos para navegación fluida
- ✅ Agrega metadatos y tabla de contenido
- ✅ Genera `LIBRO-COMPLETO.md` listo para lectura

**Salida esperada:**
- 📄 **Archivo:** `LIBRO-COMPLETO.md` 
- 📏 **Líneas:** ~4,000+ líneas
- 💾 **Tamaño:** ~136KB
- ⏱️ **Tiempo:** <2 segundos

### 🔄 Cuándo usar cada script

| Script | Uso | Momento |
|--------|-----|---------|
| `generate-full-book.sh` | Lectura completa | Después de editar capítulos |

## 🎯 Flujo de Trabajo Recomendado

### 📝 **Para Editar Contenido:**
1. Edita los archivos modulares:
   - `04-act-1-cli/README.md`
   - `05-act-2-arm/README.md` 
   - `06-act-3-bicep/README.md`
   - `07-act-4-terraform/README.md`

2. Regenera el libro completo:
   ```bash
   ./scripts/generate-full-book.sh
   ```

### 📖 **Para Leer el Libro:**
- Abre `LIBRO-COMPLETO.md` para experiencia continua
- Usa Ctrl+F para buscar en todo el contenido
- Navegación con anclas internas (#enlaces)

## ⚡ Automatización Futura

### Posibles mejoras:
- 🔄 **Auto-regeneración** con file watchers
- 📊 **Validación** de enlaces rotos
- 🔍 **Indexación** automática de términos
- 📱 **Conversión** a otros formatos (PDF, HTML)

---

**✨ Tip:** Ejecuta `generate-full-book.sh` cada vez que modifiques cualquier capítulo para mantener el libro completo actualizado.
