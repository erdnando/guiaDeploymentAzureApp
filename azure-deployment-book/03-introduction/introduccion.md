# Introduction

## Welcome to Infrastructure as Code mastery

Infrastructure as Code (    ║  │  │    │            🐳 Container Apps Environment              │     │   │ ║aC) has fundamentally transformed how organizations deploy and manage cloud resources. What once required manual clicking through web portals, error-prone scripts, and lengthy deployment processes can now be automated, versioned, and repeated consistently across environments.

This book addresses a critical challenge facing cloud engineers today: **choosing the right Infrastructure as Code tool for each specific scenario**. While most resources focus on teaching individual tools in isolation, real-world projects require understanding the strengths, limitations, and optimal use cases for each approach.

## Why this book matters

Modern cloud infrastructure demands several key capabilities that manual processes simply cannot provide:

**Reproducibility:** Infrastructure configurations must be identical across development, testing, and production environments. Manual deployments introduce inconsistencies that lead to the infamous "it works on my machine" problem.

**Version control:** Infrastructure changes need the same rigor as application code, including peer review, rollback capabilities, and audit trails for compliance requirements.

**Scalability:** Organizations need to deploy similar architectures across multiple regions, business units, or client environments without rebuilding solutions from scratch.

**Compliance:** Enterprise environments require consistent application of security policies, naming conventions, and governance rules across all resources.

**Team collaboration:** Multiple engineers must be able to work on infrastructure simultaneously without conflicts or knowledge silos.

This book provides practical experience with four different approaches to achieving these goals on Microsoft Azure, using a realistic enterprise payment system as the foundation for learning.

## What makes this approach unique

Rather than teaching tools as alternatives to choose from, this book builds the **same complete enterprise system four different ways** in **progressive learning stages**:

### Progressive mastery journey

**🎯 Learning path designed for complete mastery:**

1. **Stage 1 - Azure CLI:** Start with imperative commands to understand Azure fundamentals
2. **Stage 2 - ARM Templates:** Build enterprise-grade declarative infrastructure  
3. **Stage 3 - Bicep:** Modernize with type-safe, developer-friendly syntax
4. **Stage 4 - Terraform:** Master multi-cloud and advanced state management

**Why this sequential approach works:**
- Each stage builds foundational knowledge for the next
- You'll understand the evolution and motivation behind each tool
- By the end, you'll know exactly when to use each approach
- No confusion about "which one to choose" - you'll master them all!

### The enterprise payment system

Throughout this **complete journey**, you'll build the same production-ready payment processing system using each technology:

- **Application Gateway** with Web Application Firewall for secure load balancing
- **Container Apps Environment** hosting three microservices (payment, order, and user services)
- **PostgreSQL Flexible Server** with high availability and automated backups
- **Comprehensive monitoring** using Azure Monitor, Log Analytics, and Application Insights
- **Security hardening** with private endpoints, network security groups, and proper RBAC
- **Azure Policy compliance** ensuring consistent governance and tagging across all resources

#### 🏗️ **Enterprise Architecture Diagram**

