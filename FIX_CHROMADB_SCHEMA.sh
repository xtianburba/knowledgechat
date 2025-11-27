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

# Intentar reparar la base de datos
echo -e "${YELLOW}[3/5] Intentando reparar la base de datos...${NC}"
if [ -f "$CHROMA_DIR/chroma.sqlite3" ]; then
    echo "  Verificando integridad de la base de datos..."
    
    # Ejecutar comando SQLite para verificar
    python3 << 'PYTHON_SCRIPT'
import sqlite3
import sys

chroma_db_path = "/opt/osac-knowledge-bot/backend/chroma_db/chroma.sqlite3"

try:
    conn = sqlite3.connect(chroma_db_path)
    cursor = conn.cursor()
    
    # Verificar si existe la tabla collections y sus columnas
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='collections';")
    if cursor.fetchone():
        cursor.execute("PRAGMA table_info(collections);")
        columns = [row[1] for row in cursor.fetchall()]
        print(f"Columnas encontradas en 'collections': {columns}")
        
        # Intentar añadir la columna 'topic' si no existe
        if 'topic' not in columns:
            print("Intentando añadir columna 'topic'...")
            try:
                cursor.execute("ALTER TABLE collections ADD COLUMN topic TEXT;")
                conn.commit()
                print("✓ Columna 'topic' añadida")
            except sqlite3.OperationalError as e:
                print(f"⚠ No se pudo añadir la columna: {e}")
        else:
            print("✓ La columna 'topic' ya existe")
    else:
        print("⚠ No se encontró la tabla 'collections'")
    
    conn.close()
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
PYTHON_SCRIPT

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Reparación completada${NC}"
    else
        echo -e "${YELLOW}⚠ La reparación automática falló, se recreará ChromaDB${NC}"
        RECREATE=true
    fi
else
    echo -e "${YELLOW}⚠ No se encontró chroma.sqlite3${NC}"
    RECREATE=false
fi
echo ""

# Si la reparación falló, recrear ChromaDB
if [ "$RECREATE" = true ] || [ -z "$RECREATE" ]; then
    echo -e "${YELLOW}[4/5] Recreando ChromaDB (se perderán los vectores pero se pueden reimportar desde Zendesk)...${NC}"
    
    # Eliminar ChromaDB corrupta
    if [ -d "$CHROMA_DIR" ]; then
        rm -rf "$CHROMA_DIR"
        echo "  ChromaDB eliminada"
    fi
    
    # Crear nueva ChromaDB vacía
    mkdir -p "$CHROMA_DIR"
    echo -e "${GREEN}✓ ChromaDB recreada${NC}"
    echo ""
    echo -e "${YELLOW}⚠ IMPORTANTE: Los vectores se han eliminado.${NC}"
    echo -e "${YELLOW}   Necesitas reimportar el conocimiento desde Zendesk o manualmente.${NC}"
    echo ""
else
    echo -e "${GREEN}[4/5] ChromaDB reparada, no es necesario recrearla${NC}"
fi

# Reiniciar backend
echo -e "${YELLOW}[5/5] Reiniciando backend...${NC}"
pm2 start ecosystem.config.js --only osac-backend
pm2 save
sleep 3
echo -e "${GREEN}✓ Backend reiniciado${NC}"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Proceso completado!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Backup guardado en: $BACKUP_DIR"
echo ""
echo "PRÓXIMOS PASOS:"
echo ""
echo "1. Prueba el chat para ver si funciona:"
echo "   (haz una pregunta en la interfaz web)"
echo ""
echo "2. Si ChromaDB fue recreada, necesitas reimportar el conocimiento:"
echo "   - Ve a 'Gestionar Conocimiento' en la web"
echo "   - Haz clic en 'Sincronizar con Zendesk'"
echo ""
echo "3. Verifica los logs:"
echo "   pm2 logs osac-backend --lines 20"
echo ""

