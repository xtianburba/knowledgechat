#!/bin/bash
# Script para verificar y arreglar completamente la configuración de Apache

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SUBDOMAIN="osac-knowledge-bot.perfumesclub-helping.com"
CONFIG_FILE="/etc/apache2/sites-available/osac-knowledge-bot.conf"
SSL_CONFIG_FILE="/etc/apache2/sites-available/osac-knowledge-bot-le-ssl.conf"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Verificación y Corrección Completa de Apache${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Por favor, ejecuta como root: sudo $0${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/5] Verificando configuraciones existentes...${NC}"

# Verificar si existe configuración SSL
HAS_SSL=false
if [ -f "$SSL_CONFIG_FILE" ]; then
    HAS_SSL=true
    echo -e "${GREEN}✓ Configuración SSL encontrada${NC}"
fi

if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}✓ Configuración HTTP encontrada${NC}"
fi

echo ""

echo -e "${YELLOW}[2/5] Mostrando configuración actual de ProxyPass...${NC}"
if [ -f "$CONFIG_FILE" ]; then
    echo ""
    echo "HTTP Config:"
    grep -A 2 "ProxyPass" "$CONFIG_FILE" || echo "No se encontraron ProxyPass"
fi

if [ "$HAS_SSL" = true ]; then
    echo ""
    echo "HTTPS Config:"
    grep -A 2 "ProxyPass" "$SSL_CONFIG_FILE" || echo "No se encontraron ProxyPass"
fi
echo ""

echo -e "${YELLOW}[3/5] Actualizando configuración HTTP...${NC}"

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
    <Location /api>
        ProxyPass http://localhost:8001/api
        ProxyPassReverse http://localhost:8001/api
        Order allow,deny
        Allow from all
    </Location>
    
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

echo -e "${GREEN}✓ Configuración HTTP actualizada${NC}"
echo ""

if [ "$HAS_SSL" = true ]; then
    echo -e "${YELLOW}[4/5] Actualizando configuración HTTPS...${NC}"
    
    # Leer la configuración SSL existente y actualizar solo las partes de proxy
    cat > "$SSL_CONFIG_FILE" << 'SSL_EOF'
# Configuración SSL para OSAC Knowledge Bot
# Esta configuración se actualizará automáticamente por certbot
SSL_EOF
    
    # Buscar las líneas del certificado SSL y ServerName
    SSL_CERT_LINES=$(grep -E "SSLCertificateFile|SSLCertificateKeyFile|SSLCertificateChainFile" "$SSL_CONFIG_FILE" 2>/dev/null || echo "")
    SERVER_NAME=$(grep "ServerName" "$SSL_CONFIG_FILE" 2>/dev/null | head -1 || echo "ServerName ${SUBDOMAIN}")
    
    # Reconstruir configuración SSL completa
    cat >> "$SSL_CONFIG_FILE" << EOF

<VirtualHost *:443>
    ${SERVER_NAME}
    ServerAlias 82.223.20.111
    
    # Logs específicos para esta aplicación
    ErrorLog \${APACHE_LOG_DIR}/osac-knowledge-bot-error.log
    CustomLog \${APACHE_LOG_DIR}/osac-knowledge-bot-access.log combined
    
    # Configuración SSL (certbot añadirá las líneas SSLCertificate* aquí)
    
    # Activar proxy
    ProxyPreserveHost On
    
    # IMPORTANTE: Las reglas más específicas deben ir PRIMERO
    # Backend API - DEBE ir antes que la regla general "/"
    <Location /api>
        ProxyPass http://localhost:8001/api
        ProxyPassReverse http://localhost:8001/api
        Order allow,deny
        Allow from all
    </Location>
    
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

    # Si hay líneas de certificado SSL, añadirlas antes del cierre del VirtualHost
    if [ ! -z "$SSL_CERT_LINES" ]; then
        # Insertar las líneas SSL antes de </VirtualHost>
        sed -i '/<\/VirtualHost>/i '"$SSL_CERT_LINES" "$SSL_CONFIG_FILE"
    fi
    
    echo -e "${GREEN}✓ Configuración HTTPS actualizada${NC}"
else
    echo -e "${YELLOW}[4/5] No hay configuración SSL, omitiendo...${NC}"
fi
echo ""

echo -e "${YELLOW}[5/5] Verificando y recargando Apache...${NC}"
if apache2ctl configtest; then
    echo -e "${GREEN}✓ Configuración válida${NC}"
    systemctl reload apache2
    echo -e "${GREEN}✓ Apache recargado${NC}"
else
    echo -e "${RED}✗ Error en la configuración${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Configuración de Apache actualizada completamente!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Prueba las siguientes URLs:"
echo "  Backend: https://${SUBDOMAIN}/api/health"
echo "  Frontend: https://${SUBDOMAIN}/"
echo ""
echo "Si el problema persiste, verifica los logs:"
echo "  tail -f /var/log/apache2/osac-knowledge-bot-error.log"
echo ""

