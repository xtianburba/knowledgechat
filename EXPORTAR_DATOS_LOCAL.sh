#!/bin/bash
# Script para exportar datos desde el entorno local

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR=$(pwd)
BACKEND_DIR="$PROJECT_DIR/backend"
EXPORT_DIR="$PROJECT_DIR/export_datos_$(date +%Y%m%d_%H%M%S)"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Exportando Datos desde Local${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Crear directorio de exportación
mkdir -p "$EXPORT_DIR"
echo -e "${GREEN}✓ Directorio de exportación creado: $EXPORT_DIR${NC}"
echo ""

# 1. Exportar base de datos SQLite
echo -e "${YELLOW}[1/4] Exportando base de datos SQLite...${NC}"
if [ -f "$BACKEND_DIR/knowledge_bot.db" ]; then
    cp "$BACKEND_DIR/knowledge_bot.db" "$EXPORT_DIR/knowledge_bot.db"
    echo -e "${GREEN}✓ Base de datos SQLite exportada${NC}"
else
    echo -e "${YELLOW}⚠ No se encontró knowledge_bot.db${NC}"
fi
echo ""

# 2. Exportar ChromaDB (base de datos vectorial)
echo -e "${YELLOW}[2/4] Exportando ChromaDB...${NC}"
if [ -d "$BACKEND_DIR/chroma_db" ]; then
    cp -r "$BACKEND_DIR/chroma_db" "$EXPORT_DIR/chroma_db"
    echo -e "${GREEN}✓ ChromaDB exportada${NC}"
else
    echo -e "${YELLOW}⚠ No se encontró chroma_db${NC}"
fi
echo ""

# 3. Exportar uploads (imágenes y archivos)
echo -e "${YELLOW}[3/4] Exportando archivos uploads...${NC}"
if [ -d "$BACKEND_DIR/uploads" ]; then
    cp -r "$BACKEND_DIR/uploads" "$EXPORT_DIR/uploads"
    echo -e "${GREEN}✓ Archivos uploads exportados${NC}"
else
    echo -e "${YELLOW}⚠ No se encontró directorio uploads${NC}"
fi
echo ""

# 4. Crear archivo de información
echo -e "${YELLOW}[4/4] Creando archivo de información...${NC}"
cat > "$EXPORT_DIR/INFO.txt" << EOF
Exportación de datos OSAC Knowledge Bot
Fecha: $(date)
Directorio de origen: $PROJECT_DIR

Contenido:
- knowledge_bot.db: Base de datos SQLite (usuarios, conocimiento, analytics)
- chroma_db/: Base de datos vectorial para búsqueda semántica
- uploads/: Archivos e imágenes subidos

Para importar en el servidor, ejecuta:
  ./IMPORTAR_DATOS_SERVIDOR.sh

O manualmente copia estos archivos al servidor y ejecuta:
  scp -r export_datos_* usuario@servidor:/tmp/
  # En el servidor:
  cd /opt/osac-knowledge-bot
  ./IMPORTAR_DATOS_SERVIDOR.sh /tmp/export_datos_*
EOF

echo -e "${GREEN}✓ Archivo de información creado${NC}"
echo ""

# Comprimir todo
echo -e "${YELLOW}Comprimiendo datos exportados...${NC}"
cd "$PROJECT_DIR"
tar -czf "${EXPORT_DIR}.tar.gz" "$(basename $EXPORT_DIR)"
rm -rf "$EXPORT_DIR"
echo -e "${GREEN}✓ Datos comprimidos en: ${EXPORT_DIR}.tar.gz${NC}"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Exportación completada!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Archivo creado: ${EXPORT_DIR}.tar.gz"
echo ""
echo "Para transferir al servidor:"
echo "  scp ${EXPORT_DIR}.tar.gz root@82.223.20.111:/tmp/"
echo ""
echo "O usa el script IMPORTAR_DATOS_SERVIDOR.sh en el servidor"
echo ""

