#!/bin/bash
# Script para configurar SSL/HTTPS con Let's Encrypt para el subdominio

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SUBDOMAIN="osac-knowledge-bot.perfumesclub-helping.com"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Configurando SSL/HTTPS con Let's Encrypt${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar que estamos como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Por favor, ejecuta este script como root o con sudo${NC}"
    exit 1
fi

# Verificar que Apache está instalado
if ! command -v apache2 &> /dev/null; then
    echo -e "${RED}Apache no está instalado.${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/5] Instalando Certbot...${NC}"

# Instalar certbot si no está instalado
if ! command -v certbot &> /dev/null; then
    apt-get update
    apt-get install -y certbot python3-certbot-apache
    echo -e "${GREEN}✓ Certbot instalado${NC}"
else
    echo -e "${GREEN}✓ Certbot ya está instalado${NC}"
fi
echo ""

echo -e "${YELLOW}[2/5] Verificando configuración de Apache...${NC}"

# Verificar que el sitio está habilitado
if [ ! -f "/etc/apache2/sites-enabled/osac-knowledge-bot.conf" ]; then
    echo -e "${RED}Error: El sitio osac-knowledge-bot no está habilitado${NC}"
    echo "Ejecuta primero: a2ensite osac-knowledge-bot.conf"
    exit 1
fi

echo -e "${GREEN}✓ Sitio habilitado${NC}"
echo ""

echo -e "${YELLOW}[3/5] Verificando DNS...${NC}"

# Verificar que el DNS apunta correctamente
DNS_IP=$(dig +short $SUBDOMAIN | tail -1)
SERVER_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || echo "")

if [ -z "$SERVER_IP" ]; then
    echo -e "${YELLOW}⚠ No se pudo obtener la IP del servidor automáticamente${NC}"
    echo "Verifica manualmente que $SUBDOMAIN apunta a 82.223.20.111"
else
    if [ "$DNS_IP" = "$SERVER_IP" ] || [ "$DNS_IP" = "82.223.20.111" ]; then
        echo -e "${GREEN}✓ DNS configurado correctamente ($SUBDOMAIN -> $DNS_IP)${NC}"
    else
        echo -e "${YELLOW}⚠ DNS puede no estar configurado correctamente${NC}"
        echo "  $SUBDOMAIN apunta a: $DNS_IP"
        echo "  IP del servidor: $SERVER_IP"
        echo ""
        echo "Asegúrate de que $SUBDOMAIN apunta a 82.223.20.111 antes de continuar"
    fi
fi
echo ""

echo -e "${YELLOW}[4/5] Verificando que Apache escucha en puerto 80...${NC}"

if netstat -tlnp 2>/dev/null | grep -q ":80 " || ss -tlnp 2>/dev/null | grep -q ":80 "; then
    echo -e "${GREEN}✓ Apache está escuchando en puerto 80${NC}"
else
    echo -e "${RED}✗ Apache no está escuchando en puerto 80${NC}"
    echo "Verifica la configuración de Apache"
    exit 1
fi
echo ""

echo -e "${YELLOW}[5/5] Obteniendo certificado SSL con Certbot...${NC}"
echo ""
echo -e "${YELLOW}⚠ IMPORTANTE:${NC}"
echo "  1. El subdominio debe estar apuntando a este servidor"
echo "  2. El puerto 80 debe estar abierto y accesible desde internet"
echo "  3. Certbot necesitará acceso HTTP para verificar el dominio"
echo ""
echo -e "${YELLOW}Presiona Enter para continuar o Ctrl+C para cancelar...${NC}"
read

# Ejecutar certbot
echo "Ejecutando certbot..."
certbot --apache -d "$SUBDOMAIN" --non-interactive --agree-tos --email admin@perfumesclub.com || {
    echo ""
    echo -e "${YELLOW}Certbot requiere información interactiva. Ejecutando en modo interactivo...${NC}"
    echo ""
    certbot --apache -d "$SUBDOMAIN"
}

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ SSL configurado!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "La aplicación ahora está disponible en:"
echo -e "  ${GREEN}https://$SUBDOMAIN${NC}"
echo ""
echo "Certbot configurará automáticamente:"
echo "  - Redirección HTTP -> HTTPS"
echo "  - Renovación automática del certificado"
echo ""
echo "Para verificar el certificado:"
echo "  certbot certificates"
echo ""
echo "Para renovar manualmente:"
echo "  certbot renew"
echo ""

