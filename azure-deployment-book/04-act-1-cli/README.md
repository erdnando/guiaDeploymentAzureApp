# ⚡ ACTO I: Azure CLI - El Primer Paso del Journey

---

> ### 🎉 **¡Comienza tu Journey de Mastery!**
> 
> **¡Bienvenido/a al PRIMER ACTO del journey!** Aquí es donde empiezas a construir expertise real en Infrastructure as Code.
> 
> **🎯 ¿Por qué CLI primero?** Necesitas entender los **fundamentos de Azure** antes de automatizar. CLI te enseña:
> - Cómo funcionan realmente los recursos Azure
> - Qué parámetros y dependencias son críticos  
> - Cómo debuggear cuando las cosas fallan
> 
> **💪 Al completar este acto:** Tendrás las bases sólidas para dominar ARM, Bicep y Terraform en los siguientes actos.

---

## 🎭 **"El Fundamento de Todo Azure Engineer"**

### 🧭 **Tu Posición en el Journey Completo**

```
🎯 Journey Completo:
[ ⚡ ACTO I: CLI ] → [ ACTO II: ARM ] → [ ACTO III: Bicep ] → [ ACTO IV: Terraform ]
   ↑ ESTÁS AQUÍ
```

Azure CLI es como **aprender a caminar antes de correr**. Es la base que hace que todo lo demás tenga sentido:

- ✅ **Entiendes los recursos** desde el nivel más básico
- ✅ **Dominas troubleshooting** cuando otros métodos fallan  
- ✅ **Desarrollas intuición Azure** que aplicarás en todas las tecnologías
- ✅ **Construyes confianza** con resultados inmediatos
- ✅ **Preparas el terreno** para infraestructura declarativa avanzada

**💡 Mindset importante:** No estás "eligiendo CLI" - estás **empezando tu journey completo** con fundamentos sólidos.

---

## 🏗️ **Lo Que Vamos a Construir**

### 💳 **Sistema de Pagos Enterprise (Versión CLI)**

```
🌐 Internet
    ↓
🛡️ Application Gateway + WAF
    ↓  
🐳 Container Apps Environment
    ├── 💰 Payment Service (microservice)
    ├── 📦 Order Service (microservice)
    └── 👤 User Service (microservice)
    ↓
🗄️ Azure PostgreSQL Flexible Server
    ↓
📊 Log Analytics + Application Insights
```

### 🎯 **Con Enterprise-Ready Features**

- 🏷️ **Azure Policy Compliance** (tags, locations, governance)
- 🔒 **Security Hardening** (private endpoints, NSGs)
- 📊 **Full Monitoring Stack** (metrics, logs, alerts)
- 🔄 **Automated Deployment** con scripts modulares
- 🧹 **Easy Cleanup** para development

---

## 📚 Contenido del Capítulo

### � **Fase 1: Preparación y Fundamentos**
- [✅ 1.1 - Environment Setup](../../azure-cli-scripts/scripts/01-setup-environment.sh) (Script de configuración completa)
- [✅ 1.2 - Azure CLI Fundamentals](../../azure-cli-scripts/docs/GUIA-CLI-PASO-A-PASO.md) (Guía completa paso a paso)
- [✅ 1.3 - Project Structure](../../azure-cli-scripts/README.md) (Documentación completa del proyecto CLI)

### 🏗️ **Fase 2: Infraestructura Base**  
- [✅ 2.1 - Resource Group & Networking](../../azure-cli-scripts/scripts/02-create-networking.sh) (Script completo de networking)
- [✅ 2.2 - PostgreSQL Database](../../azure-cli-scripts/scripts/03-create-database.sh) (Script completo de base de datos)

  🏗️ **CONFIGURACIÓN AVANZADA**: Para PostgreSQL con Alta Disponibilidad Zone-Redundant:  
  📖 **Ver**: [azure-cli-scripts/docs/AVANZADO-ALTA-DISPONIBILIDAD.md](../../azure-cli-scripts/docs/AVANZADO-ALTA-DISPONIBILIDAD.md)  
  🚀 **Incluye**: Primary Zone 1, Standby Zone 2, 99.99% SLA, Failover automático < 60s

