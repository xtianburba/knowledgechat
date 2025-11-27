#!/bin/bash
# Script para verificar que todo está funcionando correctamente

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SUBDOMAIN="osac-knowledge-bot.perfumesclub-helping.com"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Verificando aplicación OSAC Knowledge Bot${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Verificar PM2
echo -e "${YELLOW}[1/4] Verificando servicios PM2...${NC}"
if pm2 list | grep -q "osac-backend.*online"; then
    echo -e "${GREEN}✓ Backend está corriendo${NC}"
else
    echo -e "${RED}✗ Backend NO está corriendo${NC}"
fi

if pm2 list | grep -q "osac-frontend.*online"; then
    echo -e "${GREEN}✓ Frontend está corriendo${NC}"
else
    echo -e "${RED}✗ Frontend NO está corriendo${NC}"
fi
echo ""

# Verificar Apache
echo -e "${YELLOW}[2/4] Verificando Apache...${NC}"
if systemctl is-active --quiet apache2; then
    echo -e "${GREEN}✓ Apache está corriendo${NC}"
else
    echo -e "${RED}✗ Apache NO está corriendo${NC}"
fi

if apache2ctl -S 2>/dev/null | grep -q "$SUBDOMAIN"; then
    echo -e "${GREEN}✓ Configuración de subdominio encontrada${NC}"
else
    echo -e "${YELLOW}⚠ Configuración de subdominio no encontrada${NC}"
fi
echo ""

# Verificar backend
echo -e "${YELLOW}[3/4] Verificando backend API...${NC}"
if curl -s http://localhost:8001/api/health | grep -q "ok"; then
    echo -e "${GREEN}✓ Backend responde en localhost:8001${NC}"
else
    echo -e "${RED}✗ Backend NO responde en localhost:8001${NC}"
fi

if curl -s http://$SUBDOMAIN/api/health 2>/dev/null | grep -q "ok"; then
    echo -e "${GREEN}✓ Backend accesible desde subdominio${NC}"
else
    echo -e "${YELLOW}⚠ Backend no accesible desde subdominio (puede ser normal si Apache no está configurado)${NC}"
fi
echo ""

# Verificar frontend
echo -e "${YELLOW}[4/4] Verificando frontend...${NC}"
if curl -s http://localhost:3001 | grep -q "html\|DOCTYPE"; then
    echo -e "${GREEN}✓ Frontend responde en localhost:3001${NC}"
else
    echo -e "${RED}✗ Frontend NO responde en localhost:3001${NC}"
fi

if curl -s http://$SUBDOMAIN 2>/dev/null | grep -q "html\|DOCTYPE"; then
    echo -e "${GREEN}✓ Frontend accesible desde subdominio${NC}"
else
    echo -e "${YELLOW}⚠ Frontend no accesible desde subdominio${NC}"
    echo "   Verifica la configuración de Apache"
fi
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo "Resumen:"
echo "  - Backend local: http://localhost:8001/api/health"
echo "  - Frontend local: http://localhost:3001"
echo "  - Aplicación pública: http://$SUBDOMAIN"
echo ""
echo "Para ver logs:"
echo "  pm2 logs osac-backend"
echo "  pm2 logs osac-frontend"
echo "  tail -f /var/log/apache2/osac-knowledge-bot-error.log"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"

