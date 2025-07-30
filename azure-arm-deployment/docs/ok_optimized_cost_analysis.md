# Análisis de Costos Optimizado: Sistema de Cobranza con Azure

> **Nota importante:**
> Este documento es solo de referencia para costos y arquitectura. Para la implementación, usa:
> - **Principiantes**: [Guía educativa completa](plantillas_arm_azure.md) - ARM Templates paso a paso
> - **Experiencia media**: [Guía de despliegue rápido](deployment-guide.md) - Proceso simplificado
> - **Automatización**: Scripts en `/scripts/deploy.sh` - Despliegue con un comando

## Resumen Ejecutivo

- **Costo mensual estimado optimizado (Fase MVP):** \$54.50 USD (solo Azure)
- **Costo anual estimado optimizado:** \$654.00 USD
- **Optimizaciones aplicadas:**
  - Escala a cero para frontend admin
  - Reducción de recursos en Container Apps
  - Downgrade a PostgreSQL B1ms
  - Sustitución de Front Door por Application Gateway Basic
  - Migración de imágenes Docker a GitHub Container Registry

---

## Detalles del Escenario

### Características del Sistema:

- **Padrón de clientes:** 30,000 registros
- **Transacciones mensuales:** 10,000
- **Alcance geográfico:** Solo México
- **Componentes:**
  - Backend API (integración con pasarela de pago)
  - Frontend de administración (1 admin)
  - Generación de líneas de captura bancaria
  - Generación de PDFs
  - Envío de WhatsApp
  - Base de datos de clientes

---

## Desglose de Costos por Componente Optimizado

### 1. Azure Container Apps (Backend API + Frontend React Admin)

**Configuración optimizada:**

- **Backend API (.NET Core):** 0.25 vCPU, 0.5 GiB RAM, mín 1 réplica, máx 2 réplicas
- **Frontend React Admin:** 0.25 vCPU, 0.5 GiB RAM, escala a cero habilitado

**Costo estimado:** \~\$18.00/mes

---

### 2. Azure Database for PostgreSQL Flexible Server

**Configuración optimizada:**

- **Tier:** General Purpose (B1ms)
- **Compute:** 1 vCore, 2 GB RAM
- **Storage:** 32 GB SSD (con auto-growth habilitado)
- **Backup retention:** 7 días
- **Alta disponibilidad:** Deshabilitado

**Costo estimado:**

- Compute: \~\$18.00/mes
- Storage: \~\$4.50/mes
- **Total PostgreSQL:** \~\$22.50/mes

---

### 3. Azure Application Gateway (Basic Tier)

**Motivo de reemplazo:** Sustituye a Azure Front Door para reducir costos.

- Nivel básico con SSL
- Configurado con path-based routing: 
  - `/api/*` → API Backend (.NET Core)
  - `/*` → Frontend React
- No incluye CDN ni WAF (evaluar en etapas futuras)

**Costo estimado:** \~\$14.00/mes

---

### 4. GitHub Container Registry

- Tier: GitHub Free/Pro (incluido en cuenta GitHub)
- Almacenamiento para imágenes Docker
- **Costo estimado:** \$0.00/mes

---

### 5. Log Analytics Workspace

- Nivel gratuito (hasta 5 GB/mes)
- **Costo estimado:** \$0/mes

---

## Arquitectura Final Recomendada (Optimizada)

### Configuración Completa:

```
Container Apps:                    $18.00
PostgreSQL Flexible Server:       $22.50
Application Gateway Basic:        $14.00
GitHub Container Registry:         $0.00
Log Analytics (free tier):        $0.00
────────────────────────────────────────
TOTAL MENSUAL AZURE:              $54.50
TOTAL ANUAL AZURE:               $654.00
```

---

## Recomendaciones Adicionales

### PostgreSQL:

- Usar PgBouncer para pool de conexiones
- Monitoreo con alertas de CPU y almacenamiento

### Container Apps:

- Activar health checks específicos:
  - Backend API: endpoint `/api/health`
  - Frontend React: verificar página principal
- Configurar scale-to-zero en frontend admin React
- Definir variables de entorno para CORS y configuración de API URL
- Revisar métricas reales para ajustar CPU y RAM según patrones de uso

### Application Gateway:

- Activar SSL
- Configurar path-based routing para separar frontend y API
- Optimizar caché para activos estáticos del frontend React
- Establecer health probes específicos para cada servicio
- Evaluar WAF y CDN externo en futuras fases si el tráfico lo requiere

---

## Consideraciones Locales para México
- **Revisar datos actualizados:** https://azurespeedtest.azurewebsites.net/
- **Latencia:** Usar Azure East US (más cercano a México)
- **Cumplimiento:** LFPDPPP y PCI DSS
- **Moneda:** Considerar tipo de cambio USD/MXN

---

## Cronograma de Implementación

### Fase 1: MVP (Mes 1–2) - \$59.50/mes

- Container Apps con recursos mínimos
- PostgreSQL B1ms
- Application Gateway básico
- Solo servicios esenciales

### Fase 2: Producción (Mes 3+)

- Escalar PostgreSQL a B2ms si es necesario
- Considerar WAF + CDN
- Personalizar dominio y certificado SSL

### Fase 3: Optimización (Mes 6+)

- Evaluar instancias reservadas
- Read replicas si crecen los reportes
- Fine-tuning de scaling y caching

---

## Alertas de Costo Recomendadas

1. **Presupuesto mensual:** \$60 USD
2. **Container Apps:** CPU > 80%
3. **PostgreSQL:** CPU, Storage o conexiones > 80%
4. **Application Gateway:** > 10 GB transferencia (tráfico inusual)
5. **GitHub Container Registry:** Monitoreo de uso (para evitar exceder límites gratuitos)

---

## Conclusión

Con esta arquitectura optimizada se logra una reducción de **\~60% del costo mensual** sin sacrificar funcionalidad esencial. Se recomienda escalar y agregar seguridad avanzada conforme crezca la carga real del sistema.

**Costo mensual objetivo:** \~\$54.50 USD\
**Costo anual estimado:** \~\$654.00 USD

