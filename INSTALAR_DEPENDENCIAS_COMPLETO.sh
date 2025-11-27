#!/bin/bash
# Script completo para instalar todas las dependencias del backend
# Incluye instalación de Rust para compilar tokenizers

set -e

echo "🚀 Iniciando instalación completa de dependencias..."

cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Paso 1: Instalar Rust (necesario para tokenizers)
echo "📦 Paso 1/5: Instalando Rust..."
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
    echo "✅ Rust instalado"
else
    echo "✅ Rust ya está instalado"
    source $HOME/.cargo/env
fi

# Paso 2: Instalar herramientas de compilación
echo "📦 Paso 2/5: Instalando herramientas de compilación..."
apt-get update -qq
apt-get install -y -qq build-essential python3-dev pkg-config libssl-dev

# Paso 3: Actualizar pip
echo "📦 Paso 3/5: Actualizando pip..."
pip install --upgrade pip setuptools wheel

# Paso 4: Instalar tokenizers
echo "📦 Paso 4/5: Instalando tokenizers (puede tardar unos minutos)..."
pip install "tokenizers>=0.13.2"
echo "✅ tokenizers instalado"

# Paso 5: Instalar resto de dependencias
echo "📦 Paso 5/5: Instalando resto de dependencias..."
pip install -r requirements.txt

echo ""
echo "✅ ¡Instalación completada exitosamente!"
echo ""
echo "Verificando instalación..."
python -c "import chromadb; print('✅ ChromaDB OK')"
python -c "import google.generativeai; print('✅ google-generativeai OK')"
python -c "import fastapi; print('✅ FastAPI OK')"
echo ""
echo "🎉 Todo listo para iniciar el backend!"

