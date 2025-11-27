#!/bin/bash
# Script para compilar el frontend y configurarlo para producción

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

FRONTEND_DIR="/opt/osac-knowledge-bot/frontend"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Compilando Frontend para Producción${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [ ! -d "$FRONTEND_DIR" ]; then
    echo -e "${RED}❌ Error: No se encontró el directorio del frontend${NC}"
    exit 1
fi

cd "$FRONTEND_DIR"

# Paso 1: Instalar dependencias
echo -e "${YELLOW}[1/4] Instalando dependencias de Node.js...${NC}"
npm install
echo -e "${GREEN}✓ Dependencias instaladas${NC}"
echo ""

# Paso 2: Instalar serve globalmente (si no está instalado)
echo -e "${YELLOW}[2/4] Verificando instalación de 'serve'...${NC}"
if ! command -v serve &> /dev/null; then
    echo "  Instalando 'serve' globalmente..."
    npm install -g serve
    echo -e "${GREEN}✓ 'serve' instalado${NC}"
else
    echo -e "${GREEN}✓ 'serve' ya está instalado${NC}"
fi
echo ""

# Paso 3: Compilar frontend
echo -e "${YELLOW}[3/4] Compilando frontend para producción...${NC}"
npm run build

if [ ! -d "build" ]; then
    echo -e "${RED}❌ Error: La compilación falló. No se creó la carpeta 'build'${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Frontend compilado exitosamente${NC}"
echo ""

# Paso 4: Reiniciar frontend con PM2
echo -e "${YELLOW}[4/4] Reiniciando frontend con PM2...${NC}"
pm2 restart osac-frontend || pm2 start ecosystem.config.js --only osac-frontend

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Frontend compilado y configurado!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Estado del frontend:"
pm2 status | grep osac-frontend || echo "  Verifica con: pm2 status"
echo ""
echo "Para ver logs del frontend:"
echo "  pm2 logs osac-frontend"
echo ""

