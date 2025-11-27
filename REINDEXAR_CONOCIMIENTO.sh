#!/bin/bash
# Script para reindexar todo el conocimiento de SQLite a ChromaDB

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

BACKEND_DIR="/opt/osac-knowledge-bot/backend"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Reindexando Conocimiento en ChromaDB${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Por favor, ejecuta como root: sudo $0${NC}"
    exit 1
fi

cd "$BACKEND_DIR"

# Detener el backend
echo -e "${YELLOW}[1/4] Deteniendo backend...${NC}"
pm2 stop osac-backend 2>/dev/null || true
sleep 2
echo -e "${GREEN}✓ Backend detenido${NC}"
echo ""

# Activar entorno virtual y ejecutar script Python
echo -e "${YELLOW}[2/4] Reindexando conocimiento desde SQLite a ChromaDB...${NC}"

python3 << 'PYTHON_SCRIPT'
import sys
import os
sys.path.insert(0, '/opt/osac-knowledge-bot/backend')

# Patch SQLite
import sqlite_patch

from database import SessionLocal, KnowledgeEntry
from vector_store import get_vector_store
from slugify import slugify

print("Conectando a la base de datos...")
db = SessionLocal()

try:
    # Obtener todas las entradas de conocimiento
    entries = db.query(KnowledgeEntry).all()
    print(f"Encontradas {len(entries)} entradas de conocimiento en SQLite")
    
    if len(entries) == 0:
        print("⚠️  No hay entradas de conocimiento en la base de datos")
        print("   Necesitas importar conocimiento desde Zendesk primero")
        sys.exit(0)
    
    # Limpiar ChromaDB
    print("\nLimpiando ChromaDB...")
    try:
        vector_store = get_vector_store()
        vector_store.clear_all()
        print("✓ ChromaDB limpiada")
    except Exception as e:
        print(f"⚠️  Error al limpiar ChromaDB (puede estar vacía): {e}")
        vector_store = get_vector_store()
    
    # Reindexar todas las entradas
    print(f"\nReindexando {len(entries)} entradas...")
    indexed = 0
    errors = 0
    
    for entry in entries:
        try:
            doc_id = f"{entry.id}_{slugify(entry.title)}"
            
            vector_store.add_documents(
                documents=[entry.content or ""],
                ids=[doc_id],
                metadatas=[{
                    "title": entry.title or "",
                    "source": entry.source or "manual",
                    "entry_id": entry.id,
                    "url": entry.url or ""
                }]
            )
            indexed += 1
            
            if indexed % 10 == 0:
                print(f"  Progreso: {indexed}/{len(entries)}...")
                
        except Exception as e:
            print(f"  ⚠️  Error al indexar entrada {entry.id} ({entry.title}): {e}")
            errors += 1
    
    print(f"\n✓ Reindexación completada:")
    print(f"  - Indexadas: {indexed}")
    print(f"  - Errores: {errors}")
    
    # Verificar conteo final
    try:
        count = vector_store.collection.count()
        print(f"\n✓ Total de documentos en ChromaDB: {count}")
    except Exception as e:
        print(f"⚠️  No se pudo contar documentos: {e}")
    
finally:
    db.close()

PYTHON_SCRIPT

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error durante la reindexación${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Reindexación completada${NC}"
echo ""

# Reiniciar backend
echo -e "${YELLOW}[3/4] Reiniciando backend...${NC}"
pm2 start ecosystem.config.js --only osac-backend
pm2 save
sleep 3
echo -e "${GREEN}✓ Backend reiniciado${NC}"
echo ""

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Reindexación completada!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "Ahora prueba hacer una pregunta en el chat para verificar que funciona."
echo ""

