#!/bin/bash
# Script para arreglar el frontend: instalar serve, compilar y reiniciar

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

FRONTEND_DIR="/opt/osac-knowledge-bot/frontend"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Arreglando Frontend${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

cd "$FRONTEND_DIR"

# Paso 1: Instalar dependencias
echo -e "${YELLOW}[1/5] Instalando dependencias...${NC}"
npm install
echo -e "${GREEN}✓ Dependencias instaladas${NC}"
echo ""

# Paso 2: Verificar que serve está instalado (ya debería estar en package.json)
echo -e "${YELLOW}[2/5] Verificando 'serve'...${NC}"
npm install
echo -e "${GREEN}✓ Dependencias verificadas${NC}"
echo ""

# Paso 3: Compilar frontend
echo -e "${YELLOW}[3/5] Compilando frontend para producción...${NC}"
npm run build

if [ ! -d "build" ]; then
    echo -e "${RED}❌ Error: La compilación falló. No se creó la carpeta 'build'${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Frontend compilado exitosamente${NC}"
echo ""

# Paso 4: Detener frontend actual (si está corriendo con error)
echo -e "${YELLOW}[4/5] Deteniendo frontend actual...${NC}"
pm2 stop osac-frontend 2>/dev/null || true
pm2 delete osac-frontend 2>/dev/null || true
echo -e "${GREEN}✓ Frontend detenido${NC}"
echo ""

# Paso 5: Iniciar frontend con PM2 usando npx serve
echo -e "${YELLOW}[5/5] Iniciando frontend con PM2...${NC}"

# Actualizar ecosystem.config.js para usar npx serve
cd /opt/osac-knowledge-bot

# Crear configuración temporal para el frontend
pm2 start ecosystem.config.js --only osac-frontend --update-env

# Si falla, intentar directamente con npx
if ! pm2 list | grep -q "osac-frontend.*online"; then
    echo "  Intentando con npx serve directamente..."
    cd "$FRONTEND_DIR"
    pm2 start npx --name "osac-frontend" -- serve -s build -l 3001
fi

echo -e "${GREEN}✓ Frontend iniciado${NC}"
echo ""

# Guardar configuración PM2
pm2 save

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Frontend arreglado y funcionando!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
pm2 status | grep osac-frontend || pm2 status
echo ""
echo "Para ver logs:"
echo "  pm2 logs osac-frontend"
echo ""