```
                           📱 Client Applications (Global)
                                      |
                                      ↓
                           🌐 Internet (HTTPS Traffic)
                                      |
                                      ↓
    ╔═══════════════════════════════════════════════════════════════════════════════╗
    ║                    🌍 Azure Region: East US 2                                ║
    ║                                                                               ║
    ║  ┌─────────────────────────────────────────────────────────────────────────┐ ║
    ║  │                    🌐 Virtual Network (VNet)                            │ ║
    ║  │                    Address Space: 10.0.0.0/16                          │ ║
    ║  │                                                                         │ ║
    ║  │  ┌─────────────────────────────────────────────────────────────────┐   │ ║
    ║  │  │               📡 Public Subnet (10.0.1.0/24)                    │   │ ║
    ║  │  │                                                                 │   │ ║
    ║  │  │    ┌─────────────────────────────────────────────────────┐      │   │ ║
    ║  │  │    │         🛡️ Application Gateway + WAF               │      │   │ ║
    ║  │  │    │            • SSL Termination                       │      │   │ ║
    ║  │  │    │            • Load Balancing                        │      │   │ ║
    ║  │  │    │            • Web Application Firewall              │      │   │ ║
    ║  │  │    │            🔗 Public IP: 20.x.x.x                 │      │   │ ║
    ║  │  │    └─────────────────────┬───────────────────────────────┘      │   │ ║
    ║  │  └─────────────────────────│────────────────────────────────────────┘   │ ║
    ║  │                            │                                            │ ║
    ║  │  ┌─────────────────────────│────────────────────────────────────────┐   │ ║
    ║  │  │               🐳 Container Apps Subnet (10.0.2.0/24)            │   │ ║
    ║  │  │                         │                                        │   │ ║
    ║  │  │    ┌────────────────────┴──────────────────────────────────┐     │   │ ║
    ║  │  │    │            � Container Apps Environment              │     │   │ ║
    ║  │  │    │                                                      │     │   │ ║
    ║  │  │    │  ┌─────────────────────────────────────────────────────┐  │     │   │ ║
    ║  │  │    │  │           � Single Zone Deployment                 │  │     │   │ ║
    ║  │  │    │  │                                                     │  │     │   │ ║
    ║  │  │    │  │  💰 Payment Service    📦 Order Service    👤 User  │  │     │   │ ║
    ║  │  │    │  │  • REST API           • REST API          Service  │  │     │   │ ║
    ║  │  │    │  │  • Auth               • Business          • REST    │  │     │   │ ║
    ║  │  │    │  │  • Validation         • Logic             • Identity│  │     │   │ ║
    ║  │  │    │  │  🔄 Auto-scale        🔄 Auto-scale       🔄 Auto-  │  │     │   │ ║
    ║  │  │    │  │                                            scale   │  │     │   │ ║
    ║  │  │    │  └─────────────────────────────────────────────────────┘  │     │   │ ║
    ║  │  │    └────────────────────┬──────────────────────────────────┘     │   │ ║
    ║  │  └─────────────────────────│────────────────────────────────────────┘   │ ║
    ║  │                            │                                            │ ║
    ║  │  ┌─────────────────────────│────────────────────────────────────────┐   │ ║
    ║  │  │            🗄️ Database Subnet (10.0.3.0/24)                     │   │ ║
    ║  │  │               🔒 Private Subnet (No Internet Access)             │   │ ║
    ║  │  │                         │                                        │   │ ║
    ║  │  │    ┌────────────────────┴──────────────────────────────────┐     │   │ ║
    ║  │  │    │        🗄️ PostgreSQL Flexible Server                 │     │   │ ║
    ║  │  │    │                                                      │     │   │ ║
    ║  │  │    │  ╔═══════════╗        ╔═══════════╗                  │     │   │ ║
    ║  │  │    │  ║🏢 Zone 1   ║   🔄   ║🏢 Zone 2   ║                  │     │   │ ║
    ║  │  │    │  ║Primary DB  ║ <───> ║Standby DB ║ (High Availability)│     │   │ ║
    ║  │  │    │  ║           ║        ║           ║                  │     │   │ ║
    ║  │  │    │  ║🔐 Private ║        ║🔐 Private ║                  │     │   │ ║
    ║  │  │    │  ║Endpoint   ║        ║Endpoint   ║                  │     │   │ ║
    ║  │  │    │  ╚═══════════╝        ╚═══════════╝                  │     │   │ ║
    ║  │  │    └─────────────────────────────────────────────────────────┘     │   │ ║
    ║  │  └───────────────────────────────────────────────────────────────────┘   │ ║
    ║  │                                                                         │ ║
    ║  │  ┌───────────────────────────────────────────────────────────────────┐   │ ║
    ║  │  │            📊 Monitoring Subnet (10.0.4.0/24)                    │   │ ║
    ║  │  │                                                                   │   │ ║
    ║  │  │    ┌─────────────────────────────────────────────────────────┐   │   │ ║
    ║  │  │    │           📊 Monitoring & Observability                │   │   │ ║
    ║  │  │    │                                                         │   │   │ ║
    ║  │  │    │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │   │   │ ║
    ║  │  │    │  │📈 Azure     │ │📋 Log       │ │🔍 App       │       │   │   │ ║
    ║  │  │    │  │Monitor      │ │Analytics    │ │Insights     │       │   │   │ ║
    ║  │  │    │  │             │ │             │ │             │       │   │   │ ║
    ║  │  │    │  │• Metrics    │ │• Logs       │ │• APM        │       │   │   │ ║
    ║  │  │    │  │• Alerts     │ │• Queries    │ │• Traces     │       │   │   │ ║
    ║  │  │    │  │• Dashboards │ │• Retention  │ │• Dependency │       │   │   │ ║
    ║  │  │    │  └─────────────┘ └─────────────┘ └─────────────┘       │   │   │ ║
    ║  │  │    └─────────────────────────────────────────────────────────┘   │   │ ║
    ║  │  └───────────────────────────────────────────────────────────────────┘   │ ║
    ║  └─────────────────────────────────────────────────────────────────────────┘ ║
    ║                                                                               ║
    ║  🔐 Network Security Groups (NSGs):                                          ║
    ║  • Public Subnet NSG: Allow HTTPS (443), SSH (22) from Internet             ║
    ║  • Container Apps NSG: Allow HTTP from App Gateway, block Internet          ║
    ║  • Database NSG: Allow PostgreSQL (5432) from Container Apps only           ║
    ║  • Monitoring NSG: Allow monitoring traffic, block external access          ║
    ║                                                                               ║
    ║  � Private Endpoints & Connectivity:                                        ║
    ║  • Database access via Private Endpoint (10.0.3.x)                          ║
    ║  • Key Vault access via Private Endpoint                                     ║
    ║  • Container Registry access via Private Endpoint                            ║
    ║                                                                               ║
    ╚═══════════════════════════════════════════════════════════════════════════════╝

    � Backup Region: West US 2 (Disaster Recovery)
    ├── 🔄 Geo-redundant Database Backups
    ├── 📦 Container Images Replication  
    └── 📊 Cross-region Monitoring Dashboard
```

