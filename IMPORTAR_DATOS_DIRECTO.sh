#!/bin/bash
# Script simplificado para importar datos directamente

set -e

ZIP_FILE="/tmp/export_datos_20251127_154252.zip"
BACKEND_DIR="/opt/osac-knowledge-bot/backend"
EXTRACT_DIR="/tmp/export_temp"

echo "Extrayendo archivo ZIP..."
mkdir -p "$EXTRACT_DIR"
unzip -o "$ZIP_FILE" -d "$EXTRACT_DIR" 2>&1 | grep -v "backslashes" || true

echo "Buscando archivos extraídos..."
# Buscar los archivos en el directorio extraído
FIND_DIR="$EXTRACT_DIR"
if [ -d "$EXTRACT_DIR/export_datos" ]; then
    FIND_DIR="$EXTRACT_DIR/export_datos"
fi

echo "Copiando archivos..."

# Base de datos
if [ -f "$FIND_DIR/knowledge_bot.db" ]; then
    echo "Copiando base de datos..."
    cp "$FIND_DIR/knowledge_bot.db" "$BACKEND_DIR/knowledge_bot.db.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    cp "$FIND_DIR/knowledge_bot.db" "$BACKEND_DIR/"
    echo "✓ Base de datos copiada"
fi

# ChromaDB
if [ -d "$FIND_DIR/chroma_db" ]; then
    echo "Copiando ChromaDB..."
    rm -rf "$BACKEND_DIR/chroma_db.backup" 2>/dev/null || true
    [ -d "$BACKEND_DIR/chroma_db" ] && mv "$BACKEND_DIR/chroma_db" "$BACKEND_DIR/chroma_db.backup"
    cp -r "$FIND_DIR/chroma_db" "$BACKEND_DIR/"
    echo "✓ ChromaDB copiada"
fi

# Uploads
if [ -d "$FIND_DIR/uploads" ]; then
    echo "Copiando uploads..."
    if [ -d "$BACKEND_DIR/uploads" ]; then
        cp -r "$FIND_DIR/uploads"/* "$BACKEND_DIR/uploads/" 2>/dev/null || true
    else
        cp -r "$FIND_DIR/uploads" "$BACKEND_DIR/"
    fi
    echo "✓ Uploads copiados"
fi

# Limpiar
rm -rf "$EXTRACT_DIR"

echo ""
echo "✓ Datos importados correctamente"
echo ""
echo "Reiniciando backend..."
pm2 restart osac-backend
echo "✓ Backend reiniciado"

