#!/bin/bash
# Solución final: Instalar dependencias evitando el problema de compilación de tokenizers

set -e

echo "🔧 Solución final para instalar dependencias..."

cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Actualizar pip
pip install --upgrade pip setuptools wheel

# Instalar dependencias de compilación básicas (sin Rust, que es más pesado)
echo "📦 Instalando herramientas de compilación básicas..."
apt-get update -qq
apt-get install -y -qq build-essential python3-dev 2>/dev/null || echo "Continuando sin algunas dependencias..."

# ESTRATEGIA: Instalar chromadb sin las dependencias problemáticas y luego completar
echo "📦 Instalando ChromaDB sin tokenizers (lo instalaremos después)..."
pip install --no-deps chromadb==0.4.18

# Instalar las dependencias de chromadb manualmente, excepto tokenizers
echo "📦 Instalando dependencias de ChromaDB..."
pip install chroma-hnswlib==0.7.3 posthog>=2.4.0 typing-extensions>=4.5.0 \
    pulsar-client>=3.1.0 onnxruntime>=1.14.1 \
    opentelemetry-api>=1.2.0 opentelemetry-exporter-otlp-proto-grpc>=1.2.0 \
    opentelemetry-instrumentation-fastapi>=0.41b0 opentelemetry-sdk>=1.2.0 || true

# Intentar instalar tokenizers desde wheel precompilado
echo "📦 Instalando tokenizers..."
pip install "tokenizers>=0.13.2" || {
    echo "⚠️  tokenizers falló, intentando instalar Rust para compilar..."
    # Instalar Rust de forma mínima
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
    source $HOME/.cargo/env
    pip install "tokenizers>=0.13.2"
}

# Verificar que chromadb esté completo
echo "📦 Verificando ChromaDB..."
python -c "import chromadb; print('✅ ChromaDB OK')" || {
    echo "⚠️  Reinstalando chromadb completo..."
    pip uninstall -y chromadb
    pip install chromadb==0.4.18
}

# Instalar resto de dependencias
echo "📦 Instalando resto de dependencias..."
pip install fastapi uvicorn[standard] python-dotenv pydantic pydantic-settings \
    python-jose[cryptography] passlib[bcrypt] python-multipart sqlalchemy \
    requests beautifulsoup4 lxml aiohttp Pillow python-slugify email_validator apscheduler

echo "✅ Instalación completada!"

