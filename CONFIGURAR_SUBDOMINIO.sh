#!/bin/bash
# Script para configurar Apache con el subdominio osac-knowledge-bot.perfumesclub-helping.com

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SUBDOMAIN="osac-knowledge-bot.perfumesclub-helping.com"

echo -e "${YELLOW}Configurando Apache para el subdominio: ${SUBDOMAIN}${NC}"
echo ""

# Verificar que estamos como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Por favor, ejecuta este script como root o con sudo${NC}"
    exit 1
fi

# Verificar que Apache está instalado
if ! command -v apache2 &> /dev/null; then
    echo -e "${RED}Apache no está instalado. Por favor, instálalo primero.${NC}"
    exit 1
fi

echo -e "${YELLOW}Paso 1: Habilitando módulos necesarios de Apache...${NC}"

# Habilitar módulos necesarios
a2enmod proxy 2>/dev/null || echo "Módulo proxy ya habilitado"
a2enmod proxy_http 2>/dev/null || echo "Módulo proxy_http ya habilitado"
a2enmod headers 2>/dev/null || echo "Módulo headers ya habilitado"
a2enmod rewrite 2>/dev/null || echo "Módulo rewrite ya habilitado"

echo -e "${GREEN}✓ Módulos habilitados${NC}"
echo ""

echo -e "${YELLOW}Paso 2: Creando configuración de sitio...${NC}"

# Crear archivo de configuración
CONFIG_FILE="/etc/apache2/sites-available/osac-knowledge-bot.conf"
PROJECT_DIR="/opt/osac-knowledge-bot"

if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}Error: No se encontró el directorio del proyecto en $PROJECT_DIR${NC}"
    exit 1
fi

# Crear configuración desde el repositorio
cat > "$CONFIG_FILE" << EOF
# Configuración Apache para OSAC Knowledge Bot
# Generado automáticamente

<VirtualHost *:80>
    ServerName ${SUBDOMAIN}
    ServerAlias 82.223.20.111
    
    # Logs específicos para esta aplicación
    ErrorLog \${APACHE_LOG_DIR}/osac-knowledge-bot-error.log
    CustomLog \${APACHE_LOG_DIR}/osac-knowledge-bot-access.log combined
    
    # Activar proxy
    ProxyPreserveHost On
    
    # Frontend (React) - Servir archivos estáticos compilados o dev server
    ProxyPass / http://localhost:3001/
    ProxyPassReverse / http://localhost:3001/
    
    # Headers para WebSocket (si se necesita)
    ProxyPassReverse /socket.io/ http://localhost:3001/socket.io/
    
    # Backend API
    ProxyPass /api http://localhost:8001/api
    ProxyPassReverse /api http://localhost:8001/api
    
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

echo -e "${GREEN}✓ Configuración creada en $CONFIG_FILE${NC}"
echo ""

echo -e "${YELLOW}Paso 3: Habilitando el sitio...${NC}"

a2ensite osac-knowledge-bot.conf 2>/dev/null || echo "Sitio ya habilitado"

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
echo -e "  - ${GREEN}http://${SUBDOMAIN}${NC}"
echo "  - http://82.223.20.111"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "  1. Asegúrate de que el DNS apunte ${SUBDOMAIN} a 82.223.20.111"
echo "  2. Actualiza CORS_ORIGINS en backend/.env con:"
echo "     CORS_ORIGINS=http://${SUBDOMAIN},http://82.223.20.111"
echo ""
echo "Para verificar los logs:"
echo "  tail -f /var/log/apache2/osac-knowledge-bot-error.log"
echo "  tail -f /var/log/apache2/osac-knowledge-bot-access.log"
echo ""