**🏗️ Infrastructure Components Breakdown:**

**🌍 Regional & Zone Distribution:**
- **Primary Region:** East US 2 (3 Availability Zones)
- **Backup Region:** West US 2 (Disaster Recovery)
- **Multi-zone deployment** for high availability and fault tolerance
- **Zone-redundant services** for 99.99% SLA compliance

**🌐 Network Architecture:**
- **VNet Address Space:** 10.0.0.0/16 (65,536 IP addresses)
- **Subnet Segmentation:** Public, Container Apps, Database, Monitoring
- **Network Security Groups (NSGs):** Layer 4 firewall rules per subnet
- **Private Endpoints:** Secure, private connectivity to PaaS services
- **No direct Internet access** to backend services (zero-trust model)

**🔒 Security & Compliance:**
- **Defense in depth:** Multiple security layers (WAF, NSGs, Private Endpoints)
- **Identity & Access:** Azure AD integration with RBAC
- **Encryption:** In-transit (TLS) and at-rest (AES-256)
- **Compliance:** SOC 2, PCI DSS ready architecture
- **Secret Management:** Azure Key Vault with Private Endpoint access

This realistic system provides context for understanding how each tool handles complex, interconnected infrastructure requirements.

### Progressive learning methodology

By implementing identical functionality with four technologies **in sequence**, you'll develop intuitive understanding of:

- **How CLI automation provides foundation knowledge** (rapid prototyping, troubleshooting, operational tasks)
- **Why ARM Templates build enterprise discipline** (governance, maximum control, compliance)
- **How Bicep improves your daily productivity** (type safety, readability, modern syntax)
- **Where Terraform completes your platform engineering skills** (multi-cloud portability, advanced state management)

## Learning objectives

After completing this book, you will be able to:

