#!/bin/bash
# Script para crear el usuario Krystian en la base de datos

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BACKEND_DIR="/opt/osac-knowledge-bot/backend"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Creando usuario Krystian${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

cd "$BACKEND_DIR"

# Activar entorno virtual
if [ ! -d "venv" ]; then
    echo -e "${RED}❌ El entorno virtual no existe en $BACKEND_DIR/venv${NC}"
    exit 1
fi

source venv/bin/activate

# Verificar si el script existe
if [ ! -f "crear_usuario.py" ]; then
    echo -e "${RED}❌ El script crear_usuario.py no existe${NC}"
    exit 1
fi

# Crear usuario
echo -e "${YELLOW}Creando usuario Krystian...${NC}"
echo ""

python crear_usuario.py Krystian krystian.burba@perfumesclub.com Perfumes22 admin

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Usuario creado!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Ahora puedes iniciar sesión con:"
echo "  Usuario: Krystian"
echo "  Contraseña: Perfumes22"
echo ""