- [✅ 2.3 - Container Apps Environment](../../azure-cli-scripts/scripts/04-create-container-env.sh) (Script de Container Apps)
- [✅ 2.4 - Monitoring Stack](../../azure-cli-scripts/scripts/05-create-monitoring.sh) (Script completo de monitoreo)

### 🚀 **Fase 3: Servicios de Aplicación**
- [✅ 3.1 - Payment Service](../../azure-cli-scripts/scripts/06-deploy-applications.sh) (Deploy completo de aplicaciones)
- [✅ 3.2 - Order Service](../../azure-cli-scripts/scripts/06-deploy-applications.sh) (Deploy completo de aplicaciones)
- [✅ 3.3 - User Service](../../azure-cli-scripts/scripts/06-deploy-applications.sh) (Deploy completo de aplicaciones)

### � **Fase 4: Seguridad y Exposición**
- [✅ 4.1 - Application Gateway](../../azure-cli-scripts/scripts/07-create-app-gateway.sh) (Script completo de App Gateway)
- [✅ 4.2 - WAF Configuration](../../azure-cli-scripts/scripts/security-check.sh) (Verificaciones de seguridad)
- [✅ 4.3 - Private Endpoints](../../azure-cli-scripts/scripts/security-check.sh) (Verificaciones de seguridad)

### ✅ **Fase 5: Validación y Testing**
- [✅ 5.1 - Health Checks](../../azure-cli-scripts/scripts/check-progress.sh) (Script de verificación completa)
- [✅ 5.2 - Performance Testing](../../azure-cli-scripts/scripts/check-progress.sh) (Script de verificación completa)
- [✅ 5.3 - Monitoring Validation](../../azure-cli-scripts/scripts/check-progress.sh) (Script de verificación completa)

### �️ **Fase 6: Operaciones**
- [✅ 6.1 - Common Issues](../../azure-cli-scripts/docs/TROUBLESHOOTING-JUNIOR.md) (Guía completa de troubleshooting)
- [✅ 6.2 - Scaling Operations](../../azure-cli-scripts/scripts/check-progress.sh) (Operaciones y monitoreo)
- [✅ 6.3 - Backup & Recovery](../../azure-cli-scripts/docs/TROUBLESHOOTING-JUNIOR.md) (Guía de troubleshooting)

### 🧹 **Fase 7: Limpieza y Optimización**
- [✅ 7.1 - Resource Cleanup](../../azure-cli-scripts/scripts/99-cleanup.sh) (Script completo de limpieza)
- [✅ 7.2 - Cost Optimization](../../azure-cli-scripts/docs/QUICK-REFERENCE-CLI.md) (Referencia rápida y optimización)

---

## 🎯 **¿Qué Vas a Aprender en Este Acto?**

### 💪 **Skills Técnicos**

#### ⚡ **Azure CLI Mastery**
- Comandos fundamentales y patrones avanzados
- Scripting y automation con bash/powershell
- Error handling y retry logic
- Output parsing y data manipulation

#### ☁️ **Azure Services Deep Dive**
- **Container Apps**: Microservices modernos en Azure
- **PostgreSQL Flexible Server**: Database managed service
- **Application Gateway**: Load balancing y WAF
- **Monitor Stack**: Log Analytics + App Insights

#### 🛠️ **DevOps Fundamentals**
- Infrastructure automation patterns
- Script modularity y reusability  
- Environment management (dev/prod)
- CI/CD integration basics

### 🧠 **Skills de Pensamiento**

#### 🎯 **Operational Mindset**
- Cuándo usar CLI vs otras herramientas
- Debugging de infraestructura en producción
- Automation vs manual operations
- Script maintainability

