# Solución Manual para Python 3.8

El problema es que **Python 3.8 es demasiado antiguo**. ChromaDB 0.3.29 requiere `tokenizers>=0.13.2`, pero las versiones recientes de tokenizers requieren Python 3.9+.

## Solución Manual (Paso a Paso)

Ejecuta estos comandos en el servidor SSH:

```bash
cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# 1. Limpiar todo
pip uninstall -y chromadb tokenizers
rm -rf venv/lib/python3.8/site-packages/tokenizers* venv/lib/python3.8/site-packages/chromadb*
pip cache purge

# 2. Instalar tokenizers 0.10.1 (compatible con Python 3.8)
pip install --no-cache-dir "tokenizers==0.10.1"

# Verificar que funciona
python -c "import tokenizers; print('✅ tokenizers OK')"

# 3. Instalar ChromaDB SIN sus dependencias (para evitar que actualice tokenizers)
pip install --no-deps --no-cache-dir "chromadb==0.3.29"

# 4. Instalar dependencias de ChromaDB manualmente (EXCEPTO tokenizers)
pip install --no-cache-dir \
    "pandas>=1.3" \
    "requests>=2.28" \
    "pydantic>=1.9,<2.0" \
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

# 5. Verificar (puede tener advertencias pero debería funcionar)
python -c "import chromadb; print('✅ chromadb instalado')"
```

## Nota Importante

⚠️ **Hay conflictos de versiones**:
- `pydantic-settings 2.8.1` requiere `pydantic>=2.7.0`
- ChromaDB 0.3.29 requiere `pydantic<2.0,>=1.9`

Esto puede causar problemas. La **solución recomendada es actualizar Python a 3.9+** en el servidor.

## Solución Alternativa: Actualizar Python

Si puedes, actualizar Python sería lo mejor:

```bash
# Instalar Python 3.9 o superior
apt-get update
apt-get install -y python3.9 python3.9-venv

# Recrear el venv con Python 3.9
cd /opt/osac-knowledge-bot/backend
rm -rf venv
python3.9 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

