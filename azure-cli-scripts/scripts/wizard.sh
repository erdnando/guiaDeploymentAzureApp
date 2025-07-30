#!/bin/bash

# ============================================================================
# wizard.sh
# Wizard interactivo para guiar a ingenieros junior paso a paso
# ============================================================================

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

clear

echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                                                                                      ║${NC}"
echo -e "${PURPLE}║                    🧙‍♂️ WIZARD AZURE CLI - SISTEMA DE PAGOS                          ║${NC}"
echo -e "${PURPLE}║                                                                                      ║${NC}"
echo -e "${PURPLE}║                     Guía Interactiva para Ingenieros Junior                         ║${NC}"
echo -e "${PURPLE}║                                                                                      ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${CYAN}👋 ¡Hola! Soy tu asistente para implementar el sistema de pagos.${NC}"
echo -e "${CYAN}Te guiaré paso a paso para que no te pierdas.${NC}"

# Función para pausar y esperar input del usuario
wait_for_user() {
    echo -e "\n${YELLOW}Presiona Enter cuando hayas leído y estés listo para continuar...${NC}"
    read -r
}

# Función para ejecutar comando con confirmación
execute_with_confirmation() {
    local script_path=$1
    local script_name=$2
    local description=$3
    local estimated_time=$4
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📋 PRÓXIMO PASO: $script_name${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "\n${YELLOW}¿Qué vamos a hacer?${NC}"
    echo -e "$description"
    echo -e "\n${CYAN}⏱️  Tiempo estimado: $estimated_time${NC}"
    echo -e "\n${GREEN}¿Deseas ejecutar este paso? (y/N/s=saltar):${NC}"
    read -r response
    
    case $response in
        [Yy]*)
            echo -e "\n${GREEN}🚀 Ejecutando $script_name...${NC}"
            if [[ -x "$script_path" ]]; then
                echo "Comando: $script_path"
                echo ""
                $script_path
                
                if [[ $? -eq 0 ]]; then
                    echo -e "\n${GREEN}✅ $script_name completado exitosamente!${NC}"
                    wait_for_user
                else
                    echo -e "\n${RED}❌ Error en $script_name${NC}"
                    echo -e "${YELLOW}¿Qué deseas hacer?${NC}"
                    echo "1. Reintentar"
                    echo "2. Ver troubleshooting"
                    echo "3. Salir"
                    read -r error_response
                    
                    case $error_response in
                        1) execute_with_confirmation "$script_path" "$script_name" "$description" "$estimated_time" ;;
                        2) ./scripts/98-troubleshoot.sh ;;
                        *) exit 1 ;;
                    esac
                fi
            else
                echo -e "${RED}❌ Script no encontrado o no ejecutable: $script_path${NC}"
                return 1
            fi
            ;;
        [Ss]*)
            echo -e "${YELLOW}⏭️  Saltando $script_name${NC}"
            ;;
        *)
            echo -e "${YELLOW}⏸️  Pausando en $script_name${NC}"
            echo -e "${CYAN}Puedes ejecutarlo manualmente cuando estés listo: $script_path${NC}"
            ;;
    esac
}

# Función para verificar progreso
check_progress_step() {
    echo -e "\n${CYAN}🔍 ¿Quieres verificar tu progreso actual?${NC}"
    echo "1. Sí, mostrar progreso"
    echo "2. No, continuar"
    read -r progress_response
    
    if [[ "$progress_response" == "1" ]]; then
        ./scripts/check-progress.sh
        wait_for_user
    fi
}

# Bienvenida y configuración inicial
echo -e "\n${BLUE}🎯 OBJETIVO:${NC}"
echo "Vamos a implementar un sistema completo de pagos en Azure que incluye:"
echo "• 4 microservicios (API Gateway, Payment, User, Notification)"
echo "• Base de datos PostgreSQL"
echo "• Load balancer (Application Gateway)"
echo "• Monitoring completo"
echo "• Networking seguro"

echo -e "\n${YELLOW}📋 PRERREQUISITOS NECESARIOS:${NC}"
echo "• Azure CLI instalado"
echo "• Cuenta de Azure con permisos de Contributor"
echo "• 1-2 horas de tiempo"
echo "• Ganas de aprender 😊"

wait_for_user

# Paso 0: Debug Setup
echo -e "\n${PURPLE}🔍 PASO 0: VERIFICACIÓN INICIAL (OBLIGATORIO)${NC}"
echo -e "${CYAN}Antes de empezar, necesito verificar que tienes todo listo.${NC}"
echo -e "${YELLOW}Esto evitará errores durante la implementación.${NC}"

execute_with_confirmation "./scripts/00-debug-setup.sh" "Verificación de Prerequisites" "Verificar que Azure CLI está instalado, estás autenticado, y tienes todos los archivos necesarios." "2 minutos"