#### 🚀 **Enterprise Perspective**
- Azure Policy compliance desde día 1
- Security considerations en cada paso
- Cost optimization continua
- Monitoring y observabilidad

---

## 🎪 **¿Por Qué Este Enfoque?**

### 🧭 **Metodología "GPS Learning"**

#### 📍 **Siempre Sabes Dónde Estás**
```bash
# Cada script empieza con contexto claro
echo "🎯 OBJETIVO: Crear PostgreSQL Flexible Server"
echo "📍 PROGRESO: Paso 2 de 7 - Database Infrastructure"
echo "⏱️  TIEMPO ESTIMADO: 5-10 minutos"
```

#### 🎯 **Cada Comando Tiene Propósito**
```bash
# ¿QUÉ HACEMOS? Crear resource group para database
# ¿POR QUÉ? Necesitamos aislación lógica de recursos
# ¿QUÉ ESPERAR? Resource group "rg-payments-db-dev" creado

az group create \
  --name "rg-payments-db-dev" \
  --location "canadacentral" \
  --tags Project="PaymentSystem" Environment="dev"
```

#### ✅ **Validación Continua**
```bash
# 🎉 CHECKPOINT: Verificar que el resource group existe
az group show --name "rg-payments-db-dev" --output table

# ¿Qué esperamos ver?
# Name                Location      Status
# rg-payments-db-dev  Canada Central Succeeded
```

### 🎮 **Gamificación Sutil**

#### 🏆 **Progress Tracking**
- **🎯 OBJECTIVE** - Sabes hacia dónde vas
- **⚡ ACTION** - Código que ejecutas  
- **✅ CHECKPOINT** - Validación de progreso
- **🎓 LEARNING** - Conceptos que aprendes
- **🎉 ACHIEVEMENT** - Celebración de logros

#### 🚨 **Error Recovery**
- **🔥 COMMON ERROR** - Errores típicos y soluciones
- **🛠️ TROUBLESHOOTING** - Debugging step-by-step
- **💡 PRO TIP** - Insights de experiencia real

### 🎬 **Storytelling Técnico**

#### 📖 **Narrativa Clara**
No solo ejecutas comandos random. **Construyes una historia:**

1. **Setup** - Preparamos el escenario
2. **Foundation** - Construimos la base sólida  
3. **Services** - Agregamos los componentes
4. **Integration** - Todo funciona junto
5. **Validation** - Confirmamos que funciona
6. **Operations** - Mantenemos en funcionamiento

---

## 🚀 **¿Cómo Usar Este Acto?**

### ⚡ **Para Principiantes**

#### 📚 **Lee Completo Primero**
1. Revisa el índice completo
2. Lee Chapter 1 sin ejecutar código
3. Prepara tu environment
4. Ejecuta paso a paso desde 1.1

#### 🎯 **Focus en Comprensión**
- No te apures con los comandos
- Lee los comentarios completamente
- Ejecuta los checkpoints religiosamente
- Haz preguntas en cada LEARNING section

### 🚀 **Para Experimentados**

#### ⚡ **Direct Execution**
1. Skip a Chapter 2 si ya tienes CLI setup
2. Ejecuta scripts completos
3. Modifica parámetros para tus necesidades
4. Focus en patterns y best practices

#### 🎨 **Customization Encouraged**
- Cambia nombres de recursos
- Prueba diferentes configuraciones
- Adapta scripts para tus proyectos
- Experimenta con output formats

### 🏆 **Para Máximo Impact**

#### 💻 **Environment Setup**
```bash
✅ Azure subscription con permisos de contributor
✅ Azure CLI 2.50+ instalado
✅ Bash/Zsh terminal (o PowerShell en Windows)
✅ VS Code para editar scripts
✅ 2-3 horas sin interrupciones
```

