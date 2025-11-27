#!/bin/bash
# Script para crear el archivo .env con valores mínimos

set -e

ENV_FILE="/opt/osac-knowledge-bot/backend/.env"

if [ -f "$ENV_FILE" ]; then
    echo "⚠️  El archivo .env ya existe en $ENV_FILE"
    echo "¿Deseas sobrescribirlo? (s/N)"
    read -r response
    if [[ ! "$response" =~ ^[Ss]$ ]]; then
        echo "Operación cancelada."
        exit 0
    fi
fi

# Generar JWT_SECRET aleatorio
JWT_SECRET=$(openssl rand -hex 32)

echo "📝 Creando archivo .env..."

cat > "$ENV_FILE" << EOF
# Google Gemini API Key (OBLIGATORIO)
# Obtén tu clave en: https://makersuite.google.com/app/apikey
GEMINI_API_KEY=

# JWT Secret (ya generado automáticamente)
JWT_SECRET=$JWT_SECRET

# CORS Origins (ajustar según tu dominio)
CORS_ORIGINS=http://82.223.20.111,http://82.223.20.111:3001,http://localhost:3000,http://localhost:8000

# ChromaDB Path
CHROMA_DB_PATH=/opt/osac-knowledge-bot/backend/chroma_db

# Upload Directory
UPLOAD_DIR=/opt/osac-knowledge-bot/backend/uploads

# Zendesk (Opcional - descomenta y completa si lo necesitas)
# ZENDESK_SUBDOMAIN=
# ZENDESK_EMAIL=
# ZENDESK_API_TOKEN=
# ZENDESK_AUTO_SYNC=false
# ZENDESK_SYNC_HOUR=2
# ZENDESK_SYNC_MINUTE=0
EOF

echo "✅ Archivo .env creado en $ENV_FILE"
echo ""
echo "⚠️  IMPORTANTE: Edita el archivo y añade tu GEMINI_API_KEY:"
echo "   nano $ENV_FILE"
echo ""
echo "El JWT_SECRET ya ha sido generado automáticamente."