### Technical proficiency
- **Deploy enterprise-grade infrastructure** using any of the four major Azure IaC approaches
- **Troubleshoot deployment failures** systematically across different tooling paradigms
- **Implement security best practices** including private networking, policy compliance, and monitoring
- **Design modular, reusable infrastructure patterns** that scale across teams and projects

### Strategic decision-making
- **Evaluate IaC tools** based on specific project requirements, team capabilities, and organizational constraints
- **Plan migration strategies** between different Infrastructure as Code approaches
- **Design tooling strategies** that balance developer productivity with operational requirements
- **Lead technical discussions** about infrastructure automation and cloud architecture

### Operational excellence
- **Establish CI/CD pipelines** for infrastructure deployments across multiple environments
- **Implement monitoring and alerting** that provides actionable insights into system health
- **Create documentation and training materials** that enable team knowledge sharing
- **Contribute to organizational IaC standards** and best practices

## Prerequisites and expectations

This book assumes:

### Technical prerequisites
- **Basic command-line experience** on Windows, macOS, or Linux
- **Fundamental cloud computing concepts** including virtual networks, databases, and compute resources
- **JSON familiarity** for configuration files and parameter management
- **Active Azure subscription** with contributor-level permissions (free tier sufficient for most examples)

### Learning approach
- **Hands-on practice** - You'll execute every example to build practical experience
- **Experimentation mindset** - Modify examples, observe results, and learn from failures
- **Documentation habit** - Keep notes about errors, solutions, and insights for future reference
- **Community engagement** - Ask questions, share experiences, and learn from other practitioners

## How to use this book

This book is designed to accommodate different learning styles and objectives:

### Sequential learning (recommended for beginners)
Work through chapters in order, building foundational understanding before advancing to complex scenarios. Each section builds upon previous concepts while introducing new patterns and best practices.

### Tool-specific focus (for experienced practitioners)
Jump directly to chapters covering tools you need to learn immediately. Each major section is self-contained with necessary context and prerequisites clearly identified.

### Reference usage (for ongoing projects)
Use specific chapters as implementation guides for production deployments. Code examples are production-ready and include comprehensive error handling and security considerations.

### Comparative analysis (for technical decision-making)
Focus on the comparative sections to understand tool selection criteria and migration strategies between different approaches.

## Code conventions and setup

All examples in this book follow consistent conventions:

### Platform compatibility
Code examples work across Windows, macOS, and Linux. When platform-specific differences exist, alternatives are provided for each environment.

### Resource naming
Consistent naming conventions include environment indicators (`dev`, `staging`, `prod`), resource type prefixes, and project identifiers to avoid conflicts and improve organization.

### Security by default
All examples implement security best practices including private networking, least-privilege access, and comprehensive monitoring from initial deployment.

### Cost optimization
Resource sizing and configuration choices balance learning objectives with cost management, ensuring examples remain accessible for individual learning budgets.

## Getting the most value

To maximize your learning experience:

### Set up a dedicated environment
Create a separate Azure subscription or resource group for book exercises to avoid conflicts with existing projects and enable easy cleanup.

### Practice beyond the examples
Modify parameters, experiment with different configurations, and observe how each tool responds to changes. This exploration builds intuitive understanding that goes beyond rote learning.

### Document your journey
Keep detailed notes about errors encountered, solutions discovered, and insights gained. This documentation becomes valuable reference material for future projects.

### Engage with the community
Join Azure and DevOps forums to ask questions, share experiences, and learn from other practitioners facing similar challenges.

---

Your Infrastructure as Code mastery journey begins now. The next chapter introduces Azure CLI automation and starts building the foundation for everything that follows.

---

## 🏗️ **¿Qué Vamos a Construir?**

### 💳 **Sistema de Pagos Enterprise**

No un "Hello World". No un simple VM. **Un sistema real que podrías mostrar en una entrevista.**

