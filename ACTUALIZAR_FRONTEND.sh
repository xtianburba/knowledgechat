#!/bin/bash
# Script para actualizar el frontend desde GitHub y recompilarlo

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="/opt/osac-knowledge-bot"
FRONTEND_DIR="$PROJECT_DIR/frontend"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Actualizando Frontend${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

cd "$PROJECT_DIR"

# Paso 1: Actualizar código desde GitHub
echo -e "${YELLOW}[1/3] Actualizando código desde GitHub...${NC}"
git stash 2>/dev/null || true
git pull
echo -e "${GREEN}✓ Código actualizado${NC}"
echo ""

# Paso 2: Instalar dependencias y compilar frontend
echo -e "${YELLOW}[2/3] Compilando frontend...${NC}"
cd "$FRONTEND_DIR"
npm install
npm run build

if [ ! -d "build" ]; then
    echo -e "${RED}❌ Error: La compilación falló${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Frontend compilado${NC}"
echo ""

# Paso 3: Reiniciar frontend con PM2
echo -e "${YELLOW}[3/3] Reiniciando frontend...${NC}"
pm2 restart osac-frontend || pm2 start ecosystem.config.js --only osac-frontend
pm2 save
echo -e "${GREEN}✓ Frontend reiniciado${NC}"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Frontend actualizado exitosamente!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Estado del frontend:"
pm2 status | grep osac-frontend || echo "  Verifica con: pm2 status"
echo ""

