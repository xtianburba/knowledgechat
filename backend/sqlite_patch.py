"""
Patch para usar pysqlite3 en lugar de sqlite3 del sistema
ChromaDB requiere SQLite >= 3.35.0, pero Ubuntu 20.04 tiene una versión más antigua
"""
import sys

# Intentar usar pysqlite3 si está disponible
try:
    import pysqlite3
    # Reemplazar sqlite3 del sistema con pysqlite3
    sys.modules['sqlite3'] = pysqlite3
except ImportError:
    # Si pysqlite3 no está instalado, usar sqlite3 del sistema
    # Esto causará un error si SQLite es demasiado antiguo
    pass

