# Guía de Configuración Inicial - OSAC Knowledge Bot

Esta guía te ayudará a configurar el sistema por primera vez.

## Paso 1: Obtener API Key de Google Gemini (Gratis)

1. Ve a [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Inicia sesión con tu cuenta de Google
3. Haz clic en "Create API Key"
4. Copia la clave generada
5. **Nota**: La API de Gemini tiene un límite gratuito de 60 solicitudes por minuto

## Paso 2: Configurar Zendesk (Opcional)

Si quieres sincronizar con Zendesk, necesitas:

1. Ve a tu panel de Zendesk: `https://tu-subdominio.zendesk.com/admin/apps-integrations/apis/zendesk-api`
2. Genera un API Token
3. Anota:
   - Tu subdominio de Zendesk (ejemplo: si tu URL es `https://miempresa.zendesk.com`, el subdominio es `miempresa`)
   - Tu email de Zendesk
   - El API Token generado

## Paso 3: Configurar Backend

1. Ve a la carpeta `backend`:
   ```bash
   cd backend
   ```

2. Crea un entorno virtual:
   ```bash
   python -m venv venv
   # En Windows:
   venv\Scripts\activate
   # En Linux/Mac:
   source venv/bin/activate
   ```

3. Instala las dependencias:
   ```bash
   pip install -r requirements.txt
   ```

4. Crea el archivo `.env`:
   ```bash
   # En Linux/Mac
   cp .env.example .env
   # En Windows
   copy .env.example .env
   ```

5. Edita el archivo `.env` con tus credenciales:
   ```env
   # OBLIGATORIO: Tu API Key de Gemini
   GEMINI_API_KEY=tu_api_key_de_gemini_aqui

   # OPCIONAL: Si quieres usar Zendesk
   ZENDESK_SUBDOMAIN=tu_subdominio
   ZENDESK_EMAIL=tu_email@ejemplo.com
   ZENDESK_API_TOKEN=tu_token

   # IMPORTANTE: Cambia este secret por uno seguro
   JWT_SECRET=genera_un_secret_super_seguro_aqui

   # Configuración de base de datos
   CHROMA_DB_PATH=./chroma_db

   # CORS (para desarrollo)
   CORS_ORIGINS=http://localhost:3000,http://localhost:8000
   ```

   **Generar un JWT_SECRET seguro:**
   ```bash
   # En Linux/Mac
   openssl rand -hex 32
   
   # En Windows (PowerShell)
   [Convert]::ToBase64String((1..32 | ForEach-Object { Get-Random -Maximum 256 }))
   ```

6. Inicializa la base de datos (se creará automáticamente al iniciar el servidor):
   ```bash
   python -c "from database import init_db; init_db()"
   ```

7. Inicia el servidor backend:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

   Deberías ver algo como:
   ```
   INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
   INFO:     Started reloader process
   INFO:     Started server process
   INFO:     Waiting for application startup.
   ```

## Paso 4: Configurar Frontend

1. Abre una nueva terminal y ve a la carpeta `frontend`:
   ```bash
   cd frontend
   ```

2. Instala las dependencias:
   ```bash
   npm install
   ```

3. (Opcional) Si tu backend está en un puerto diferente o servidor remoto, configura la URL:
   - Edita `package.json` y cambia el proxy si es necesario
   - O configura variables de entorno

4. Inicia el servidor de desarrollo:
   ```bash
   npm start
   ```

   El navegador debería abrirse automáticamente en `http://localhost:3000`

## Paso 5: Primera Configuración

1. **Registrar el primer usuario (será administrador automáticamente)**:
   - Ve a `http://localhost:3000`
   - Haz clic en "Registrarse"
   - Completa el formulario
   - El primer usuario será automáticamente administrador

2. **Sincronizar con Zendesk (si lo configuraste)**:
   - Inicia sesión con tu cuenta
   - Ve a "Gestionar Conocimiento" (solo visible para admins)
   - Haz clic en "Sincronizar con Zendesk"
   - Espera a que termine (puede tardar varios minutos dependiendo de cuántos artículos tengas)

3. **Añadir conocimiento manualmente**:
   - Ve a "Gestionar Conocimiento"
   - Haz clic en "Añadir Contenido Manual"
   - Completa el formulario con título y contenido
   - Opcionalmente añade una URL

4. **Probar el chat**:
   - Ve a "Chat"
   - Haz una pregunta sobre el conocimiento que has añadido
   - El bot debería responder basándose en tu base de conocimiento

## Paso 6: Añadir Más Usuarios

Otros usuarios del departamento pueden:

1. Ir a `http://localhost:3000/register`
2. Registrarse con su username y email
3. Iniciar sesión y usar el chat
4. Solo los administradores pueden gestionar la base de conocimiento

## Solución de Problemas

### Error: "GEMINI_API_KEY is not set"
- Asegúrate de que el archivo `.env` existe en la carpeta `backend`
- Verifica que la variable `GEMINI_API_KEY` esté correctamente configurada
- Reinicia el servidor backend

### Error: "Could not validate credentials"
- Tu token JWT expiró o es inválido
- Cierra sesión y vuelve a iniciar sesión

### Error al sincronizar con Zendesk
- Verifica que las credenciales de Zendesk en `.env` sean correctas
- Verifica que tu cuenta de Zendesk tenga acceso a la API
- Revisa los logs del backend para más detalles

### El chat no responde
- Verifica que el backend esté corriendo
- Verifica que tengas contenido en la base de conocimiento
- Revisa los logs del backend para errores

### Error de CORS
- Verifica que `CORS_ORIGINS` en `.env` incluya la URL de tu frontend
- Reinicia el servidor backend

## Próximos Pasos

1. **Despliegue en Producción**: Consulta `DEPLOYMENT.md` para desplegar en tu VPS de IONOS
2. **Configurar Backup**: Configura backups regulares de la base de datos
3. **Personalizar**: Ajusta los prompts y estilos según tus necesidades
4. **Añadir Más Fuentes**: Extiende el sistema para añadir más fuentes de conocimiento

## Recursos Adicionales

- [Documentación de Google Gemini](https://ai.google.dev/docs)
- [Documentación de Zendesk API](https://developer.zendesk.com/api-reference/)
- [Documentación de ChromaDB](https://docs.trychroma.com/)

¡Listo! Ya tienes tu sistema de base de conocimiento con IA funcionando.


