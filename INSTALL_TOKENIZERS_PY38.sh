#!/bin/bash
# Instalar versión compatible de tokenizers para Python 3.8

set -e

echo "🔧 Instalando tokenizers compatible con Python 3.8..."

cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Desinstalar completamente
echo "📦 Desinstalando tokenizers actual..."
pip uninstall -y tokenizers 2>/dev/null || true
rm -rf venv/lib/python3.8/site-packages/tokenizers* 2>/dev/null || true
pip cache purge

# Instalar versión compatible con Python 3.8
# Primero intentamos 0.10.1 (compatible con Python 3.8)
echo "📦 Instalando tokenizers 0.10.1..."
pip install --no-cache-dir "tokenizers==0.10.1"

# Verificar instalación
echo "🔍 Verificando instalación..."
python -c "import tokenizers; print(f'✅ tokenizers {tokenizers.__version__} OK')" || {
    echo "⚠️  tokenizers 0.10.1 falló, probando 0.13.2..."
    pip uninstall -y tokenizers
    pip install --no-cache-dir "tokenizers==0.13.2"
    python -c "import tokenizers; print(f'✅ tokenizers {tokenizers.__version__} OK')"
}

echo "✅ tokenizers instalado correctamente"

