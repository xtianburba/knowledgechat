#!/bin/bash
# Script completo para configurar Apache con subdominio y actualizar CORS

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SUBDOMAIN="osac-knowledge-bot.perfumesclub-helping.com"
PROJECT_DIR="/opt/osac-knowledge-bot"
ENV_FILE="$PROJECT_DIR/backend/.env"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Configurando Apache con subdominio: ${SUBDOMAIN}${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
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

# Paso 1: Habilitar módulos de Apache
echo -e "${YELLOW}[1/5] Habilitando módulos de Apache...${NC}"
a2enmod proxy 2>/dev/null || echo "  ✓ Módulo proxy ya habilitado"
a2enmod proxy_http 2>/dev/null || echo "  ✓ Módulo proxy_http ya habilitado"
a2enmod headers 2>/dev/null || echo "  ✓ Módulo headers ya habilitado"
a2enmod rewrite 2>/dev/null || echo "  ✓ Módulo rewrite ya habilitado"
echo -e "${GREEN}✓ Módulos habilitados${NC}"
echo ""

# Paso 2: Crear configuración de Apache
echo -e "${YELLOW}[2/5] Creando configuración de Apache...${NC}"
CONFIG_FILE="/etc/apache2/sites-available/osac-knowledge-bot.conf"

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

# Paso 3: Habilitar sitio
echo -e "${YELLOW}[3/5] Habilitando sitio en Apache...${NC}"
a2ensite osac-knowledge-bot.conf 2>/dev/null || echo "  ✓ Sitio ya habilitado"
echo -e "${GREEN}✓ Sitio habilitado${NC}"
echo ""

# Paso 4: Verificar y recargar Apache
echo -e "${YELLOW}[4/5] Verificando configuración de Apache...${NC}"
if apache2ctl configtest; then
    echo -e "${GREEN}✓ Configuración válida${NC}"
    echo ""
    echo -e "${YELLOW}Recargando Apache...${NC}"
    systemctl reload apache2
    echo -e "${GREEN}✓ Apache recargado${NC}"
else
    echo -e "${RED}✗ Error en la configuración de Apache${NC}"
    exit 1
fi
echo ""

# Paso 5: Actualizar CORS en .env
echo -e "${YELLOW}[5/5] Actualizando CORS_ORIGINS en .env...${NC}"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}⚠️  El archivo .env no existe. Créalo primero ejecutando:${NC}"
    echo "   cd $PROJECT_DIR && ./CREAR_ENV.sh"
    echo ""
else
    # Actualizar CORS_ORIGINS
    if grep -q "^CORS_ORIGINS=" "$ENV_FILE"; then
        sed -i "s|^CORS_ORIGINS=.*|CORS_ORIGINS=http://${SUBDOMAIN},http://82.223.20.111,http://localhost:3000,http://localhost:8000|" "$ENV_FILE"
        echo -e "${GREEN}✓ CORS_ORIGINS actualizado${NC}"
        echo ""
        echo "  Nuevo valor:"
        grep "^CORS_ORIGINS=" "$ENV_FILE" | sed 's/^/  /'
    else
        echo "  Añadiendo CORS_ORIGINS al .env..."
        echo "CORS_ORIGINS=http://${SUBDOMAIN},http://82.223.20.111,http://localhost:3000,http://localhost:8000" >> "$ENV_FILE"
        echo -e "${GREEN}✓ CORS_ORIGINS añadido${NC}"
    fi
    echo ""
    echo -e "${YELLOW}Reiniciando backend para aplicar cambios...${NC}"
    pm2 restart osac-backend || echo "  ⚠️  Backend no está corriendo con PM2"
    echo -e "${GREEN}✓ Backend reiniciado${NC}"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Configuración completada exitosamente!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "La aplicación estará disponible en:"
echo -e "  ${GREEN}http://${SUBDOMAIN}/${NC}"
echo "  http://82.223.20.111"
echo ""
echo "Para verificar:"
echo "  curl http://${SUBDOMAIN}/api/health"
echo ""
echo "Para ver logs:"
echo "  tail -f /var/log/apache2/osac-knowledge-bot-error.log"
echo "  tail -f /var/log/apache2/osac-knowledge-bot-access.log"
echo ""

