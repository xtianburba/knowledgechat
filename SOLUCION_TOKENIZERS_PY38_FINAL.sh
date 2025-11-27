#!/bin/bash
# Solución final para tokenizers en Python 3.8
# Instalar versión compatible específica

set -e

echo "🔧 Solucionando tokenizers para Python 3.8..."

cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Asegurar que Rust está disponible
source $HOME/.cargo/env 2>/dev/null || true

# Desinstalar completamente tokenizers
echo "📦 Desinstalando tokenizers actual..."
pip uninstall -y tokenizers || true

# Limpiar completamente el caché y archivos residuales
echo "🧹 Limpiando archivos residuales..."
rm -rf venv/lib/python3.8/site-packages/tokenizers*
pip cache purge

# Instalar versión específica compatible con Python 3.8
# tokenizers 0.13.x es compatible con Python 3.8
echo "📦 Instalando tokenizers 0.13.3 (compatible con Python 3.8)..."
pip install --no-cache-dir "tokenizers==0.13.3" || {
    echo "⚠️  Versión 0.13.3 no disponible, intentando 0.14.0..."
    pip install --no-cache-dir "tokenizers==0.14.0" || {
        echo "⚠️  Versiones precompiladas fallan, compilando desde fuente..."
        pip install --no-binary tokenizers --no-cache-dir "tokenizers==0.13.3"
    }
}

echo "✅ tokenizers instalado"

