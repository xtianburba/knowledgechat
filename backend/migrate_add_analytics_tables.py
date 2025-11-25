"""Script to add analytics tables to database"""
import sqlite3
from pathlib import Path

def migrate_analytics_tables():
    """Add ChatInteraction and DocumentUsageStats tables"""
    db_path = Path(__file__).parent / "knowledge_bot.db"
    
    if not db_path.exists():
        print(f"❌ Base de datos no encontrada en: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()
        
        # Check if tables exist
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='chat_interactions'")
        chat_table_exists = cursor.fetchone() is not None
        
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='document_usage_stats'")
        stats_table_exists = cursor.fetchone() is not None
        
        # Create chat_interactions table
        if not chat_table_exists:
            print("Creando tabla chat_interactions...")
            cursor.execute("""
                CREATE TABLE chat_interactions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER NOT NULL,
                    question TEXT NOT NULL,
                    response_preview TEXT,
                    documents_used TEXT,
                    response_time_ms INTEGER,
                    context_count INTEGER DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            cursor.execute("CREATE INDEX idx_chat_interactions_user_id ON chat_interactions(user_id)")
            cursor.execute("CREATE INDEX idx_chat_interactions_created_at ON chat_interactions(created_at)")
            print("✓ Tabla chat_interactions creada")
        else:
            print("✓ Tabla chat_interactions ya existe")
        
        # Create document_usage_stats table
        if not stats_table_exists:
            print("Creando tabla document_usage_stats...")
            cursor.execute("""
                CREATE TABLE document_usage_stats (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    knowledge_entry_id INTEGER NOT NULL UNIQUE,
                    times_used INTEGER DEFAULT 0,
                    last_used_at TIMESTAMP,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            cursor.execute("CREATE INDEX idx_doc_stats_entry_id ON document_usage_stats(knowledge_entry_id)")
            print("✓ Tabla document_usage_stats creada")
        else:
            print("✓ Tabla document_usage_stats ya existe")
        
        conn.commit()
        conn.close()
        
        print("\n✓ Migración completada exitosamente")
        return True
        
    except Exception as e:
        print(f"❌ Error durante la migración: {e}")
        if conn:
            conn.rollback()
            conn.close()
        return False

if __name__ == "__main__":
    print("Ejecutando migración de tablas de analytics...")
    print("=" * 50)
    success = migrate_analytics_tables()
    print("=" * 50)
    if success:
        print("✓ Todas las tablas están listas")
    else:
        print("❌ La migración falló")

