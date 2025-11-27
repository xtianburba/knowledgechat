#!/bin/bash
# Solución completa para Python 3.8: usar versiones compatibles

set -e

echo "🔧 Instalando versiones compatibles con Python 3.8..."

cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Desinstalar tokenizers y chromadb actuales
echo "📦 Desinstalando versiones incompatibles..."
pip uninstall -y tokenizers chromadb 2>/dev/null || true
rm -rf venv/lib/python3.8/site-packages/tokenizers* 2>/dev/null || true
rm -rf venv/lib/python3.8/site-packages/chromadb* 2>/dev/null || true
pip cache purge

# Instalar tokenizers compatible con Python 3.8
echo "📦 Instalando tokenizers 0.10.1 (compatible con Python 3.8)..."
pip install --no-cache-dir "tokenizers==0.10.1"

# Verificar tokenizers
python -c "import tokenizers; print(f'✅ tokenizers {tokenizers.__version__} OK')" || {
    echo "⚠️  tokenizers falló, intentando 0.13.2..."
    pip uninstall -y tokenizers
    source $HOME/.cargo/env 2>/dev/null || true
    pip install --no-binary tokenizers --no-cache-dir "tokenizers==0.13.2"
}

# Instalar ChromaDB compatible (versión más antigua que funciona con Python 3.8)
echo "📦 Instalando ChromaDB 0.3.29 (compatible con Python 3.8)..."
pip install --no-cache-dir "chromadb==0.3.29" || {
    echo "⚠️  ChromaDB 0.3.29 falló, intentando 0.4.15..."
    pip install --no-cache-dir "chromadb==0.4.15"
}

# Verificar instalación
echo "🔍 Verificando instalación..."
python -c "import tokenizers; print(f'✅ tokenizers {tokenizers.__version__} OK')"
python -c "import chromadb; print(f'✅ chromadb {chromadb.__version__} OK')"

echo "✅ Instalación completada!"

