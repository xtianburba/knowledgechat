"""
Script para importar usuarios desde Zendesk
Importa usuarios con licencias: agent, agent_light, admin
y los crea en la base de datos con la contraseña por defecto: Perfumes22
"""
import requests
from typing import List, Dict
from database import SessionLocal, User, init_db
from auth import get_password_hash
from config import settings
import sys


class ZendeskUserImporter:
    """Importador de usuarios desde Zendesk"""
    
    def __init__(self):
        """Initialize Zendesk user importer"""
        self.subdomain = settings.zendesk_subdomain
        self.email = settings.zendesk_email
        self.api_token = settings.zendesk_api_token
        self.base_url = f"https://{self.subdomain}.zendesk.com/api/v2"
        
        if not all([self.subdomain, self.email, self.api_token]):
            raise ValueError("Zendesk credentials not configured in environment variables")
    
    def _make_request(self, endpoint: str, params: Dict = None) -> Dict:
        """Make authenticated request to Zendesk API"""
        url = f"{self.base_url}/{endpoint}"
        auth = (f"{self.email}/token", self.api_token)
        
        try:
            response = requests.get(url, auth=auth, params=params)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error fetching from Zendesk: {e}")
            if hasattr(e.response, 'text'):
                print(f"Response: {e.response.text}")
            raise
    
    def get_users_by_roles(self, roles: List[str]) -> List[Dict]:
        """Get users from Zendesk with specified roles and licenses"""
        all_users = []
        seen_user_ids = set()
        
        # Obtener todos los usuarios agent y admin
        # Luego filtrar por licencia: agent, agent_light, admin
        print("Obteniendo usuarios desde Zendesk...")
        
        # Obtener usuarios agent (incluye agent y agent_light)
        print("  - Obteniendo usuarios con rol 'agent'...")
        agent_users = self._get_all_users_by_role("agent")
        print(f"    Encontrados: {len(agent_users)} usuarios agent")
        
        # Obtener usuarios admin
        print("  - Obteniendo usuarios con rol 'admin'...")
        admin_users = self._get_all_users_by_role("admin")
        print(f"    Encontrados: {len(admin_users)} usuarios admin")
        
        # Combinar y filtrar
        all_users_list = agent_users + admin_users
        
        # Filtrar usuarios por licencia/role_type y eliminar duplicados
        for user in all_users_list:
            user_id = user.get("id")
            if not user_id or user_id in seen_user_ids:
                continue
            
            role = user.get("role", "").lower()
            role_type = user.get("role_type")
            active = user.get("active", True)
            suspended = user.get("suspended", False)
            
            # Solo procesar usuarios activos y no suspendidos
            if not active or suspended:
                continue
            
            # Filtrar por licencias deseadas:
            # - admin (role_type = 0 o role = "admin")
            # - agent (cualquier role_type si role = "agent")
            # - agent_light (role_type = 4, pero role = "agent")
            if role == "admin" or role_type == 0:
                # Admin
                all_users.append(user)
                seen_user_ids.add(user_id)
            elif role == "agent":
                # Incluir todos los agents (tanto normales como light)
                # role_type puede ser: 1 (agent), 4 (agent_light), o None
                all_users.append(user)
                seen_user_ids.add(user_id)
        
        print(f"Total usuarios únicos encontrados: {len(all_users)}")
        return all_users
    
    def _get_all_users_by_role(self, role: str) -> List[Dict]:
        """Get all users by role with pagination"""
        all_users = []
        page = 1
        per_page = 100
        
        while True:
            try:
                params = {
                    "per_page": per_page,
                    "page": page,
                    "role": role
                }
                
                response = self._make_request("users.json", params=params)
                users_batch = response.get("users", [])
                
                if not users_batch:
                    break
                
                all_users.extend(users_batch)
                
                # Verificar si hay más páginas
                if len(users_batch) < per_page:
                    break
                
                page += 1
                
            except Exception as e:
                print(f"    Error fetching {role} users page {page}: {e}")
                break
        
        return all_users
    
    def import_users(self, default_password: str = "Perfumes22") -> Dict:
        """Import users from Zendesk into database"""
        db = SessionLocal()
        
        try:
            # Obtener usuarios de Zendesk con roles específicos
            roles_to_import = ["admin", "agent"]
            zendesk_users = self.get_users_by_roles(roles_to_import)
            
            print(f"\nSe encontraron {len(zendesk_users)} usuarios en Zendesk")
            
            # Eliminar duplicados por ID
            unique_users = {}
            for user in zendesk_users:
                user_id = user.get("id")
                if user_id and user_id not in unique_users:
                    unique_users[user_id] = user
            
            zendesk_users = list(unique_users.values())
            print(f"Usuarios únicos: {len(zendesk_users)}")
            
            # Hash de la contraseña por defecto
            hashed_password = get_password_hash(default_password)
            
            created_count = 0
            updated_count = 0
            skipped_count = 0
            errors = []
            
            for z_user in zendesk_users:
                try:
                    email = z_user.get("email", "").strip().lower()
                    name = z_user.get("name", "").strip()
                    user_id = z_user.get("id")
                    role = z_user.get("role", "agent")
                    role_type = z_user.get("role_type", 0)  # 0=admin, 1=agent, 4=agent_light
                    active = z_user.get("active", True)
                    suspended = z_user.get("suspended", False)
                    
                    # Solo importar usuarios activos y no suspendidos
                    if not active or suspended:
                        skipped_count += 1
                        continue
                    
                    if not email:
                        skipped_count += 1
                        continue
                    
                    # Determinar username (usar email o name)
                    # Limpiar el email para crear username
                    if email:
                        username = email.split("@")[0].lower()
                        # Limpiar caracteres especiales
                        username = ''.join(c for c in username if c.isalnum() or c in ['_', '-'])
                    elif name:
                        username = name.lower().replace(" ", "_")
                        username = ''.join(c for c in username if c.isalnum() or c in ['_', '-'])
                    else:
                        skipped_count += 1
                        continue
                    
                    # Asegurar que el username no esté vacío
                    if not username:
                        skipped_count += 1
                        continue
                    
                    # Determinar rol en nuestra aplicación
                    if role == "admin" or role_type == 0:
                        app_role = "admin"
                    elif role == "agent":
                        if role_type == 4:  # agent_light -> user
                            app_role = "user"
                        else:  # agent normal (role_type == 1 o None) -> supervisor
                            app_role = "supervisor"
                    else:
                        # Si no es admin ni agent, asignar como user por defecto
                        app_role = "user"
                    
                    # Verificar si el username ya existe (puede haber conflictos)
                    username_base = username
                    username_counter = 1
                    while db.query(User).filter(User.username == username).first():
                        username = f"{username_base}{username_counter}"
                        username_counter += 1
                    
                    # Verificar si el usuario ya existe por email
                    existing_user = db.query(User).filter(User.email == email).first()
                    
                    if existing_user:
                        # Actualizar contraseña si el usuario existe
                        existing_user.hashed_password = hashed_password
                        # Solo actualizar rol si el usuario no es admin
                        if existing_user.role != "admin":
                            existing_user.role = app_role
                        updated_count += 1
                        print(f"✓ Actualizado: {username} ({email}) - Rol: {app_role}")
                    else:
                        # Crear nuevo usuario
                        new_user = User(
                            username=username,
                            email=email,
                            hashed_password=hashed_password,
                            role=app_role,
                            is_admin=(app_role == "admin")
                        )
                        db.add(new_user)
                        created_count += 1
                        print(f"✓ Creado: {username} ({email}) - Rol: {app_role}")
                
                except Exception as e:
                    error_msg = f"Error procesando usuario {z_user.get('email', 'unknown')}: {str(e)}"
                    errors.append(error_msg)
                    print(f"✗ {error_msg}")
            
            db.commit()
            
            return {
                "success": True,
                "created": created_count,
                "updated": updated_count,
                "skipped": skipped_count,
                "errors": errors,
                "total_processed": len(zendesk_users)
            }
        
        except Exception as e:
            db.rollback()
            print(f"Error general: {e}")
            return {
                "success": False,
                "error": str(e),
                "created": 0,
                "updated": 0,
                "skipped": 0,
                "errors": [str(e)]
            }
        
        finally:
            db.close()


