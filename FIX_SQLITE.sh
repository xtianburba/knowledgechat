#!/bin/bash
# Solución para SQLite antiguo: usar pysqlite3-binary

set -e

echo "🔧 Solucionando problema de SQLite..."

cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Instalar pysqlite3-binary que incluye SQLite >= 3.35.0
echo "📦 Instalando pysqlite3-binary..."
pip install pysqlite3-binary

# Crear un archivo de parche para usar pysqlite3 en lugar de sqlite3
echo "📝 Creando parche para usar pysqlite3..."
cat > /tmp/patch_sqlite.py << 'PYEOF'
# Parche para usar pysqlite3 en lugar de sqlite3 del sistema
import sys

# Importar pysqlite3 antes de que sqlite3 sea importado
try:
    import pysqlite3
    sys.modules['sqlite3'] = pysqlite3
except ImportError:
    pass
PYEOF

echo "✅ pysqlite3 instalado"

# Verificar ChromaDB con el parche
echo "🔍 Verificando ChromaDB..."
python << 'EOF'
# Aplicar parche primero
import sys
try:
    import pysqlite3
    sys.modules['sqlite3'] = pysqlite3
except ImportError:
    pass

import chromadb
from chromadb.config import Settings as ChromaSettings

try:
    client = chromadb.PersistentClient(
        path="/tmp/test_chroma",
        settings=ChromaSettings(
            anonymized_telemetry=False,
            allow_reset=True
        )
    )
    print("✅ ChromaDB PersistentClient funciona correctamente!")
    del client
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
EOF

echo "✅ Verificación completada!"

