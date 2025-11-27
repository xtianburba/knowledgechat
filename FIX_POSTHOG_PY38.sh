#!/bin/bash
# Solución para posthog incompatible con Python 3.8

set -e

echo "🔧 Solucionando problema de posthog con Python 3.8..."

cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Desinstalar posthog actual
echo "📦 Desinstalando posthog incompatible..."
pip uninstall -y posthog

# Instalar versión compatible con Python 3.8
echo "📦 Instalando posthog 2.4.0 (compatible con Python 3.8)..."
pip install --no-cache-dir "posthog==2.4.0"

echo "✅ posthog instalado"

# Verificar ChromaDB con el nuevo posthog
echo "🔍 Verificando ChromaDB..."
python << 'EOF'
import chromadb
from chromadb.config import Settings

try:
    # Intentar crear cliente con telemetría deshabilitada
    client = chromadb.Client(Settings(
        anonymized_telemetry=False,
        allow_reset=True
    ))
    print("✅ ChromaDB cliente funciona!")
    del client
except Exception as e:
    print(f"⚠️  Error: {e}")
    # Probar con PersistentClient que puede funcionar mejor
    try:
        import os
        os.makedirs("/tmp/test_chroma", exist_ok=True)
        client = chromadb.PersistentClient(
            path="/tmp/test_chroma",
            settings=Settings(
                anonymized_telemetry=False,
                allow_reset=True
            )
        )
        print("✅ ChromaDB PersistentClient funciona!")
        del client
    except Exception as e2:
        print(f"❌ También falla PersistentClient: {e2}")
EOF

echo "✅ Verificación completada!"

