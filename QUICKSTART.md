# Inicio Rápido - OSAC Knowledge Bot

## ⚡ Pasos Rápidos para Empezar

### 1. Obtener API Key de Gemini (5 minutos)

1. Ve a https://makersuite.google.com/app/apikey
2. Inicia sesión con tu cuenta de Google
3. Haz clic en "Create API Key"
4. Copia la clave generada

### 2. Configurar Backend (5 minutos)

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# Linux/Mac
source venv/bin/activate

pip install -r requirements.txt
```

Crea archivo `.env` en `backend/`:

```env
GEMINI_API_KEY=tu_api_key_de_gemini_aqui
JWT_SECRET=genera_un_secret_seguro_aqui
CORS_ORIGINS=http://localhost:3000,http://localhost:8000
```

Inicia el servidor:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 3. Configurar Frontend (3 minutos)

```bash
cd frontend
npm install
npm start
```

El navegador se abrirá en `http://localhost:3000`

### 4. Primera Configuración (2 minutos)

1. **Registrar el primer usuario** (será admin automáticamente):
   - Ve a http://localhost:3000/register
   - Completa el formulario

2. **Añadir conocimiento**:
   - Inicia sesión
   - Ve a "Gestionar Conocimiento"
   - Añade contenido manualmente o sincroniza con Zendesk

3. **Probar el chat**:
   - Ve a "Chat"
   - Haz una pregunta sobre el conocimiento añadido

## 📚 Documentación Completa

- **SETUP.md**: Guía detallada de configuración
- **DEPLOYMENT.md**: Guía de despliegue en VPS de IONOS
- **PROPUESTA_SOLUCION.md**: Resumen ejecutivo de la solución

## 🔧 Configuración de Zendesk (Opcional)

Si quieres sincronizar automáticamente con Zendesk:

1. Ve a tu panel de Zendesk: `https://tu-subdominio.zendesk.com/admin/apps-integrations/apis/zendesk-api`
2. Genera un API Token
3. Añade a tu `.env`:

```env
ZENDESK_SUBDOMAIN=tu_subdominio
ZENDESK_EMAIL=tu_email@ejemplo.com
ZENDESK_API_TOKEN=tu_token
```

4. En la interfaz web, haz clic en "Sincronizar con Zendesk"

## ✅ Verificar que Todo Funciona

1. Backend corriendo: http://localhost:8000/api/health
2. Frontend corriendo: http://localhost:3000
3. Puedes registrarte e iniciar sesión
4. Puedes añadir conocimiento
5. El chat responde correctamente

## 🚨 Problemas Comunes

**Error: "GEMINI_API_KEY is not set"**
- Verifica que el archivo `.env` existe en `backend/`
- Verifica que la variable esté correctamente configurada
- Reinicia el servidor backend

**Error de CORS**
- Asegúrate de que `CORS_ORIGINS` en `.env` incluya `http://localhost:3000`
- Reinicia el servidor backend

**El chat no responde**
- Verifica que el backend esté corriendo
- Verifica que tengas contenido en la base de conocimiento
- Revisa los logs del backend

## 🎉 ¡Listo!

Ya tienes tu sistema funcionando. Para desplegar en producción, consulta `DEPLOYMENT.md`.