```
🌐 Internet
    ↓
🛡️ Application Gateway (Load Balancer + WAF)
    ↓
🐳 Container Apps Environment
    ├── 💰 Payment Service
    ├── 📦 Order Service  
    └── 👤 User Service
    ↓
🗄️ Azure Database for PostgreSQL
```

### 🏷️ **Con Azure Policy Compliance Real**

- ✅ **Required Tags** en todos los recursos
- ✅ **Location restrictions** (solo Canada Central)
- ✅ **Governance completa** como en una empresa real
- ✅ **Security hardening** desde el día 1

### 📊 **+ Monitoring Completo**

- 📈 **Application Insights** para telemetría
- 📋 **Log Analytics** para logs centralizados  
- 🚨 **Alertas** para problemas críticos
- 📊 **Dashboards** para observabilidad

---

## 🎓 **¿Qué Vas a Aprender REALMENTE?**

### 💪 **Skills Técnicos**

#### 🔧 **Infrastructure as Code**
- Principios fundamentales de IaC
- Versionado de infraestructura
- Reproducibilidad y consistencia
- Automatización de despliegues

#### ☁️ **Azure Platform Expertise**
- Container Apps para microservicios
- Application Gateway para load balancing
- PostgreSQL Flexible Server
- VNet y networking avanzado
- Azure Monitor y observabilidad

#### 🛠️ **Tool Mastery**
- **Azure CLI**: Scripting y automation
- **ARM Templates**: Fundación nativa Azure
- **Bicep**: DSL moderna y elegante  
- **Terraform**: Multi-cloud power

### 🧠 **Skills de Pensamiento**

#### 🎯 **Architectural Thinking**
- Cuándo usar cada herramienta
- Trade-offs y decisiones técnicas
- Escalabilidad y mantenibilidad
- Security by design

#### 🚀 **DevOps Mindset**
- Automatización sobre procesos manuales
- Infrastructure as Code como cultura
- Feedback loops rápidos
- Continuous improvement

---

## 👥 **¿Para Quién Es Este Libro?**

### 🎯 **Tu Perfil Ideal:**

#### 🌱 **Si Eres Principiante:**
- **Desarrollador** que quiere entrar al mundo DevOps
- **SysAdmin** migrando de on-premises a cloud
- **Estudiante** con ganas de aprender tecnologías demandadas
- **Career changer** buscando skills del futuro

#### 🚀 **Si Ya Tienes Experiencia:**
- **DevOps Engineer** que quiere comparar herramientas
- **Cloud Architect** evaluando opciones técnicas
- **Consultor** que necesita versatilidad
- **Tech Lead** tomando decisiones de stack

### 📋 **Prerequisites (Mínimos)**

#### ✅ **Técnicos:**
- Conocimiento básico de línea de comandos
- Conceptos básicos de redes (IP, puertos, DNS)
- Familiaridad con JSON (para parámetros)
- Cuenta de Azure (puedes usar free trial)

#### ✅ **Mentales:**
- **Curiosidad** para experimentar y fallar
- **Paciencia** para debugging (las cosas van a fallar)
- **Ganas** de leer documentación cuando sea necesario
- **Persistencia** para no rendirse al primer error

---

## 🎮 **¿Cómo Va a Funcionar Tu Aprendizaje?**

### 🧭 **Metodología "GPS Learning"**

Como un GPS, siempre vas a saber:
- **📍 Dónde estás** - Checkpoint actual
- **🎯 A dónde vas** - Objetivo de la sección
- **🛣️ Cómo llegar** - Pasos específicos
- **🚨 Si te desviaste** - Troubleshooting guides

### 🎪 **Formato "Netflix-Style"**

#### 🎬 **Cada Acto = Un Episodio Completo**
- **Introducción enganchadora** - Por qué esta herramienta
- **Desarrollo práctico** - Hands-on completo
- **Clímax técnico** - Deployment exitoso
- **Conclusión satisfactoria** - Reflexión y next steps

#### ⏯️ **Binge-Friendly**
Puedes leer un acto por día, o los 4 en un fin de semana. **Tú decides el ritmo.**

### 🎯 **Estructura Predictible**

