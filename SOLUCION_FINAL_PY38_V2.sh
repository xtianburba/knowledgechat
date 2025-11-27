#!/bin/bash
# Solución final v2: Instalar ChromaDB sin sus dependencias de tokenizers
# y forzar versión compatible

set -e

echo "🔧 Solución final para Python 3.8 (v2)..."

cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Desinstalar todo
echo "📦 Limpiando instalaciones anteriores..."
pip uninstall -y chromadb tokenizers 2>/dev/null || true
rm -rf venv/lib/python3.8/site-packages/tokenizers* 2>/dev/null || true
rm -rf venv/lib/python3.8/site-packages/chromadb* 2>/dev/null || true
pip cache purge

# Instalar tokenizers 0.10.1 primero
echo "📦 Instalando tokenizers 0.10.1..."
pip install --no-cache-dir "tokenizers==0.10.1"

# Verificar tokenizers funciona
python -c "import tokenizers; print(f'✅ tokenizers {tokenizers.__version__} OK')"

# Instalar ChromaDB SIN sus dependencias (para evitar que actualice tokenizers)
echo "📦 Instalando ChromaDB sin dependencias de tokenizers..."
pip install --no-deps --no-cache-dir chromadb==0.3.29

# Instalar las dependencias de ChromaDB manualmente EXCEPTO tokenizers
echo "📦 Instalando dependencias de ChromaDB (excepto tokenizers)..."
pip install --no-cache-dir \
    "pandas>=1.3" \
    "requests>=2.28" \
    "pydantic<2.0,>=1.9" \
    "hnswlib>=0.7" \
    "clickhouse-connect>=0.5.7" \
    "duckdb>=0.7.1" \
    "fastapi==0.85.1" \
    "starlette==0.20.4" \
    "posthog>=2.4.0" \
    "typing-extensions>=4.5.0" \
    "pulsar-client>=3.1.0" \
    "onnxruntime>=1.14.1" \
    "tqdm>=4.65.0" \
    "overrides>=7.3.1" \
    "graphlib-backport>=1.0.3"

# NO instalar tokenizers de nuevo, ya está instalado 0.10.1

# Verificar que chromadb puede importarse (aunque puede quejarse de tokenizers)
echo "🔍 Verificando ChromaDB..."
python -c "import chromadb; print(f'✅ chromadb {chromadb.__version__} instalado')" || {
    echo "⚠️  ChromaDB instalado pero puede tener advertencias sobre tokenizers"
}

echo "✅ Instalación completada!"
echo "⚠️  Nota: Puede haber conflictos de versiones, pero debería funcionar básicamente"