#### 📝 **Best Practices**
- Ejecuta en subscription de development
- Usa tu propio suffix para recursos únicos
- Toma screenshots de resultados exitosos
- Documenta errores y soluciones

---

## 🎪 **¿Qué Te Hace Diferente Después de Este Acto?**

### 🎯 **Technical Superpowers**

#### ⚡ **Automation Confidence**
- Puedes automatizar cualquier tarea Azure repetitiva
- Scripts modulares y reutilizables
- Error handling professional-grade
- Integration con cualquier CI/CD pipeline

#### 🛠️ **Troubleshooting Mastery**
- Debugging de infraestructura paso a paso
- Logs analysis con Azure CLI
- Performance investigation
- Security audit capabilities

#### 🚀 **Operational Excellence**
- Environment management profesional
- Resource lifecycle automation
- Cost monitoring y optimization
- Disaster recovery procedures

### 💼 **Career Impact**

#### 📈 **Immediate Value**
- Puedes automatizar deployment de cualquier Azure service
- Troubleshooting rápido en production
- Scripts de recovery para emergencias
- Documentation automática de infraestructura

#### 🏆 **Long-term Growth**
- Foundation sólida para DevOps engineering
- Credibilidad técnica en equipos
- Mentoring capability para juniors
- Platform engineering readiness

---

## 🎬 **¿Listo Para Empezar?**

### 🚀 **Tu Primer Paso**

**Objective**: En los próximos 20 minutos, vas a tener Azure CLI configurado y vas a ejecutar tu primer script de automation.

**Promise**: Al final del día, vas a haber construido un sistema de pagos completo usando solo línea de comandos.

**Outcome**: Mañana, cuando un colega pregunte "¿Cómo automatizan deployments?", vas a tener una respuesta sólida.

---

## 🎯 **¡Empezamos Ya!**

[🚀 **Capítulo 1.1 - Environment Setup** →](./01-setup/environment-setup.md)

---

*"La mejor forma de predecir el futuro es automatizarlo."*  
**— DevOps Engineers, probably**

---

### 📋 **Quick Reference**

- 📁 **[Project Structure](./01-setup/project-structure.md)** - Organización de scripts
- 🔧 **[CLI Fundamentals](./01-setup/cli-fundamentals.md)** - Comandos esenciales
- 🚨 **[Troubleshooting Guide](./06-operations/troubleshooting.md)** - Cuando algo falla
- 🧹 **[Cleanup Scripts](./07-cleanup/cleanup-scripts.md)** - Borrar todo rápido

---

## 🧭 Navegación del Libro

**📍 Estás en:** 🎭 ACTO I - Azure CLI Scripts (04-act-1-cli/README.md)  
**📖 Libro completo:** [../LIBRO-COMPLETO.md](../LIBRO-COMPLETO.md)  

### ⬅️➡️ **Navegación:**
← **Anterior:** [🎯 Introducción Técnica](../03-introduction/introduccion.md)  
**Siguiente:** [🏛️ ACTO II - ARM Templates](../05-act-2-arm/README.md) →

### 🎯 **Continuar en este ACTO:**
- 🚀 **Empezar implementación:** [📁 Capítulo 1.1 - Environment Setup](./01-setup/environment-setup.md)
- 🏗️ **Ver arquitectura:** [🏗️ Capítulo 1.2 - Infrastructure](./02-infrastructure/core-infrastructure.md)
- 🐳 **Deployar servicios:** [🐳 Capítulo 1.3 - Services](./03-services/container-services.md)

### 🎭 **Otros ACTOs:**
- 🏛️ **ACTO II:** [ARM Templates](../05-act-2-arm/README.md) (Enterprise declarativo)
- 🎨 **ACTO III:** [Bicep](../06-act-3-bicep/README.md) (DSL moderno)
- 🌍 **ACTO IV:** [Terraform](../07-act-4-terraform/README.md) (Multi-cloud)

---
