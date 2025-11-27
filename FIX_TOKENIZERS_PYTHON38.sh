#!/bin/bash
# Solución para tokenizers en Python 3.8

set -e

echo "🔧 Solucionando problema de tokenizers en Python 3.8..."

cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Desinstalar tokenizers actual (incompatible)
echo "📦 Desinstalando tokenizers incompatible..."
pip uninstall -y tokenizers

# Limpiar caché de pip
pip cache purge

# Instalar versión específica compatible con Python 3.8
echo "📦 Instalando tokenizers compatible con Python 3.8..."
pip install "tokenizers==0.13.3" || pip install "tokenizers==0.14.0"

# Verificar instalación
echo "🔍 Verificando instalación..."
python -c "import tokenizers; print('✅ tokenizers OK')" || {
    echo "⚠️  Tokenizers aún falla, intentando compilar desde fuente..."
    source $HOME/.cargo/env
    pip install --no-binary tokenizers tokenizers
}

echo "✅ tokenizers instalado correctamente"

