#!/bin/bash
# Script para arreglar el esquema de ChromaDB

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BACKEND_DIR="/opt/osac-knowledge-bot/backend"
CHROMA_DIR="$BACKEND_DIR/chroma_db"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Arreglando Esquema de ChromaDB${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Por favor, ejecuta como root: sudo $0${NC}"
    exit 1
fi

cd "$BACKEND_DIR"

# Detener el backend
echo -e "${YELLOW}[1/5] Deteniendo backend...${NC}"
pm2 stop osac-backend 2>/dev/null || true
sleep 2
echo -e "${GREEN}✓ Backend detenido${NC}"
echo ""

# Hacer backup de ChromaDB
echo -e "${YELLOW}[2/5] Creando backup de ChromaDB...${NC}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKEND_DIR/chroma_db_backup_$TIMESTAMP"

if [ -d "$CHROMA_DIR" ]; then
    cp -r "$CHROMA_DIR" "$BACKUP_DIR"
    echo -e "${GREEN}✓ Backup creado en: $BACKUP_DIR${NC}"
else
    echo -e "${YELLOW}⚠ No se encontró ChromaDB para hacer backup${NC}"
fi
echo ""

# Recrear ChromaDB (es la solución más segura para esquema corrupto)
echo -e "${YELLOW}[3/5] Recreando ChromaDB con esquema correcto...${NC}"

# Eliminar ChromaDB corrupta
if [ -d "$CHROMA_DIR" ]; then
    rm -rf "$CHROMA_DIR"
    echo "  ChromaDB eliminada"
fi

# Crear nueva ChromaDB vacía (se inicializará cuando se reinicie el backend)
mkdir -p "$CHROMA_DIR"
echo -e "${GREEN}✓ ChromaDB recreada${NC}"
echo ""
echo -e "${YELLOW}⚠ IMPORTANTE: Los vectores se han eliminado.${NC}"
echo -e "${YELLOW}   Necesitas reimportar el conocimiento desde Zendesk.${NC}"
echo ""

# Reiniciar backend
echo -e "${YELLOW}[4/5] Reiniciando backend...${NC}"
pm2 start ecosystem.config.js --only osac-backend
pm2 save
sleep 3
echo -e "${GREEN}✓ Backend reiniciado${NC}"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ ChromaDB recreada!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Backup guardado en: $BACKUP_DIR"
echo ""
echo "PRÓXIMOS PASOS:"
echo ""
echo "1. Ve a la web: https://osac-knowledge-bot.perfumesclub-helping.com/"
echo "2. Inicia sesión como admin/supervisor"
echo "3. Ve a 'Gestionar Conocimiento'"
echo "4. Haz clic en 'Sincronizar con Zendesk' para reimportar todo el conocimiento"
echo ""
echo "O espera a que se ejecute la sincronización automática (si está configurada)"
echo ""
