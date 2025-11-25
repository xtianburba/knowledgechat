"""Script to migrate Krystian user to admin role"""
from database import SessionLocal, User
from sqlalchemy import text

def migrate_krystian():
    """Update Krystian user to admin role"""
    db = SessionLocal()
    try:
        # Find Krystian user
        user = db.query(User).filter(User.username == "Krystian").first()
        
        if not user:
            print("❌ Usuario 'Krystian' no encontrado")
            return
        
        # Update role and is_admin
        user.role = "admin"
        user.is_admin = True
        
        db.commit()
        print(f"✓ Usuario '{user.username}' actualizado a rol admin")
        print(f"  - Role: {user.role}")
        print(f"  - is_admin: {user.is_admin}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    print("Migrando usuario Krystian a admin...")
    migrate_krystian()

