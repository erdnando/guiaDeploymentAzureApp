# 📖 Orden de Lectura del Libro - Azure Deployment Mastery

Este archivo define la secuencia de navegación del libro para una experiencia de lectura fluida.

## 🎯 Secuencia de Lectura Recomendada

### 📚 **Secuencia Completa:**

1. **📖 README.md** (Introducción principal)
2. **📜 PREFACE.md** (Prefacio estilo Packt)
3. **📋 CODE-CONVENTIONS.md** (Convenciones de código)
4. **🎯 03-introduction/introduccion.md** (Introducción técnica)
5. **🎭 04-act-1-cli/README.md** (Azure CLI)
6. **🏛️ 05-act-2-arm/README.md** (ARM Templates)
7. **🎨 06-act-3-bicep/README.md** (Bicep)
8. **🌍 07-act-4-terraform/README.md** (Terraform)
9. **⚖️ 08-comparison/comparacion-final.md** (Comparación)
10. **🎯 09-conclusions/conclusiones.md** (Conclusiones)
11. **🚀 10-next-steps/proximos-pasos.md** (Próximos pasos)

### 🔄 **Navegación Alternativa:**

- **📖 Lectura completa:** `LIBRO-COMPLETO.md` (todo en un archivo)
- **🎯 Lectura por tema:** Saltar directamente a un ACTO específico
- **📋 Referencia rápida:** Usar `TABLE-OF-CONTENTS.md`

---

## 🧭 Plantilla de Navegación

### Para el **primer** archivo de la secuencia:
```markdown
---

## 🧭 Navegación del Libro

**📍 Estás en:** [Nombre del archivo actual]  
**📖 Libro completo:** [LIBRO-COMPLETO.md](LIBRO-COMPLETO.md)  

### ➡️ **Continuar Leyendo:**
**Siguiente:** [📜 Prefacio](PREFACE.md) →

---
```

### Para archivos **intermedios**:
```markdown
---

## 🧭 Navegación del Libro

**📍 Estás en:** [Nombre del archivo actual]  
**📖 Libro completo:** [LIBRO-COMPLETO.md](LIBRO-COMPLETO.md)  

### ⬅️➡️ **Navegación:**
← **Anterior:** [Archivo previo](archivo-previo.md)  
**Siguiente:** [Archivo siguiente](archivo-siguiente.md) →

---
```

### Para el **último** archivo:
```markdown
---

## 🧭 Navegación del Libro

**📍 Estás en:** [Nombre del archivo actual]  
**📖 Libro completo:** [LIBRO-COMPLETO.md](LIBRO-COMPLETO.md)  

### ⬅️ **Navegación:**
← **Anterior:** [📯 Conclusiones](../09-conclusions/conclusiones.md)  
🎉 **¡Has completado el libro!** 

### 🔄 **Opciones:**
- 📖 **Releer:** Volver al [📖 Inicio](../README.md)
- 🚀 **Implementar:** Usar los scripts de los [4 ACTOs](../README.md#table-of-contents)
- 💬 **Discutir:** Compartir en redes sociales

---
```

---

## 🤖 Script de Automatización

Se puede crear un script que agregue automáticamente estos enlaces a todos los archivos:

```bash
#!/bin/bash
# add-navigation.sh - Agrega navegación automática a todos los archivos del libro
```

---

**📝 Nota:** Este sistema de navegación se puede regenerar automáticamente junto con el libro completo.
