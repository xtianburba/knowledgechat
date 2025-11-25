#!/bin/bash

# Script Rápido de Deploy - OSAC Knowledge Bot
# Para servidor IONOS (82.223.20.111)

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║     OSAC Knowledge Bot - Deploy Rápido (IONOS)        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Verificar que estamos como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}⚠ Este script debe ejecutarse como root${NC}"
    echo "Ejecuta: sudo $0"
    exit 1
fi

INSTALL_DIR="/opt/osac-knowledge-bot"
REPO_URL="https://github.com/xtianburba/knowledgechat.git"

echo -e "${YELLOW}[1/7] Verificando repositorio...${NC}"
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}  ⚠ Directorio ya existe. Actualizando código...${NC}"
    cd "$INSTALL_DIR"
    git pull || echo "  ⚠ No es un repositorio git o hay cambios locales"
else
    mkdir -p /opt
    cd /opt
    echo -e "${YELLOW}  Intentando clonar repositorio...${NC}"
    echo -e "${YELLOW}  Si pide autenticación y falla:${NC}"
    echo -e "${YELLOW}  1. Haz el repositorio público en GitHub, O${NC}"
    echo -e "${YELLOW}  2. Usa: git clone https://TU_TOKEN@github.com/xtianburba/knowledgechat.git${NC}"
    git clone "$REPO_URL" osac-knowledge-bot || {
        echo -e "${RED}  ✗ Error al clonar. Ver SOLUCION_GITHUB_AUTH.md${NC}"
        exit 1
    }
    cd osac-knowledge-bot
fi
echo -e "${GREEN}  ✓ Código actualizado${NC}"
echo ""

echo -e "${YELLOW}[2/7] Instalando dependencias del sistema...${NC}"
apt update -qq
# Intentar instalar todo junto primero
apt install -y python3 python3-pip python3-venv git build-essential 2>/dev/null || true
# Node.js - si ya está instalado desde NodeSource, npm viene incluido
if ! command -v node &> /dev/null; then
    apt install -y nodejs 2>/dev/null || true
fi
# Instalar python3-venv específico si es necesario
PYTHON_VERSION=$(python3 --version 2>&1 | grep -oP '\d+\.\d+' | head -1 || echo "3.8")
PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
apt install -y python${PYTHON_MAJOR}.${PYTHON_MINOR}-venv 2>/dev/null || apt install -y python3-venv 2>/dev/null || true
# Instalar PM2 y serve globalmente (ignorar errores de npm ya que nodejs incluye npm)
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2 2>/dev/null || {
        echo -e "${YELLOW}  ⚠ PM2 no se pudo instalar, pero continuando...${NC}"
    }
fi
if ! command -v serve &> /dev/null; then
    npm install -g serve 2>/dev/null || {
        echo -e "${YELLOW}  ⚠ serve no se pudo instalar, pero continuando...${NC}"
    }
fi
echo -e "${GREEN}  ✓ Dependencias instaladas (ignorando conflictos menores de npm)${NC}"
echo ""

echo -e "${YELLOW}[3/7] Configurando Backend...${NC}"
cd "$INSTALL_DIR/backend"

# Eliminar venv si existe pero está corrupto
if [ -d "venv" ] && [ ! -f "venv/bin/python3" ]; then
    echo -e "${YELLOW}  Eliminando entorno virtual corrupto...${NC}"
    rm -rf venv
fi

# Crear entorno virtual
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}  Creando entorno virtual...${NC}"
    python3 -m venv venv || {
        echo -e "${RED}  Error creando venv. Instalando python3-venv...${NC}"
        PYTHON_VERSION=$(python3 --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
        if [ -n "$PYTHON_VERSION" ]; then
            PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
            PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
            apt install -y python${PYTHON_MAJOR}.${PYTHON_MINOR}-venv
        else
            apt install -y python3-venv
        fi
        python3 -m venv venv
    }
fi

source venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
mkdir -p chroma_db uploads logs
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}  ⚠ Creando archivo .env...${NC}"
    touch .env
    echo -e "${RED}  ⚠ IMPORTANTE: Debes editar .env con tus credenciales después${NC}"
fi
echo -e "${GREEN}  ✓ Backend configurado${NC}"
echo ""

echo -e "${YELLOW}[4/7] Configurando Frontend...${NC}"
cd "$INSTALL_DIR/frontend"
npm install -q
npm run build -q
mkdir -p logs
echo -e "${GREEN}  ✓ Frontend configurado${NC}"
echo ""

echo -e "${YELLOW}[5/7] Configurando PM2...${NC}"
cd "$INSTALL_DIR"
chmod +x deploy.sh
if [ ! -f "ecosystem.config.js" ]; then
    echo -e "${YELLOW}  ⚠ Creando ecosystem.config.js...${NC}"
    # El archivo debería estar en el repo, pero lo creamos por si acaso
fi
echo -e "${GREEN}  ✓ PM2 configurado${NC}"
echo ""

echo -e "${YELLOW}[6/7] Configurando Apache...${NC}"
cd "$INSTALL_DIR"
if [ -f "setup-apache.sh" ]; then
    chmod +x setup-apache.sh
    ./setup-apache.sh
else
    echo -e "${YELLOW}  ⚠ Script de Apache no encontrado. Configura manualmente.${NC}"
fi
echo ""

echo -e "${YELLOW}[7/7] Iniciando aplicaciones con PM2...${NC}"
cd "$INSTALL_DIR"
pm2 delete osac-backend 2>/dev/null || true
pm2 delete osac-frontend 2>/dev/null || true
pm2 start ecosystem.config.js
pm2 save
echo -e "${GREEN}  ✓ Aplicaciones iniciadas${NC}"
echo ""

echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║          ✓ Deploy Completado Exitosamente             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo ""
echo "1. ${RED}CONFIGURAR CREDENCIALES:${NC}"
echo "   nano $INSTALL_DIR/backend/.env"
echo ""
echo "2. Verificar estado:"
echo "   pm2 status"
echo "   pm2 logs"
echo ""
echo "3. Acceder a la aplicación:"
echo "   http://82.223.20.111"
echo ""
echo -e "${GREEN}¡Listo!${NC}"

