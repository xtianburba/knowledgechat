#!/bin/bash
# Script para arreglar el orden de las reglas ProxyPass en Apache

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SUBDOMAIN="osac-knowledge-bot.perfumesclub-helping.com"
CONFIG_FILE="/etc/apache2/sites-available/osac-knowledge-bot.conf"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Arreglando orden de ProxyPass en Apache${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Por favor, ejecuta como root: sudo $0${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/3] Creando backup de la configuración actual...${NC}"
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✓ Backup creado${NC}"
fi
echo ""

echo -e "${YELLOW}[2/3] Actualizando configuración de Apache...${NC}"

cat > "$CONFIG_FILE" << EOF
# Configuración Apache para OSAC Knowledge Bot
# IMPORTANTE: Las reglas más específicas (/api) deben ir ANTES de las generales (/)

<VirtualHost *:80>
    ServerName ${SUBDOMAIN}
    ServerAlias 82.223.20.111
    
    # Logs específicos para esta aplicación
    ErrorLog \${APACHE_LOG_DIR}/osac-knowledge-bot-error.log
    CustomLog \${APACHE_LOG_DIR}/osac-knowledge-bot-access.log combined
    
    # Activar proxy
    ProxyPreserveHost On
    
    # IMPORTANTE: Las reglas más específicas deben ir PRIMERO
    # Backend API - DEBE ir antes que la regla general "/"
    ProxyPass /api http://localhost:8001/api
    ProxyPassReverse /api http://localhost:8001/api
    
    # Frontend (React) - Esta regla captura todo lo que no sea /api
    ProxyPass / http://localhost:3002/
    ProxyPassReverse / http://localhost:3002/
    
    # Headers para CORS
    Header always set Access-Control-Allow-Origin "*"
    Header always set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
    Header always set Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With"
    
    # Para peticiones OPTIONS (preflight)
    <LocationMatch "^/api">
        RewriteEngine On
        RewriteCond %{REQUEST_METHOD} OPTIONS
        RewriteRule ^(.*)$ $1 [R=200,L]
    </LocationMatch>
    
    # Timeout para requests largos (chat con IA)
    ProxyTimeout 300
    Timeout 300
</VirtualHost>
EOF

echo -e "${GREEN}✓ Configuración actualizada${NC}"
echo ""

echo -e "${YELLOW}[3/3] Verificando y recargando Apache...${NC}"
if apache2ctl configtest; then
    echo -e "${GREEN}✓ Configuración válida${NC}"
    systemctl reload apache2
    echo -e "${GREEN}✓ Apache recargado${NC}"
else
    echo -e "${RED}✗ Error en la configuración. Restaurando backup...${NC}"
    if [ -f "$CONFIG_FILE.backup"* ]; then
        cp "$CONFIG_FILE.backup"* "$CONFIG_FILE"
        systemctl reload apache2
    fi
    exit 1
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Configuración de Apache arreglada!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "El orden correcto ahora es:"
echo "  1. /api → backend (puerto 8001)"
echo "  2. / → frontend (puerto 3002)"
echo ""
echo "Prueba accediendo a:"
echo "  - https://${SUBDOMAIN}/api/health"
echo "  - https://${SUBDOMAIN}/"
echo ""

