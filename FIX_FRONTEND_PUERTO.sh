#!/bin/bash
# Script rápido para arreglar el puerto del frontend

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Arreglando configuración del frontend...${NC}"
echo ""

cd /opt/osac-knowledge-bot

# 1. Actualizar código
git pull

# 2. Detener frontend
echo "Deteniendo frontend..."
pm2 stop osac-frontend 2>/dev/null || true
pm2 delete osac-frontend 2>/dev/null || true

# 3. Verificar que serve está instalado
cd frontend
if [ ! -f "node_modules/.bin/serve" ]; then
    echo "Instalando serve..."
    npm install
fi

# 4. Verificar que build existe
if [ ! -d "build" ]; then
    echo "Compilando frontend..."
    npm run build
fi

# 5. Reiniciar con la nueva configuración
cd ..
pm2 start ecosystem.config.js --only osac-frontend --update-env

# 6. Esperar un poco y verificar
sleep 3

echo ""
echo -e "${GREEN}Verificando puerto...${NC}"
if curl -s http://localhost:3001 | grep -q "html\|DOCTYPE"; then
    echo -e "${GREEN}✓ Frontend funcionando en puerto 3001${NC}"
else
    echo -e "${YELLOW}⚠ Verifica los logs: pm2 logs osac-frontend${NC}"
fi

pm2 save

echo ""
pm2 status | grep osac-frontend

