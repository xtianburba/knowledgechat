#!/usr/bin/env python3
"""Script para crear un usuario en la base de datos"""

import sys
import os

# Añadir el directorio actual al path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Patch SQLite antes de cualquier otra importación
import sqlite_patch

from database import SessionLocal, User, init_db
from auth import get_password_hash
from sqlalchemy.exc import IntegrityError

def crear_usuario(username: str, email: str, password: str, role: str = "admin"):
    """Crear un usuario en la base de datos"""
    # Inicializar base de datos
    init_db()
    
    db = SessionLocal()
    try:
        # Verificar si el usuario ya existe
        existing_user = db.query(User).filter(User.username == username).first()
        if existing_user:
            print(f"❌ El usuario '{username}' ya existe en la base de datos.")
            print(f"   Email: {existing_user.email}")
            print(f"   Rol: {existing_user.role}")
            return False
        
        # Verificar si el email ya existe
        existing_email = db.query(User).filter(User.email == email).first()
        if existing_email:
            print(f"❌ El email '{email}' ya está en uso por el usuario '{existing_email.username}'.")
            return False
        
        # Crear nuevo usuario
        hashed_password = get_password_hash(password)
        new_user = User(
            username=username,
            email=email,
            hashed_password=hashed_password,
            role=role,
            is_admin=(role == "admin")
        )
        
        db.add(new_user)
        db.commit()
        db.refresh(new_user)
        
        print(f"✅ Usuario creado exitosamente:")
        print(f"   Usuario: {new_user.username}")
        print(f"   Email: {new_user.email}")
        print(f"   Rol: {new_user.role}")
        print(f"   Admin: {'Sí' if new_user.is_admin else 'No'}")
        return True
        
    except IntegrityError as e:
        db.rollback()
        print(f"❌ Error de integridad: {e}")
        return False
    except Exception as e:
        db.rollback()
        print(f"❌ Error al crear usuario: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        db.close()

def listar_usuarios():
    """Listar todos los usuarios en la base de datos"""
    db = SessionLocal()
    try:
        usuarios = db.query(User).all()
        if not usuarios:
            print("No hay usuarios en la base de datos.")
            return
        
        print(f"\n📋 Usuarios en la base de datos ({len(usuarios)}):\n")
        for usuario in usuarios:
            print(f"  - {usuario.username} ({usuario.email})")
            print(f"    Rol: {usuario.role} | Admin: {'Sí' if usuario.is_admin else 'No'}")
            print()
    finally:
        db.close()

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Uso: python crear_usuario.py <username> <email> <password> [role]")
        print("\nEjemplo:")
        print("  python crear_usuario.py Krystian krystian@example.com Perfumes22 admin")
        print("\nRoles disponibles: admin, supervisor, user")
        print("\nPara listar usuarios existentes:")
        print("  python crear_usuario.py --list")
        sys.exit(1)
    
    if sys.argv[1] == "--list":
        listar_usuarios()
        sys.exit(0)
    
    username = sys.argv[1]
    email = sys.argv[2]
    password = sys.argv[3]
    role = sys.argv[4] if len(sys.argv) > 4 else "admin"
    
    if role not in ["admin", "supervisor", "user"]:
        print(f"❌ Rol inválido: {role}")
        print("Roles válidos: admin, supervisor, user")
        sys.exit(1)
    
    print(f"Creando usuario '{username}'...")
    success = crear_usuario(username, email, password, role)
    
    if success:
        sys.exit(0)
    else:
        sys.exit(1)

