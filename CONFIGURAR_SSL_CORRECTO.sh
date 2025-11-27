#!/bin/bash
# Script para configurar SSL correctamente para el subdominio

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SUBDOMAIN="osac-knowledge-bot.perfumesclub-helping.com"
EMAIL="admin@perfumesclub.com"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Configurando SSL para ${SUBDOMAIN}${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Por favor, ejecuta como root: sudo $0${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/6] Verificando que Apache está corriendo...${NC}"
if ! systemctl is-active --quiet apache2; then
    echo -e "${RED}Apache no está corriendo. Iniciando...${NC}"
    systemctl start apache2
fi
echo -e "${GREEN}✓ Apache está corriendo${NC}"
echo ""

echo -e "${YELLOW}[2/6] Verificando que el sitio HTTP está funcionando...${NC}"
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://${SUBDOMAIN}/ || echo "000")
if [ "$HTTP_RESPONSE" != "200" ] && [ "$HTTP_RESPONSE" != "301" ] && [ "$HTTP_RESPONSE" != "302" ]; then
    echo -e "${YELLOW}⚠ La respuesta HTTP es $HTTP_RESPONSE (puede ser normal si no hay SSL)${NC}"
else
    echo -e "${GREEN}✓ El sitio HTTP responde${NC}"
fi
echo ""

echo -e "${YELLOW}[3/6] Instalando Certbot...${NC}"
if ! command -v certbot &> /dev/null; then
    apt-get update
    apt-get install -y certbot python3-certbot-apache
    echo -e "${GREEN}✓ Certbot instalado${NC}"
else
    echo -e "${GREEN}✓ Certbot ya está instalado${NC}"
fi
echo ""

echo -e "${YELLOW}[4/6] Verificando DNS...${NC}"
DNS_IP=$(dig +short ${SUBDOMAIN} | tail -1 || echo "")
if [ -z "$DNS_IP" ]; then
    echo -e "${RED}⚠ No se pudo resolver el DNS para ${SUBDOMAIN}${NC}"
    echo "Asegúrate de que el DNS apunta correctamente antes de continuar"
else
    echo -e "${GREEN}✓ DNS resuelve a: $DNS_IP${NC}"
    if [ "$DNS_IP" != "82.223.20.111" ]; then
        echo -e "${YELLOW}⚠ La IP del DNS ($DNS_IP) no coincide con la del servidor (82.223.20.111)${NC}"
        echo "Esto puede causar problemas con la verificación SSL"
    fi
fi
echo ""

echo -e "${YELLOW}[5/6] Obteniendo certificado SSL con Certbot...${NC}"
echo ""
echo -e "${YELLOW}⚠ IMPORTANTE:${NC}"
echo "  - El dominio debe apuntar a este servidor"
echo "  - El puerto 80 debe estar accesible desde internet"
echo "  - Certbot usará HTTP para verificar el dominio"
echo ""
read -p "¿Continuar con la obtención del certificado? [S/n]: " -r response
if [[ "$response" =~ ^[Nn]$ ]]; then
    echo "Cancelado."
    exit 0
fi

echo ""
echo "Ejecutando certbot..."
certbot --apache \
    -d "${SUBDOMAIN}" \
    --non-interactive \
    --agree-tos \
    --email "${EMAIL}" \
    --redirect \
    --cert-name osac-knowledge-bot || {
    
    echo ""
    echo -e "${YELLOW}Certbot falló en modo no-interactivo. Ejecutando modo interactivo...${NC}"
    echo ""
    certbot --apache -d "${SUBDOMAIN}" --redirect
}

echo ""
echo -e "${GREEN}[6/6] Verificando certificado...${NC}"
if certbot certificates | grep -q "${SUBDOMAIN}"; then
    echo -e "${GREEN}✓ Certificado configurado correctamente${NC}"
else
    echo -e "${RED}⚠ El certificado no aparece en la lista${NC}"
fi
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ SSL configurado!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "El sitio ahora está disponible en:"
echo -e "  ${GREEN}https://${SUBDOMAIN}${NC}"
echo ""
echo "El certificado se renovará automáticamente."
echo ""
echo "Para verificar el certificado:"
echo "  certbot certificates"
echo ""

