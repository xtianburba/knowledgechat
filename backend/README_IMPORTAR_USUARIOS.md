# Importar Usuarios desde Zendesk

Este script importa automáticamente usuarios desde Zendesk y los crea en la base de datos de la aplicación con la contraseña por defecto `Perfumes22`.

## Usuarios que se importan

El script importa usuarios con las siguientes licencias de Zendesk:
- **Admin** → Rol: `admin` en la aplicación
- **Agent** → Rol: `supervisor` en la aplicación
- **Agent Light** → Rol: `user` en la aplicación

## Requisitos previos

1. **Credenciales de Zendesk configuradas** en el archivo `.env`:
   ```env
   ZENDESK_SUBDOMAIN=tu_subdominio
   ZENDESK_EMAIL=tu_email@ejemplo.com
   ZENDESK_API_TOKEN=tu_token
   ```

2. **Base de datos inicializada**: El script inicializa las tablas automáticamente.

## Ejecutar el script

### Windows:
```bash
cd backend
venv\Scripts\activate
python import_users_from_zendesk.py
```

### Linux/Mac:
```bash
cd backend
source venv/bin/activate
python import_users_from_zendesk.py
```

## ¿Qué hace el script?

1. ✅ Se conecta a la API de Zendesk
2. ✅ Obtiene todos los usuarios con licencias: admin, agent, agent_light
3. ✅ Filtra solo usuarios activos y no suspendidos
4. ✅ Crea usuarios en la base de datos con:
   - **Username**: Parte del email antes del @ (o nombre si no hay email)
   - **Email**: Email del usuario en Zendesk
   - **Contraseña**: `Perfumes22` (igual para todos)
   - **Rol**: Según la licencia en Zendesk

5. ✅ **No duplica usuarios**: Si un usuario ya existe (por email), actualiza su contraseña y rol (excepto si ya es admin)

## Mapeo de roles

| Licencia Zendesk | Rol en la aplicación | Permisos |
|-----------------|---------------------|----------|
| Admin | `admin` | Acceso completo (gestión de usuarios, conocimiento, informes) |
| Agent | `supervisor` | Chat + gestión de conocimiento + informes |
| Agent Light | `user` | Solo chat |

## Resultado

El script mostrará:
- ✅ Usuarios creados
- 🔄 Usuarios actualizados (si ya existían)
- ⏭️ Usuarios omitidos (inactivos, suspendidos, sin email)
- ⚠️ Errores (si los hay)

## Notas importantes

⚠️ **Contraseña por defecto**: Todos los usuarios importados tendrán la contraseña `Perfumes22`. Se recomienda que los usuarios cambien su contraseña después del primer inicio de sesión (esto requeriría implementar un sistema de cambio de contraseña).

⚠️ **Usuarios existentes**: Si un usuario ya existe en la base de datos (mismo email), el script:
- Actualizará su contraseña a `Perfumes22`
- Actualizará su rol (a menos que ya sea admin)

⚠️ **Usernames duplicados**: Si hay conflictos de username, el script añadirá un número al final (ej: `usuario1`, `usuario2`, etc.)

## Solución de problemas

### Error: "Zendesk credentials not configured"
- Verifica que el archivo `.env` tenga las credenciales correctas
- Asegúrate de estar en el directorio `backend` al ejecutar el script

### Error: "Error fetching from Zendesk"
- Verifica que las credenciales de Zendesk sean correctas
- Verifica que el API token tenga permisos para leer usuarios
- Verifica tu conexión a internet

### No se importan usuarios
- Verifica que haya usuarios activos en Zendesk con las licencias especificadas
- Revisa los mensajes de "Usuarios omitidos" para ver por qué se omitieron

