#!/bin/bash
# Script para verificar el contenido de ChromaDB

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BACKEND_DIR="/opt/osac-knowledge-bot/backend"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Verificando Contenido de ChromaDB${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

cd "$BACKEND_DIR"

# Activar entorno virtual
source venv/bin/activate

# Script Python para verificar ChromaDB
python3 << 'PYTHON_SCRIPT'
import sys
import os
sys.path.insert(0, '/opt/osac-knowledge-bot/backend')

# Patch SQLite antes de importar chromadb
import sqlite_patch

try:
    import chromadb
    from chromadb.config import Settings as ChromaSettings
    from config import settings
    
    print("Conectando a ChromaDB...")
    client = chromadb.PersistentClient(
        path=settings.chroma_db_path,
        settings=ChromaSettings(
            anonymized_telemetry=False,
            allow_reset=True
        )
    )
    
    # Obtener la colección
    try:
        collection = client.get_collection(name="knowledge_base")
        print("✓ Colección 'knowledge_base' encontrada")
    except Exception as e:
        print(f"❌ Error al obtener la colección: {e}")
        print("  La colección no existe o está vacía")
        sys.exit(1)
    
    # Contar documentos
    count = collection.count()
    print(f"\n📊 Total de documentos en ChromaDB: {count}")
    
    if count == 0:
        print("\n⚠️  ChromaDB está VACÍA!")
        print("   No hay documentos indexados para buscar.")
        print("   Necesitas importar conocimiento desde Zendesk o añadirlo manualmente.")
        sys.exit(0)
    
    # Obtener algunos documentos de ejemplo
    print(f"\n📄 Muestra de documentos (primeros 5):")
    print("-" * 60)
    
    try:
        results = collection.get(limit=5)
        for i, (doc_id, doc, metadata) in enumerate(zip(
            results['ids'][:5] if results['ids'] else [],
            results['documents'][:5] if results['documents'] else [],
            results['metadatas'][:5] if results['metadatas'] else []
        ), 1):
            print(f"\n{i}. ID: {doc_id}")
            if metadata:
                print(f"   Título: {metadata.get('title', 'N/A')}")
                print(f"   Fuente: {metadata.get('source', 'N/A')}")
                print(f"   URL: {metadata.get('url', 'N/A')}")
            print(f"   Contenido (primeros 100 chars): {doc[:100]}...")
    except Exception as e:
        print(f"❌ Error al obtener documentos: {e}")
    
    # Probar una búsqueda
    print(f"\n🔍 Probando búsqueda con query 'procedimiento':")
    print("-" * 60)
    try:
        search_results = collection.query(
            query_texts=["procedimiento"],
            n_results=3
        )
        
        if search_results['documents'] and search_results['documents'][0]:
            print(f"✓ Se encontraron {len(search_results['documents'][0])} resultados")
            for i, (doc, metadata, distance) in enumerate(zip(
                search_results['documents'][0],
                search_results['metadatas'][0] if search_results['metadatas'] else [],
                search_results['distances'][0] if search_results['distances'] else []
            ), 1):
                print(f"\n  {i}. Distancia: {distance:.4f}")
                if metadata:
                    print(f"     Título: {metadata.get('title', 'N/A')}")
                print(f"     Contenido: {doc[:150]}...")
        else:
            print("⚠️  No se encontraron resultados")
    except Exception as e:
        print(f"❌ Error al buscar: {e}")
        import traceback
        traceback.print_exc()
    
    print("\n" + "=" * 60)
    print("✓ Verificación completada")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
PYTHON_SCRIPT

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Si ChromaDB está vacía, necesitas:"
echo "  1. Ir a 'Gestionar Conocimiento' en la web"
echo "  2. Hacer clic en 'Sincronizar con Zendesk'"
echo ""