# Verificar si queremos continuar después del debug
echo -e "\n${GREEN}🎉 ¡Verificación completada!${NC}"
echo -e "${CYAN}¿Deseas continuar con la implementación completa? (y/N):${NC}"
read -r continue_response

if [[ ! "$continue_response" =~ ^[Yy]$ ]]; then
    echo -e "\n${YELLOW}👋 No hay problema. Puedes volver cuando estés listo.${NC}"
    echo -e "${CYAN}Para continuar después, ejecuta: ./scripts/wizard.sh${NC}"
    exit 0
fi

# Mostrar el plan completo
echo -e "\n${BLUE}📋 PLAN DE IMPLEMENTACIÓN:${NC}"
echo "1. 🏗️  Setup Environment (2 min)"
echo "2. 🌐 Networking (5 min)"
echo "3. 💾 Database (8 min)"
echo "4. 📦 Container Environment (6 min)"
echo "5. 📊 Monitoring (4 min)"
echo "6. 🚀 Applications (7 min)"
echo "7. ⚖️  Application Gateway (10 min)"
echo ""
echo -e "${CYAN}⏱️  Tiempo total estimado: ~45 minutos${NC}"

wait_for_user

# Paso 1: Setup Environment
execute_with_confirmation "./scripts/01-setup-environment.sh" "Setup Environment" "Crear el Resource Group que contendrá todos nuestros recursos y verificar configuración básica." "2 minutos"

check_progress_step

# Paso 2: Networking
execute_with_confirmation "./scripts/02-create-networking.sh" "Crear Networking" "Crear Virtual Network con subnets seguras para nuestros microservicios y Application Gateway." "5 minutos"

check_progress_step

# Paso 3: Database
execute_with_confirmation "./scripts/03-create-database.sh" "Crear Base de Datos" "Desplegar PostgreSQL Flexible Server con configuración de seguridad y firewall." "8 minutos"

check_progress_step

# Paso 4: Container Environment
execute_with_confirmation "./scripts/04-create-container-env.sh" "Container Apps Environment" "Crear el entorno donde se ejecutarán nuestros microservicios containerizados." "6 minutos"

check_progress_step

# Paso 5: Monitoring
execute_with_confirmation "./scripts/05-create-monitoring.sh" "Monitoring y Observabilidad" "Configurar Log Analytics y Application Insights para monitorear nuestro sistema." "4 minutos"

check_progress_step

# Paso 6: Applications
execute_with_confirmation "./scripts/06-deploy-applications.sh" "Desplegar Aplicaciones" "Desplegar los 4 microservicios: API Gateway, Payment API, User API, y Notification Service." "7 minutos"

check_progress_step

# Paso 7: Application Gateway
execute_with_confirmation "./scripts/07-create-app-gateway.sh" "Application Gateway" "Crear load balancer de capa 7 con SSL termination y routing inteligente." "10 minutos"

# Verificación final
echo -e "\n${PURPLE}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║                                                                                      ║${NC}"
echo -e "${PURPLE}║                             🎉 ¡IMPLEMENTACIÓN COMPLETA!                            ║${NC}"
echo -e "${PURPLE}║                                                                                      ║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}🎯 ¡Felicitaciones! Has completado la implementación del sistema de pagos.${NC}"

# Mostrar progreso final
echo -e "\n${CYAN}📊 Veamos tu progreso final:${NC}"
./scripts/check-progress.sh

echo -e "\n${BLUE}🎓 PRÓXIMOS PASOS RECOMENDADOS:${NC}"
echo "1. 🧪 Prueba las URLs de tus aplicaciones"
echo "2. 📊 Explora los dashboards de monitoring en Azure Portal"
echo "3. 🔧 Usa ./scripts/98-troubleshoot.sh para explorar herramientas de debugging"
echo "4. 📚 Lee la guía completa en docs/GUIA-CLI-PASO-A-PASO.md"
echo "5. 🧹 Cuando termines, limpia recursos con ./scripts/99-cleanup.sh"

echo -e "\n${YELLOW}💡 CONSEJOS PARA CONTINUAR APRENDIENDO:${NC}"
echo "• Modifica las aplicaciones y vuelve a desplegar"
echo "• Experimenta con diferentes configuraciones"
echo "• Compara este enfoque CLI con Terraform/BICEP/ARM"
echo "• Practica troubleshooting con errores intencionales"

echo -e "\n${GREEN}🏆 ¡Has dado un gran paso en tu carrera como Azure Engineer!${NC}"
echo -e "${CYAN}Dominar Azure CLI te abre puertas para automation, debugging y DevOps.${NC}"

echo -e "\n${PURPLE}Gracias por usar el wizard. ¡Sigue aprendiendo! 🚀${NC}"
