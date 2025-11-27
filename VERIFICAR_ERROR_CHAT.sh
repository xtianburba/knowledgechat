#!/bin/bash
# Script para verificar y diagnosticar errores en el chat

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="/opt/osac-knowledge-bot"
BACKEND_DIR="$PROJECT_DIR/backend"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Verificando Configuración del Chat${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

cd "$BACKEND_DIR"

# Verificar archivo .env
echo -e "${YELLOW}[1/5] Verificando archivo .env...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${RED}❌ No se encontró el archivo .env${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Archivo .env existe${NC}"

# Verificar GEMINI_API_KEY
echo -e "${YELLOW}[2/5] Verificando GEMINI_API_KEY...${NC}"
GEMINI_KEY=$(grep "^GEMINI_API_KEY=" .env | cut -d'=' -f2- | tr -d '"' | tr -d "'")
if [ -z "$GEMINI_KEY" ] || [ "$GEMINI_KEY" = "" ]; then
    echo -e "${RED}❌ GEMINI_API_KEY no está configurada o está vacía${NC}"
    echo ""
    echo "Solución: Añade la clave API en el archivo .env:"
    echo "  GEMINI_API_KEY=tu_clave_api_aqui"
    exit 1
fi
echo -e "${GREEN}✓ GEMINI_API_KEY está configurada${NC}"

# Verificar ChromaDB
echo -e "${YELLOW}[3/5] Verificando ChromaDB...${NC}"
if [ -d "chroma_db" ]; then
    echo -e "${GREEN}✓ Directorio chroma_db existe${NC}"
    if [ -f "chroma_db/chroma.sqlite3" ]; then
        echo -e "${GREEN}✓ Base de datos ChromaDB existe${NC}"
    else
        echo -e "${YELLOW}⚠ Base de datos ChromaDB no existe (puede estar vacía)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Directorio chroma_db no existe (se creará automáticamente)${NC}"
fi

# Verificar logs del backend
echo -e "${YELLOW}[4/5] Revisando logs del backend...${NC}"
if [ -d "logs" ]; then
    if [ -f "logs/backend-error.log" ]; then
        echo "Últimas líneas de error:"
        tail -20 logs/backend-error.log | head -10
    fi
fi

# Verificar que el backend esté corriendo
echo -e "${YELLOW}[5/5] Verificando estado del backend...${NC}"
if pm2 list | grep -q "osac-backend.*online"; then
    echo -e "${GREEN}✓ Backend está corriendo${NC}"
    echo ""
    echo "Para ver los logs en tiempo real:"
    echo "  pm2 logs osac-backend --lines 50"
else
    echo -e "${RED}❌ Backend no está corriendo${NC}"
    echo ""
    echo "Para iniciar el backend:"
    echo "  pm2 start ecosystem.config.js --only osac-backend"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Verificación completada${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Si el problema persiste, revisa los logs del backend:"
echo "  pm2 logs osac-backend --lines 100"
echo ""