def main():
    """Main function"""
    print("=" * 60)
    print("Importador de Usuarios desde Zendesk")
    print("=" * 60)
    
    # Verificar configuración de Zendesk
    if not all([settings.zendesk_subdomain, settings.zendesk_email, settings.zendesk_api_token]):
        print("\n❌ Error: Credenciales de Zendesk no configuradas")
        print("Por favor, configura en tu archivo .env:")
        print("  ZENDESK_SUBDOMAIN=tu_subdominio")
        print("  ZENDESK_EMAIL=tu_email@ejemplo.com")
        print("  ZENDESK_API_TOKEN=tu_token")
        sys.exit(1)
    
    # Inicializar base de datos
    print("\n📦 Inicializando base de datos...")
    init_db()
    
    # Importar usuarios
    print("\n📥 Importando usuarios desde Zendesk...")
    print("Licencias a importar: admin, agent, agent_light")
    print("Contraseña por defecto: Perfumes22\n")
    
    importer = ZendeskUserImporter()
    result = importer.import_users(default_password="Perfumes22")
    
    # Mostrar resultados
    print("\n" + "=" * 60)
    print("Resultados de la importación:")
    print("=" * 60)
    
    if result["success"]:
        print(f"✅ Usuarios creados: {result['created']}")
        print(f"🔄 Usuarios actualizados: {result['updated']}")
        print(f"⏭️  Usuarios omitidos: {result['skipped']}")
        print(f"📊 Total procesado: {result['total_processed']}")
        
        if result["errors"]:
            print(f"\n⚠️  Errores ({len(result['errors'])}):")
            for error in result["errors"]:
                print(f"   - {error}")
    else:
        print(f"❌ Error durante la importación: {result.get('error', 'Desconocido')}")
        sys.exit(1)
    
    print("\n✅ Importación completada!")


if __name__ == "__main__":
    main()

