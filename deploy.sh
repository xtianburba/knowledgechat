#!/bin/bash

# Script de Deploy para OSAC Knowledge Bot - Servidor IONOS
# NO modifica ni interfiere con aplicaciones existentes

set -e  # Salir si hay algún error

echo "=========================================="
echo "Deploy OSAC Knowledge Bot - IONOS Server"
echo "=========================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Verificar que estamos en el directorio correcto
if [ ! -f "backend/main.py" ] || [ ! -f "frontend/package.json" ]; then
    echo -e "${RED}Error: Este script debe ejecutarse desde la raíz del proyecto${NC}"
    exit 1
fi

# Directorio de instalación
INSTALL_DIR="/opt/osac-knowledge-bot"
CURRENT_DIR=$(pwd)

echo -e "${YELLOW}Paso 1: Verificando requisitos...${NC}"

# Verificar Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python3 no está instalado. Instalando...${NC}"
    apt update
    apt install -y python3 python3-pip python3-venv
fi

# Verificar Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}Node.js no está instalado. Instalando...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
fi

# Verificar PM2
if ! command -v pm2 &> /dev/null; then
    echo -e "${YELLOW}PM2 no está instalado. Instalando globalmente...${NC}"
    npm install -g pm2
fi

# Verificar Git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Git no está instalado. Instalando...${NC}"
    apt install -y git
fi

echo -e "${GREEN}✓ Requisitos verificados${NC}"
echo ""

echo -e "${YELLOW}Paso 2: Preparando directorio de instalación...${NC}"

# Crear directorio si no existe
if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR"
    echo -e "${GREEN}✓ Directorio creado: $INSTALL_DIR${NC}"
else
    echo -e "${YELLOW}⚠ Directorio ya existe: $INSTALL_DIR${NC}"
    read -p "¿Deseas continuar? (se actualizará el código) [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""

echo -e "${YELLOW}Paso 3: Copiando archivos del proyecto...${NC}"

# Copiar archivos (si no estamos ya en el directorio de instalación)
if [ "$CURRENT_DIR" != "$INSTALL_DIR" ]; then
    echo "Copiando desde $CURRENT_DIR a $INSTALL_DIR..."
    cp -r "$CURRENT_DIR"/* "$INSTALL_DIR"/ 2>/dev/null || {
        echo "Intentando copiar archivos manualmente..."
        rsync -av --exclude='node_modules' --exclude='venv' --exclude='.git' "$CURRENT_DIR"/ "$INSTALL_DIR"/
    }
    echo -e "${GREEN}✓ Archivos copiados${NC}"
else
    echo -e "${GREEN}✓ Ya estamos en el directorio de instalación${NC}"
fi

cd "$INSTALL_DIR"

echo ""

echo -e "${YELLOW}Paso 4: Configurando Backend...${NC}"

cd backend

# Crear entorno virtual si no existe
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "${GREEN}✓ Entorno virtual creado${NC}"
else
    echo -e "${YELLOW}⚠ Entorno virtual ya existe${NC}"
fi

# Activar entorno virtual e instalar dependencias
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

echo -e "${GREEN}✓ Dependencias del backend instaladas${NC}"

# Crear archivo .env si no existe
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠ Creando archivo .env desde .env.example (si existe)...${NC}"
    if [ -f ".env.example" ]; then
        cp .env.example .env
        echo -e "${GREEN}✓ Archivo .env creado. ${RED}IMPORTANTE: Edita .env con tus credenciales${NC}"
    else
        touch .env
        echo -e "${YELLOW}⚠ Archivo .env creado vacío. ${RED}IMPORTANTE: Configúralo con tus credenciales${NC}"
    fi
else
    echo -e "${GREEN}✓ Archivo .env ya existe${NC}"
fi

# Crear directorios necesarios
mkdir -p chroma_db
mkdir -p uploads
mkdir -p logs

echo -e "${GREEN}✓ Directorios creados${NC}"

cd ..

echo ""

echo -e "${YELLOW}Paso 5: Configurando Frontend...${NC}"

cd frontend

# Instalar dependencias
npm install

# Crear build de producción
echo -e "${YELLOW}Construyendo aplicación de producción...${NC}"
npm run build

echo -e "${GREEN}✓ Build de producción creado${NC}"

cd ..

echo ""

echo -e "${YELLOW}Paso 6: Creando configuración PM2...${NC}"

# Crear ecosystem.config.js si no existe
if [ ! -f "ecosystem.config.js" ]; then
    cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'osac-backend',
      script: './backend/venv/bin/uvicorn',
      args: 'main:app --host 0.0.0.0 --port 8001 --workers 2',
      cwd: '/opt/osac-knowledge-bot/backend',
      interpreter: 'none',
      env: {
        NODE_ENV: 'production',
        PYTHONUNBUFFERED: '1'
      },
      error_file: '/opt/osac-knowledge-bot/backend/logs/backend-error.log',
      out_file: '/opt/osac-knowledge-bot/backend/logs/backend-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '500M',
      instances: 1,
      exec_mode: 'fork'
    },
    {
      name: 'osac-frontend',
      script: 'serve',
      args: '-s build -l 3001',
      cwd: '/opt/osac-knowledge-bot/frontend',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      },
      error_file: '/opt/osac-knowledge-bot/frontend/logs/frontend-error.log',
      out_file: '/opt/osac-knowledge-bot/frontend/logs/frontend-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      max_memory_restart: '300M'
    }
  ]
};
EOF
    echo -e "${GREEN}✓ Archivo ecosystem.config.js creado${NC}"
else
    echo -e "${GREEN}✓ Archivo ecosystem.config.js ya existe${NC}"
fi

# Instalar serve globalmente si no está instalado
if ! command -v serve &> /dev/null; then
    echo -e "${YELLOW}Instalando 'serve' para servir el frontend...${NC}"
    npm install -g serve
fi

# Crear directorio de logs
mkdir -p frontend/logs

echo ""

echo -e "${YELLOW}Paso 7: Inicializando base de datos...${NC}"

cd backend
source venv/bin/activate
python3 -c "from database import init_db; init_db(); print('✓ Base de datos inicializada')" || {
    echo -e "${YELLOW}⚠ Error al inicializar base de datos (puede que ya esté inicializada)${NC}"
}
cd ..

echo ""

echo -e "${GREEN}=========================================="
echo "✓ Deploy completado exitosamente!"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo ""
echo "1. ${RED}IMPORTANTE:${NC} Edita el archivo .env con tus credenciales:"
echo "   nano $INSTALL_DIR/backend/.env"
echo ""
echo "2. Inicia las aplicaciones con PM2:"
echo "   cd $INSTALL_DIR"
echo "   pm2 start ecosystem.config.js"
echo ""
echo "3. Guarda la configuración PM2:"
echo "   pm2 save"
echo "   pm2 startup"
echo ""
echo "4. Configura Apache como reverse proxy (ver DEPLOY_IONOS.md)"
echo ""
echo "5. Verifica el estado:"
echo "   pm2 status"
echo "   pm2 logs"
echo ""
echo -e "${GREEN}¡Listo para continuar!${NC}"

