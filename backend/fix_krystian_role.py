"""Script to fix Krystian's role in the database"""
import sqlite3
from pathlib import Path

def fix_krystian_role():
    """Fix Krystian's role in the database"""
    db_path = Path(__file__).parent / "knowledge_bot.db"
    
    if not db_path.exists():
        print(f"❌ Base de datos no encontrada en: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(str(db_path))
        cursor = conn.cursor()
        
        # Check current status
        cursor.execute("SELECT username, is_admin, role FROM users WHERE username = 'Krystian'")
        user = cursor.fetchone()
        
        if not user:
            print("❌ Usuario 'Krystian' no encontrado")
            return False
        
        print(f"Estado actual de Krystian:")
        print(f"  - Username: {user[0]}")
        print(f"  - is_admin: {user[1]}")
        print(f"  - role: {user[2]}")
        
        # Update to admin
        cursor.execute("UPDATE users SET role = 'admin', is_admin = 1 WHERE username = 'Krystian'")
        conn.commit()
        
        # Verify
        cursor.execute("SELECT username, is_admin, role FROM users WHERE username = 'Krystian'")
        user = cursor.fetchone()
        
        print(f"\n✓ Usuario actualizado:")
        print(f"  - Username: {user[0]}")
        print(f"  - is_admin: {user[1]}")
        print(f"  - role: {user[2]}")
        
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        if conn:
            conn.rollback()
            conn.close()
        return False

if __name__ == "__main__":
    print("Corrigiendo role de Krystian...")
    print("=" * 50)
    success = fix_krystian_role()
    print("=" * 50)
    if success:
        print("✓ Corrección completada exitosamente")
    else:
        print("❌ La corrección falló")

