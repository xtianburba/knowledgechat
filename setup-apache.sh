#!/bin/bash

# Script para configurar Apache como reverse proxy
# NO modifica configuraciones existentes de Apache

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Configurando Apache como reverse proxy para OSAC Knowledge Bot...${NC}"
echo ""

# Verificar que Apache está instalado
if ! command -v apache2 &> /dev/null; then
    echo -e "${RED}Apache no está instalado. Por favor, instálalo primero.${NC}"
    exit 1
fi

# Verificar que estamos como root o con sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Por favor, ejecuta este script como root o con sudo${NC}"
    exit 1
fi

echo -e "${YELLOW}Paso 1: Habilitando módulos necesarios de Apache...${NC}"

# Habilitar módulos necesarios (si no están ya habilitados)
a2enmod proxy 2>/dev/null || echo "Módulo proxy ya habilitado"
a2enmod proxy_http 2>/dev/null || echo "Módulo proxy_http ya habilitado"
a2enmod headers 2>/dev/null || echo "Módulo headers ya habilitado"
a2enmod rewrite 2>/dev/null || echo "Módulo rewrite ya habilitado"

echo -e "${GREEN}✓ Módulos habilitados${NC}"
echo ""

echo -e "${YELLOW}Paso 2: Creando configuración de sitio...${NC}"

# Crear archivo de configuración
CONFIG_FILE="/etc/apache2/sites-available/osac-knowledge-bot.conf"

if [ -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}⚠ El archivo de configuración ya existe: $CONFIG_FILE${NC}"
    read -p "¿Deseas sobrescribirlo? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelado. Usando configuración existente."
    else
        cp apache-config.conf "$CONFIG_FILE"
        echo -e "${GREEN}✓ Configuración actualizada${NC}"
    fi
else
    cp apache-config.conf "$CONFIG_FILE"
    echo -e "${GREEN}✓ Configuración creada en $CONFIG_FILE${NC}"
fi

echo ""

echo -e "${YELLOW}Paso 3: Habilitando el sitio...${NC}"

a2ensite osac-knowledge-bot.conf

echo -e "${GREEN}✓ Sitio habilitado${NC}"
echo ""

echo -e "${YELLOW}Paso 4: Verificando configuración de Apache...${NC}"

if apache2ctl configtest; then
    echo -e "${GREEN}✓ Configuración válida${NC}"
    echo ""
    echo -e "${YELLOW}Paso 5: Recargando Apache...${NC}"
    systemctl reload apache2
    echo -e "${GREEN}✓ Apache recargado${NC}"
else
    echo -e "${RED}✗ Error en la configuración de Apache${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}=========================================="
echo "✓ Apache configurado exitosamente!"
echo "==========================================${NC}"
echo ""
echo "La aplicación estará disponible en:"
echo "  - http://osac-knowledge-bot.perfumesclub-helping.com"
echo "  - http://82.223.20.111"
echo ""
echo "⚠️  IMPORTANTE: Asegúrate de que el DNS apunte el subdominio a esta IP"
echo ""
echo "Para verificar los logs:"
echo "  tail -f /var/log/apache2/osac-knowledge-bot-error.log"
echo "  tail -f /var/log/apache2/osac-knowledge-bot-access.log"
echo ""

