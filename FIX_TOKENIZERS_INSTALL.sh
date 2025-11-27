#!/bin/bash
# Script para resolver el problema de instalación de tokenizers en Ubuntu 20.04

set -e

echo "🔧 Solucionando problema de tokenizers..."

cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Instalar dependencias de compilación necesarias
echo "📦 Instalando dependencias del sistema para compilación..."
apt-get update -qq
apt-get install -y -qq build-essential python3-dev rustc cargo 2>/dev/null || echo "Algunas dependencias pueden no estar disponibles"

# Intentar instalar tokenizers desde wheel precompilado primero
echo "📦 Intentando instalar tokenizers desde wheel precompilado..."
pip install --upgrade pip setuptools wheel

# Instalar tokenizers primero (puede que funcione sin compilar)
pip install tokenizers || {
    echo "⚠️  No se pudo instalar tokenizers desde wheel, intentando con compilación..."
    # Si falla, intentar instalar las dependencias de compilación
    pip install --only-binary :all: tokenizers 2>/dev/null || {
        echo "⚠️  Instalando tokenizers con compilación (puede tardar)..."
        pip install tokenizers
    }
}

# Ahora instalar chromadb y resto de dependencias
echo "📦 Instalando ChromaDB y resto de dependencias..."
pip install chromadb==0.4.18 || {
    echo "⚠️  ChromaDB falló, intentando sin tokenizers..."
    # Si chromadb falla, intentar instalar sin tokenizers (ya está instalado)
    pip install chromadb==0.4.18 --no-deps
    pip install $(pip show chromadb | grep Requires | cut -d: -f2 | tr ',' ' ')
}

# Instalar resto de dependencias excluyendo chromadb (ya instalado)
echo "📦 Instalando resto de dependencias..."
pip install fastapi uvicorn[standard] python-dotenv pydantic pydantic-settings python-jose[cryptography] passlib[bcrypt] python-multipart sqlalchemy requests beautifulsoup4 lxml aiohttp Pillow python-slugify email_validator apscheduler

echo "✅ Instalación completada!"

