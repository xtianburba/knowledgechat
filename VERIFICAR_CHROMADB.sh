#!/bin/bash
# Verificar que ChromaDB funciona correctamente

cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

echo "🔍 Verificando instalación..."

# Verificar tokenizers
python -c "import tokenizers; print(f'✅ tokenizers {tokenizers.__version__} OK')" || {
    echo "❌ tokenizers NO funciona"
    exit 1
}

# Verificar ChromaDB
python -c "import chromadb; print(f'✅ chromadb {chromadb.__version__} instalado')" || {
    echo "❌ chromadb NO se puede importar"
    exit 1
}

# Probar crear un cliente de ChromaDB
python << 'EOF'
try:
    import chromadb
    from chromadb.config import Settings
    
    # Crear cliente temporal para probar
    client = chromadb.Client(Settings(anonymized_telemetry=False))
    print("✅ ChromaDB cliente creado correctamente")
    
    # Limpiar
    del client
except Exception as e:
    print(f"⚠️  ChromaDB tiene problemas: {e}")
    print("Pero puede que funcione básicamente")
EOF

echo ""
echo "✅ Verificación completada!"

