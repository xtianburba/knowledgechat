#!/bin/bash
# Script para actualizar CORS_ORIGINS en el archivo .env

set -e

ENV_FILE="/opt/osac-knowledge-bot/backend/.env"
SUBDOMAIN="osac-knowledge-bot.perfumesclub-helping.com"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ El archivo .env no existe: $ENV_FILE"
    echo "Ejecuta primero: ./CREAR_ENV.sh"
    exit 1
fi

echo "📝 Actualizando CORS_ORIGINS en $ENV_FILE..."

# Actualizar CORS_ORIGINS
sed -i "s|^CORS_ORIGINS=.*|CORS_ORIGINS=http://${SUBDOMAIN},http://82.223.20.111,http://localhost:3000,http://localhost:8000|" "$ENV_FILE"

echo "✅ CORS_ORIGINS actualizado"
echo ""
echo "Contenido actualizado:"
grep "^CORS_ORIGINS=" "$ENV_FILE"
echo ""
echo "⚠️  Reinicia el backend para aplicar los cambios:"
echo "   pm2 restart osac-backend"