Cada sección sigue el patrón:
1. **🤔 ¿Qué vamos a hacer?** - Objetivo claro
2. **🎯 ¿Por qué es importante?** - Contexto y motivación
3. **👀 ¿Qué esperamos?** - Resultado esperado
4. **⚡ ¡Manos a la obra!** - Código y ejecución
5. **✅ Checkpoint** - Validación de resultados
6. **🎓 Aprendizaje** - Conceptos clave
7. **🎉 Logro** - Celebración del progreso

---

## ⚡ **¿Cómo Maximizar Tu Experiencia?**

### 🛠️ **Setup Recomendado**

#### 💻 **Entorno Técnico:**
```bash
✅ Azure Subscription activa
✅ Visual Studio Code
✅ Azure CLI instalado
✅ Git para versionado
✅ Terminal favorito (bash/zsh/powershell)
```

#### 📚 **Entorno de Aprendizaje:**
```
✅ 2-3 horas continuas por acto
✅ Ambiente sin distracciones  
✅ Bloc de notas para insights
✅ Acceso a Stack Overflow (para cuando falle algo)
```

### 🎯 **Estrategias de Aprendizaje**

#### 🔥 **Para Máximo Impacto:**

1. **🖐️ Hands-On Obligatorio**
   - NO solo leas el código
   - EJECUTA cada comando
   - MODIFICA parámetros y observa resultados

2. **🔄 Experimentación Activa**
   - Cambia nombres de recursos
   - Prueba diferentes configuraciones
   - Rompe cosas a propósito (en entorno dev)

3. **📝 Documentación Personal**
   - Anota errores y soluciones
   - Captura screenshots de resultados
   - Crea tu propio "cheat sheet"

4. **🤝 Aprendizaje Social**
   - Comparte lo que aprendes
   - Haz preguntas en comunidades
   - Enseña conceptos a otros

### 🚨 **Mindset Correcto**

#### ✅ **Expectativas Realistas:**
- **Las cosas VAN a fallar** - Es parte del aprendizaje
- **No vas a entender todo inmediatamente** - Es normal
- **Cada error es una oportunidad** - De aprender algo nuevo
- **La práctica hace la maestría** - Repite hasta que sea natural

#### ❌ **Evita Estos Traps:**
- Saltar los "boring parts" (setup, prerequisites)
- Copiar-pegar sin entender
- Rendirse al primer error de sintaxis
- Comparar tu progreso con otros

---

## 🎪 **¿Qué Te Hace Diferente Después de Este Libro?**

### 🏆 **Tu Nuevo Superpoder**

#### 🎯 **Versatilidad Técnica**
Puedes trabajar en cualquier equipo:
- **Startup usando Terraform** ✅ Dominado
- **Enterprise con ARM Templates** ✅ Dominado  
- **Azure-native shop con Bicep** ✅ Dominado
- **Automation-heavy con Azure CLI** ✅ Dominado

#### 🧠 **Pensamiento Arquitectónico**
No solo ejecutas comandos, **diseñas soluciones:**
- Evalúas trade-offs con conocimiento profundo
- Recomiendas herramientas basado en contexto
- Migras entre tecnologías con confianza
- Mentore as otros en IaC best practices

### 💼 **Impact en Tu Carrera**

#### 📈 **Inmediato (Primeros 3 meses):**
- Conversaciones técnicas más profundas
- Confianza para proponer automatizaciones
- Credibilidad en reuniones de arquitectura
- Capacidad de hacer estimaciones más precisas

#### 🚀 **Mediano Plazo (6-12 meses):**
- Liderazgo en proyectos de migración cloud
- Mentoring de developers junior
- Participación en decisiones de arquitectura
- Reconocimiento como "Azure expert"

#### 🏆 **Largo Plazo (1-2 años):**
- **Roles senior** en equipos DevOps/Platform
- **Consultoría especializada** en IaC
- **Speaking opportunities** en conferencias
- **Network profesional** expandido significativamente

---

