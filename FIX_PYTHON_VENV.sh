#!/bin/bash

# Script rápido para instalar python3-venv y continuar el deploy

echo "Instalando python3-venv..."

# Detectar versión de Python
PYTHON_VERSION=$(python3 --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
echo "Python version detectada: $PYTHON_VERSION"

if [ -n "$PYTHON_VERSION" ]; then
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d. -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d. -f2)
    echo "Instalando python${PYTHON_MAJOR}.${PYTHON_MINOR}-venv..."
    apt update
    apt install -y python${PYTHON_MAJOR}.${PYTHON_MINOR}-venv
else
    echo "Instalando python3-venv genérico..."
    apt update
    apt install -y python3-venv
fi

echo "✓ python3-venv instalado"
echo ""
echo "Ahora puedes continuar:"
echo "1. Eliminar el venv corrupto: rm -rf /opt/osac-knowledge-bot/backend/venv"
echo "2. Continuar el deploy: cd /opt/osac-knowledge-bot && ./QUICK_DEPLOY.sh"
echo ""
echo "O ejecuta:"
echo "  cd /opt/osac-knowledge-bot/backend && rm -rf venv && python3 -m venv venv"

