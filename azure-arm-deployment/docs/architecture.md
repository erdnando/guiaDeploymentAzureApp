# Documentación de la Arquitectura Azure

## Descripción General

Este proyecto implementa un sistema de pagos moderno utilizando **Azure Container Apps** como plataforma principal de hosting, con **Application Gateway** para balanceador de carga y WAF, y **PostgreSQL Flexible Server** como base de datos.

## Arquitectura de la Solución

### Componentes Principales

```
Internet
    ↓
Application Gateway (WAF v2)
    ↓
Azure Container Apps
    ├── Frontend (React/Vue/Angular)
    └── Backend API (Node.js/Python/.NET)
    ↓
PostgreSQL Flexible Server
```

### Recursos Azure Desplegados

1. **Infraestructura de Red**
   - Virtual Network (VNET) con subnets dedicadas
   - Network Security Groups (NSG) con reglas de seguridad
   - Public IP para Application Gateway

2. **Base de Datos**
   - PostgreSQL Flexible Server 14
   - Configuración de backup automático
   - Integración con VNET para acceso privado

3. **Hosting de Aplicaciones**
   - Container Apps Environment
   - Container Apps para Frontend y Backend
   - Integración con GitHub Container Registry

4. **Load Balancer y Seguridad**
   - Application Gateway v2 con WAF
   - Certificados SSL/TLS
   - Enrutamiento basado en rutas

5. **Monitoreo y Logs**
   - Log Analytics Workspace
   - Application Insights
   - Alertas automáticas

## Flujo de Datos

1. **Usuario → Application Gateway**: Todas las requests llegan al Application Gateway
2. **Application Gateway → Container Apps**: Routing basado en rutas (`/api/*` → Backend, `/*` → Frontend)
3. **Backend → PostgreSQL**: Conexión segura a base de datos vía VNET
4. **Monitoreo**: Logs y métricas enviadas a Log Analytics y Application Insights

## Características de Seguridad

### Network Security
- **WAF (Web Application Firewall)**: Protección contra ataques comunes (OWASP Top 10)
- **NSG Rules**: Control granular de tráfico de red
- **Private Networking**: PostgreSQL accesible solo desde la VNET
- **SSL/TLS**: Encriptación end-to-end

### Access Control
- **Managed Identity**: Autenticación sin credenciales hardcoded
- **Principio de menor privilegio**: Cada componente tiene solo los permisos necesarios
- **Network Isolation**: Componentes separados por subnets

## Escalabilidad y Performance

### Container Apps
- **Auto-scaling**: Escala automáticamente basado en CPU, memoria o requests
- **Revisiones**: Deployments azul/verde automáticos
- **Multi-región**: Soporte para deployment en múltiples regiones

### Application Gateway
- **Auto-scaling**: Escala automáticamente basado en carga
- **Connection Pooling**: Optimización de conexiones
- **Health Probes**: Monitoreo automático de salud de endpoints

### PostgreSQL
- **Compute Scaling**: Escala vertical de vCPUs y memoria
- **Storage Scaling**: Crecimiento automático de almacenamiento
- **Read Replicas**: Soporte para réplicas de lectura

## Monitoring y Observability

### Métricas Clave
- **Application Gateway**: Request rate, response time, error rate
- **Container Apps**: CPU/Memory usage, replica count, request latency
- **PostgreSQL**: Connections, query performance, storage usage

### Logs Centralizados
- **Application Logs**: Logs de aplicación enviados a Log Analytics
- **Access Logs**: Logs de acceso del Application Gateway
- **Audit Logs**: Logs de auditoría de PostgreSQL

### Alertas Automáticas
- **High CPU**: Alertas cuando CPU > 80%
- **Error Rate**: Alertas cuando error rate > 5%
- **Database Connections**: Alertas cuando conexiones > 80% del límite
- **Failed Requests**: Alertas cuando requests fallan > 10/min

## Estimación de Costos

### Ambiente de Desarrollo
- **PostgreSQL (B1ms)**: ~$30/mes
- **Application Gateway (Standard_v2)**: ~$250/mes
- **Container Apps**: ~$0.001/vCPU por segundo (bajo uso: ~$20/mes)
- **Log Analytics**: ~$2.30/GB (estimado: ~$10/mes)
- **Total Estimado**: ~$310/mes

### Ambiente de Producción
- **PostgreSQL (GP_Standard_D2s_v3)**: ~$200/mes
- **Application Gateway (WAF_v2)**: ~$300/mes
- **Container Apps**: ~$0.001/vCPU por segundo (uso medio: ~$100/mes)
- **Log Analytics**: ~$2.30/GB (estimado: ~$50/mes)
- **Total Estimado**: ~$650/mes

## Comparación con Alternativas

### vs. App Service + Azure SQL
| Aspecto | Container Apps + PostgreSQL | App Service + Azure SQL |
|---------|----------------------------|-------------------------|
| **Costo** | ~$310/mes (dev) | ~$200/mes (dev) |
| **Escalabilidad** | Excelente (Kubernetes) | Buena (PaaS) |
| **Flexibilidad** | Alta (cualquier runtime) | Media (runtimes soportados) |
| **Complejidad** | Media | Baja |
| **DevOps** | Contenedores nativos | Deployment tradicional |

### vs. AKS + Azure Database
| Aspecto | Container Apps | AKS |
|---------|---------------|-----|
| **Gestión** | Fully Managed | Semi-managed |
| **Costo** | Sin costo de cluster | Costo de nodes |
| **Complejidad** | Baja | Alta |
| **Control** | Medio | Alto |
| **Time to Market** | Rápido | Lento |

## Ventajas de Esta Arquitectura

### Para Equipos Pequeños
- **Simplicidad**: Menos componentes que gestionar
- **Costo-efectivo**: Solo pagas por lo que usas
- **Rápida implementación**: Infrastructure as Code listo para usar

### Para Escalabilidad
- **Auto-scaling nativo**: Sin configuración manual
- **Performance**: Application Gateway optimizado para high-throughput
- **Disponibilidad**: SLA de 99.95% para Container Apps

### Para Seguridad
- **WAF integrado**: Protección contra ataques web
- **Network isolation**: Componentes aislados por subnets
- **Compliance**: Certificaciones SOC, ISO, HIPAA

## Desventajas y Consideraciones

### Limitaciones
- **Vendor Lock-in**: Específico de Azure
- **Costo fijo**: Application Gateway tiene costo base alto
- **Complejidad de red**: Requiere entendimiento de networking

### Alternativas a Considerar
- **Para proyectos muy pequeños**: App Service + Azure SQL
- **Para equipos expertos**: AKS + Azure Database
- **Para multi-cloud**: Kubernetes vanilla + cloud-agnostic databases

## Casos de Uso Ideales

Esta arquitectura es ideal para:

- **Aplicaciones web modernas** con separación frontend/backend
- **APIs REST/GraphQL** con alta demanda
- **Sistemas de pagos** que requieren alta seguridad
- **Startups en crecimiento** que necesitan escalabilidad
- **Equipos DevOps** que prefieren contenedores
- **Aplicaciones con tráfico variable** que se benefician del auto-scaling

## Próximos Pasos

Después del deployment inicial:

1. **Configurar dominio personalizado** en Application Gateway
2. **Implementar CI/CD** con GitHub Actions
3. **Configurar backup strategy** para PostgreSQL
4. **Optimizar reglas de auto-scaling** basado en métricas reales
5. **Implementar disaster recovery** en otra región
