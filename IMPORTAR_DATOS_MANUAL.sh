#!/bin/bash
# Script manual para importar datos del ZIP de Windows

set -e

ZIP_FILE="/tmp/export_datos_20251127_154252.zip"
BACKEND_DIR="/opt/osac-knowledge-bot/backend"
EXTRACT_DIR="/tmp/export_manual"

echo "Extrayendo ZIP..."
rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"

# Extraer con conversión automática de backslashes
cd "$EXTRACT_DIR"
unzip -a "$ZIP_FILE" 2>&1 | grep -v "backslashes" || true

echo ""
echo "Archivos extraídos:"
ls -la

echo ""
echo "Copiando archivos al backend..."

# Hacer backups
cd "$BACKEND_DIR"
cp knowledge_bot.db knowledge_bot.db.backup_$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
[ -d chroma_db ] && mv chroma_db chroma_db.backup_$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Copiar base de datos
if [ -f "$EXTRACT_DIR/knowledge_bot.db" ]; then
    cp "$EXTRACT_DIR/knowledge_bot.db" .
    echo "✓ Base de datos copiada"
else
    echo "⚠ No se encontró knowledge_bot.db"
fi

# Copiar ChromaDB (puede tener backslashes convertidos a slashes)
if [ -d "$EXTRACT_DIR/chroma_db" ]; then
    cp -r "$EXTRACT_DIR/chroma_db" .
    echo "✓ ChromaDB copiada"
else
    echo "⚠ No se encontró chroma_db"
fi

# Copiar uploads
if [ -d "$EXTRACT_DIR/uploads" ]; then
    if [ -d "uploads" ]; then
        cp -r "$EXTRACT_DIR/uploads"/* uploads/ 2>/dev/null || true
    else
        cp -r "$EXTRACT_DIR/uploads" .
    fi
    echo "✓ Uploads copiados"
else
    echo "⚠ No se encontró uploads"
fi

# Limpiar
rm -rf "$EXTRACT_DIR"

echo ""
echo "✓ Datos importados"
echo ""
echo "Reiniciando backend..."
pm2 restart osac-backend
sleep 2
echo "✓ Backend reiniciado"
echo ""

