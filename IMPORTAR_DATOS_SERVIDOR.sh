#!/bin/bash
# Script para importar datos en el servidor

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="/opt/osac-knowledge-bot"
BACKEND_DIR="$PROJECT_DIR/backend"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Importando Datos en el Servidor${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Por favor, ejecuta como root: sudo $0${NC}"
    exit 1
fi

# Detectar si se pasó un archivo como argumento
if [ -n "$1" ]; then
    EXPORT_FILE="$1"
else
    # Buscar el archivo más reciente en /tmp (buscar tanto .tar.gz como .zip)
    EXPORT_FILE=$(ls -t /tmp/export_datos_*.tar.gz /tmp/export_datos_*.zip 2>/dev/null | head -1)
    
    if [ -z "$EXPORT_FILE" ]; then
        echo -e "${RED}No se encontró archivo de exportación${NC}"
        echo ""
        echo "Uso: $0 [ruta_al_archivo.tar.gz o .zip]"
        echo ""
        echo "O coloca el archivo export_datos_*.tar.gz o export_datos_*.zip en /tmp/"
        echo ""
        exit 1
    fi
fi

echo -e "${YELLOW}Archivo de exportación: $EXPORT_FILE${NC}"
echo ""

if [ ! -f "$EXPORT_FILE" ]; then
    echo -e "${RED}El archivo no existe: $EXPORT_FILE${NC}"
    exit 1
fi

# Extraer archivo
echo -e "${YELLOW}[1/4] Extrayendo archivo...${NC}"
EXPORT_DIR="/tmp/export_datos_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$EXPORT_DIR"

# Determinar si es .zip o .tar.gz
if [[ "$EXPORT_FILE" == *.zip ]]; then
    echo "  Extrayendo archivo ZIP..."
    unzip -q "$EXPORT_FILE" -d "$EXPORT_DIR" 2>/dev/null || {
        echo -e "${RED}Error al extraer ZIP. Instalando unzip...${NC}"
        apt-get update && apt-get install -y unzip
        unzip -q "$EXPORT_FILE" -d "$EXPORT_DIR"
    }
    # Encontrar el directorio dentro del zip
    EXPORT_DIR=$(find "$EXPORT_DIR" -maxdepth 1 -type d | grep -v "^$EXPORT_DIR$" | head -1 || echo "$EXPORT_DIR")
else
    echo "  Extrayendo archivo TAR.GZ..."
    tar -xzf "$EXPORT_FILE" -C "$EXPORT_DIR" --strip-components=1 2>/dev/null || tar -xzf "$EXPORT_FILE" -C "$EXPORT_DIR"
    EXPORT_DIR=$(find "$EXPORT_DIR" -maxdepth 1 -type d | grep -v "^$EXPORT_DIR$" | head -1 || echo "$EXPORT_DIR")
fi

echo -e "${GREEN}✓ Archivo extraído${NC}"
echo ""

# Detener servicios
echo -e "${YELLOW}[2/4] Deteniendo servicios...${NC}"
pm2 stop osac-backend 2>/dev/null || true
sleep 2
echo -e "${GREEN}✓ Servicios detenidos${NC}"
echo ""

# Crear backups
echo -e "${YELLOW}[3/4] Creando backups de datos existentes...${NC}"
BACKUP_DIR="$PROJECT_DIR/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ -f "$BACKEND_DIR/knowledge_bot.db" ]; then
    cp "$BACKEND_DIR/knowledge_bot.db" "$BACKUP_DIR/knowledge_bot.db.backup"
    echo -e "${GREEN}✓ Backup de base de datos creado${NC}"
fi

if [ -d "$BACKEND_DIR/chroma_db" ]; then
    cp -r "$BACKEND_DIR/chroma_db" "$BACKUP_DIR/chroma_db.backup"
    echo -e "${GREEN}✓ Backup de ChromaDB creado${NC}"
fi

if [ -d "$BACKEND_DIR/uploads" ]; then
    cp -r "$BACKEND_DIR/uploads" "$BACKUP_DIR/uploads.backup"
    echo -e "${GREEN}✓ Backup de uploads creado${NC}"
fi

echo -e "${GREEN}✓ Backups creados en: $BACKUP_DIR${NC}"
echo ""

# Importar datos
echo -e "${YELLOW}[4/4] Importando datos...${NC}"

# Importar base de datos SQLite
if [ -f "$EXPORT_DIR/knowledge_bot.db" ]; then
    cp "$EXPORT_DIR/knowledge_bot.db" "$BACKEND_DIR/knowledge_bot.db"
    chown -R www-data:www-data "$BACKEND_DIR/knowledge_bot.db" 2>/dev/null || chown -R root:root "$BACKEND_DIR/knowledge_bot.db"
    chmod 644 "$BACKEND_DIR/knowledge_bot.db"
    echo -e "${GREEN}✓ Base de datos SQLite importada${NC}"
else
    echo -e "${YELLOW}⚠ No se encontró knowledge_bot.db en la exportación${NC}"
fi

# Importar ChromaDB
if [ -d "$EXPORT_DIR/chroma_db" ]; then
    rm -rf "$BACKEND_DIR/chroma_db"
    cp -r "$EXPORT_DIR/chroma_db" "$BACKEND_DIR/chroma_db"
    chown -R www-data:www-data "$BACKEND_DIR/chroma_db" 2>/dev/null || chown -R root:root "$BACKEND_DIR/chroma_db"
    echo -e "${GREEN}✓ ChromaDB importada${NC}"
else
    echo -e "${YELLOW}⚠ No se encontró chroma_db en la exportación${NC}"
fi

# Importar uploads
if [ -d "$EXPORT_DIR/uploads" ]; then
    if [ -d "$BACKEND_DIR/uploads" ]; then
        # Merge: mantener archivos existentes y añadir nuevos
        cp -r "$EXPORT_DIR/uploads"/* "$BACKEND_DIR/uploads/" 2>/dev/null || true
    else
        mkdir -p "$BACKEND_DIR/uploads"
        cp -r "$EXPORT_DIR/uploads" "$BACKEND_DIR/uploads"
    fi
    chown -R www-data:www-data "$BACKEND_DIR/uploads" 2>/dev/null || chown -R root:root "$BACKEND_DIR/uploads"
    echo -e "${GREEN}✓ Archivos uploads importados${NC}"
else
    echo -e "${YELLOW}⚠ No se encontró uploads en la exportación${NC}"
fi

# Limpiar archivos temporales
rm -rf "$EXPORT_DIR"

echo ""

# Reiniciar servicios
echo -e "${YELLOW}Reiniciando servicios...${NC}"
pm2 restart osac-backend
sleep 2
echo -e "${GREEN}✓ Servicios reiniciados${NC}"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Importación completada!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Datos importados:"
echo "  - Base de datos SQLite (usuarios, conocimiento)"
echo "  - ChromaDB (base de datos vectorial)"
echo "  - Archivos uploads (imágenes)"
echo ""
echo "Backups guardados en: $BACKUP_DIR"
echo ""
echo "Ya puedes iniciar sesión con tus usuarios locales."
echo ""

