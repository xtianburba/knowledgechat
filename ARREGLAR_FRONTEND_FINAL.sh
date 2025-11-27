#!/bin/bash
# Script para arreglar el frontend definitivamente

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

FRONTEND_DIR="/opt/osac-knowledge-bot/frontend"
PROJECT_DIR="/opt/osac-knowledge-bot"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Arreglando Frontend - Configuración Final${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

cd "$FRONTEND_DIR"

# Paso 1: Verificar que build existe
if [ ! -d "build" ]; then
    echo -e "${YELLOW}[1/5] Compilando frontend...${NC}"
    npm install
    npm run build
    echo -e "${GREEN}✓ Frontend compilado${NC}"
else
    echo -e "${GREEN}✓ Carpeta build existe${NC}"
fi
echo ""

# Paso 2: Detener frontend actual
echo -e "${YELLOW}[2/5] Deteniendo frontend actual...${NC}"
pm2 stop osac-frontend 2>/dev/null || true
pm2 delete osac-frontend 2>/dev/null || true
echo -e "${GREEN}✓ Frontend detenido${NC}"
echo ""

# Paso 3: Usar serve directamente desde node_modules
echo -e "${YELLOW}[3/5] Verificando instalación de serve...${NC}"
npm install
if [ ! -f "node_modules/.bin/serve" ]; then
    echo "  Instalando serve..."
    npm install serve
fi
echo -e "${GREEN}✓ Serve instalado${NC}"
echo ""

# Paso 4: Crear script de inicio temporal
echo -e "${YELLOW}[4/5] Creando script de inicio...${NC}"
cat > "$FRONTEND_DIR/start-serve.sh" << 'EOF'
#!/bin/bash
cd /opt/osac-knowledge-bot/frontend
./node_modules/.bin/serve -s build -l 3001
EOF

chmod +x "$FRONTEND_DIR/start-serve.sh"
echo -e "${GREEN}✓ Script de inicio creado${NC}"
echo ""

# Paso 5: Actualizar ecosystem.config.js para usar el script
echo -e "${YELLOW}[5/5] Actualizando configuración de PM2...${NC}"
cd "$PROJECT_DIR"

# Crear una copia de seguridad
cp ecosystem.config.js ecosystem.config.js.bak

# Crear nueva configuración temporal solo para frontend
cat > /tmp/frontend-pm2-config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'osac-frontend',
      script: '/opt/osac-knowledge-bot/frontend/start-serve.sh',
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
      max_memory_restart: '300M',
      interpreter: 'bash'
    }
  ]
};
EOF

# Iniciar con la configuración temporal
pm2 start /tmp/frontend-pm2-config.js

# Actualizar ecosystem.config.js principal
cd "$PROJECT_DIR"
sed -i 's|script: '"'"'npx'"'"'|script: '"'"'/opt/osac-knowledge-bot/frontend/start-serve.sh'"'"'|' ecosystem.config.js
sed -i 's|args: '"'"'-s build -l 3001'"'"'|interpreter: '"'"'bash'"'"'|' ecosystem.config.js
sed -i '/^[[:space:]]*args:/d' ecosystem.config.js

echo -e "${GREEN}✓ Configuración actualizada${NC}"
echo ""

# Guardar configuración PM2
pm2 save

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Frontend arreglado!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Estado del frontend:"
pm2 status | grep osac-frontend
echo ""
echo "Probando conexión..."
sleep 2
if curl -s http://localhost:3001 | grep -q "html\|DOCTYPE"; then
    echo -e "${GREEN}✓ Frontend responde correctamente en puerto 3001${NC}"
else
    echo -e "${YELLOW}⚠ Verifica los logs: pm2 logs osac-frontend${NC}"
fi
echo ""

