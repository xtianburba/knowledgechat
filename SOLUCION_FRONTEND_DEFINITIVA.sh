#!/bin/bash
# Solución definitiva para el frontend - usar script wrapper

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

FRONTEND_DIR="/opt/osac-knowledge-bot/frontend"
PROJECT_DIR="/opt/osac-knowledge-bot"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Solución Definitiva para el Frontend${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

cd "$FRONTEND_DIR"

# 1. Verificar build
if [ ! -d "build" ]; then
    echo "Compilando frontend..."
    npm install
    npm run build
fi

# 2. Crear script wrapper para serve
echo "Creando script wrapper para serve..."
cat > "$FRONTEND_DIR/serve-frontend.sh" << 'SCRIPTEOF'
#!/bin/bash
cd /opt/osac-knowledge-bot/frontend
exec ./node_modules/.bin/serve -s build -l 3001
SCRIPTEOF

chmod +x "$FRONTEND_DIR/serve-frontend.sh"
echo -e "${GREEN}✓ Script wrapper creado${NC}"
echo ""

# 3. Actualizar ecosystem.config.js
cd "$PROJECT_DIR"
echo "Actualizando ecosystem.config.js..."

# Crear backup
cp ecosystem.config.js ecosystem.config.js.bak

# Actualizar la configuración del frontend para usar el script wrapper
cat > /tmp/new-ecosystem.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'osac-backend',
      script: './backend/venv/bin/python',
      args: '-m uvicorn main:app --host 0.0.0.0 --port 8001 --workers 2',
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
      script: '/opt/osac-knowledge-bot/frontend/serve-frontend.sh',
      cwd: '/opt/osac-knowledge-bot/frontend',
      interpreter: 'bash',
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

mv /tmp/new-ecosystem.js ecosystem.config.js
echo -e "${GREEN}✓ ecosystem.config.js actualizado${NC}"
echo ""

# 4. Detener y reiniciar frontend
echo "Reiniciando frontend..."
pm2 stop osac-frontend 2>/dev/null || true
pm2 delete osac-frontend 2>/dev/null || true
sleep 2

pm2 start ecosystem.config.js --only osac-frontend
sleep 3

# 5. Verificar
echo ""
echo -e "${YELLOW}Verificando...${NC}"
if curl -s http://localhost:3001 | grep -q "html\|DOCTYPE"; then
    echo -e "${GREEN}✓ Frontend funcionando correctamente en puerto 3001${NC}"
else
    echo -e "${YELLOW}⚠ Esperando un poco más...${NC}"
    sleep 2
    if curl -s http://localhost:3001 | grep -q "html\|DOCTYPE"; then
        echo -e "${GREEN}✓ Frontend funcionando correctamente en puerto 3001${NC}"
    else
        echo -e "${RED}✗ Frontend aún no responde. Ver logs: pm2 logs osac-frontend${NC}"
    fi
fi

pm2 save

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Configuración completada!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
pm2 status | grep osac-frontend
echo ""

