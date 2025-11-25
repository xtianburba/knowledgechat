"""Script to add role column to users table"""
import sqlite3
import os
from pathlib import Path

def migrate_database():
    """Add role column to users table if it doesn't exist"""
    db_path = Path(__file__).parent / "knowledge_bot.db"
    
    if not db_path.exists():
        print(f"❌ Base de datos no encontrada en: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()
        
        # Check if role column already exists
        cursor.execute("PRAGMA table_info(users)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'role' in columns:
            print("✓ La columna 'role' ya existe en la tabla users")
        else:
            # Add role column
            print("Añadiendo columna 'role' a la tabla users...")
            cursor.execute("ALTER TABLE users ADD COLUMN role VARCHAR DEFAULT 'user'")
            
            # Update existing users
            # Set admin role for users with is_admin = True
            cursor.execute("UPDATE users SET role = 'admin' WHERE is_admin = 1")
            
            # Set user role for users with is_admin = False or NULL
            cursor.execute("UPDATE users SET role = 'user' WHERE role IS NULL OR role = ''")
            
            conn.commit()
            print("✓ Columna 'role' añadida exitosamente")
            print("✓ Usuarios existentes actualizados con roles apropiados")
        
        # Verify the changes
        cursor.execute("SELECT username, is_admin, role FROM users")
        users = cursor.fetchall()
        print("\nUsuarios actuales:")
        for username, is_admin, role in users:
            print(f"  - {username}: is_admin={bool(is_admin)}, role={role or 'NULL'}")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Error durante la migración: {e}")
        if conn:
            conn.rollback()
            conn.close()
        return False

if __name__ == "__main__":
    print("Ejecutando migración de base de datos...")
    print("=" * 50)
    success = migrate_database()
    print("=" * 50)
    if success:
        print("✓ Migración completada exitosamente")
    else:
        print("❌ La migración falló")