## 🎬 **El Momento de la Verdad**

### 🤔 **¿Estás Listo/a Para el Compromiso?**

Este libro no es solo información. **Es una transformación.**

Si estás dispuesto/a a:
- ✅ **Invertir tiempo** en práctica deliberada
- ✅ **Tolerar errores** como parte del proceso
- ✅ **Mantener curiosidad** cuando algo no funcione
- ✅ **Aplicar conocimientos** en proyectos reales

**Entonces este libro va a cambiar tu carrera.**

### 🎯 **Tu Misión, Si Decides Aceptarla:**

> *En las próximas semanas, vas a construir el mismo sistema enterprise 4 veces diferentes. Al final, vas a entender no solo CÓMO hacer Infrastructure as Code, sino CUÁNDO y POR QUÉ elegir cada herramienta.*
>
> *Este conocimiento te va a abrir puertas que ni sabías que existían.*

---

## 🚀 **¡Empecemos la Aventura!**

### 🎭 **Choose Your Own Adventure**

#### ⚡ **Opción A: El Camino Completo**
[🎬 **ACTO I - Azure CLI**: El Poder de los Scripts →](../04-act-1-cli/README.md)

#### 🎯 **Opción B: Directo a Tu Tecnología**
- [🏛️ **ACTO II - ARM Templates**: La Base Fundamental](../05-act-2-arm/README.md)
- [🎨 **ACTO III - Bicep**: La Elegancia Moderna](../06-act-3-bicep/README.md) (En desarrollo)
- [🌍 **ACTO IV - Terraform**: El Gigante Multi-Cloud](../07-act-4-terraform/README.md) (En desarrollo)

---

### 💪 **Una Última Cosa...**

**Cada gran ingeniero que conoces empezó exactamente donde estás tú ahora** - con curiosidad y ganas de aprender algo nuevo.

La diferencia entre los que se quedan donde están y los que crecen exponencialmente es simple: **acción consistente.**

**No esperes a estar "listo/a". Empezá ahora.**

---

*¡Nos vemos en el ACTO I!* 🎬

**[Tu Nombre]**  
*Tu guía en esta aventura Azure*

---

*P.S.: Cuando termines el primer acto, volvé a leer esta introducción. Te vas a sorprender de cuánto has aprendido ya.*

---

## 🧭 Navegación del Libro

**📍 Estás en:** 🎯 Introducción Técnica (03-introduction/introduccion.md)  
**📖 Libro completo:** [../LIBRO-COMPLETO.md](../LIBRO-COMPLETO.md)  

### ⬅️➡️ **Navegación:**
← **Anterior:** [📋 Convenciones de Código](../CODE-CONVENTIONS.md)  
**Siguiente:** [🎭 ACTO I - Azure CLI Scripts](../04-act-1-cli/README.md) →

---

### � **¡Preparación Completada!**

**¡Felicitaciones!** Has completado toda la preparación necesaria:
- ✅ **Entiendes el propósito** del libro (README)
- ✅ **Conoces el contexto** y metodología (Prefacio)  
- ✅ **Sabes las convenciones** de código (Convenciones)
- ✅ **Tienes el contexto técnico** (aquí - Introducción)

### 🚀 **¡Ahora empieza la diversión!**

**A partir de aquí, construirás el mismo sistema 4 veces con diferentes tecnologías:**

| ACTO | Tecnología | ¿Listo para empezar? |
|------|------------|---------------------|
| 🎭 **I** | Azure CLI | **👉 [¡Empezar ACTO I!](../04-act-1-cli/README.md)** |
| �️ **II** | ARM Templates | [Ver ACTO II](../05-act-2-arm/README.md) |
| 🎨 **III** | Bicep | [Ver ACTO III](../06-act-3-bicep/README.md) |
| 🌍 **IV** | Terraform | [Ver ACTO IV](../07-act-4-terraform/README.md) |

### 💡 **Recomendación:**
**Empezá con el ACTO I (Azure CLI)** - es el más fácil y te dará confianza para los siguientes.

---
