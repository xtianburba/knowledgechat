#!/bin/bash
# Solución simple: instalar tokenizers manualmente primero

set -e

echo "🔧 Solución simple para tokenizers..."

cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Actualizar pip
pip install --upgrade pip setuptools wheel

# Instalar dependencias de compilación básicas
echo "📦 Instalando herramientas de compilación..."
apt-get update -qq
apt-get install -y -qq build-essential python3-dev pkg-config libssl-dev 2>/dev/null || echo "Algunos paquetes pueden no estar disponibles"

# Intentar instalar tokenizers desde una versión precompilada específica
echo "📦 Instalando tokenizers..."
pip install "tokenizers>=0.13.2,<0.15.0" || {
    echo "⚠️  Intentando instalar tokenizers sin especificar versión..."
    pip install tokenizers
}

# Ahora instalar chromadb sin las dependencias que ya tenemos
echo "📦 Instalando ChromaDB..."
pip install chromadb==0.4.18 || {
    echo "⚠️  ChromaDB con dependencias falló, instalando manualmente..."
    # Instalar chromadb sin sus dependencias de tokenizers
    pip install --no-deps chromadb==0.4.18
    # Instalar dependencias de chromadb manualmente excepto tokenizers
    pip install chroma-hnswlib==0.7.3 posthog>=2.4.0 typing-extensions>=4.5.0 pulsar-client>=3.1.0 onnxruntime>=1.14.1 opentelemetry-api>=1.2.0 opentelemetry-exporter-otlp-proto-grpc>=1.2.0 opentelemetry-instrumentation-fastapi>=0.41b0 opentelemetry-sdk>=1.2.0
}

# Instalar resto de dependencias
echo "📦 Instalando resto de dependencias..."
pip install fastapi uvicorn[standard] python-dotenv pydantic pydantic-settings python-jose[cryptography] passlib[bcrypt] python-multipart sqlalchemy requests beautifulsoup4 lxml aiohttp Pillow python-slugify email_validator apscheduler

echo "✅ Instalación completada!"

