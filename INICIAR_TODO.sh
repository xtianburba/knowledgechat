#!/bin/bash
# Script para iniciar el backend y frontend con PM2

set -e

echo "🚀 Iniciando OSAC Knowledge Bot..."

cd /opt/osac-knowledge-bot

# Verificar que el .env existe
if [ ! -f "backend/.env" ]; then
    echo "❌ Error: El archivo backend/.env no existe!"
    echo "Por favor, crea el archivo .env con tus credenciales."
    exit 1
fi

# Crear directorios de logs si no existen
mkdir -p backend/logs frontend/logs

# Verificar que el frontend está compilado
if [ ! -d "frontend/build" ]; then
    echo "📦 Compilando frontend para producción..."
    cd frontend
    npm install
    npm run build
    cd ..
fi

# Detener aplicaciones si ya están corriendo
echo "🛑 Deteniendo aplicaciones existentes (si existen)..."
pm2 stop osac-backend osac-frontend 2>/dev/null || true
pm2 delete osac-backend osac-frontend 2>/dev/null || true

# Iniciar aplicaciones con PM2
echo "🚀 Iniciando backend..."
pm2 start ecosystem.config.js --only osac-backend

echo "🚀 Iniciando frontend..."
pm2 start ecosystem.config.js --only osac-frontend

# Guardar configuración PM2
pm2 save

echo ""
echo "✅ Aplicaciones iniciadas!"
echo ""
echo "Ver estado:"
echo "  pm2 status"
echo ""
echo "Ver logs:"
echo "  pm2 logs osac-backend"
echo "  pm2 logs osac-frontend"
echo ""
echo "Aplicación disponible en:"
echo "  - Backend: http://localhost:8001/api/health"
echo "  - Frontend: http://localhost:3001"

