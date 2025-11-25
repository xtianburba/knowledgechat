# OSAC Knowledge Bot - Sistema de Base de Conocimiento con IA

Sistema web de chatbot inteligente que permite a los usuarios consultar información sobre procedimientos, manuales y procesos del departamento, utilizando IA generativa (Google Gemini) y recuperación aumentada de generación (RAG).

## 🎯 Características

- ✅ Autenticación con usuario y contraseña
- ✅ Integración con Zendesk Knowledge Base
- ✅ Scraping automático de URLs para actualizar base de conocimiento
- ✅ Chat interactivo con IA (Google Gemini)
- ✅ Sistema RAG para respuestas precisas basadas en la documentación
- ✅ Gestión de base de conocimiento (añadir/actualizar contenido)
- ✅ Soporte para imágenes en los procedimientos
- ✅ Interfaz web moderna y responsive

## 🛠️ Tecnologías

- **Backend**: Python + FastAPI
- **Frontend**: React + TypeScript
- **IA**: Google Gemini API (Gratis - 60 RPM)
- **Vector Database**: ChromaDB (Open Source)
- **Autenticación**: JWT
- **Scraping**: Zendesk API + BeautifulSoup

## 📋 Requisitos Previos

- Python 3.9+
- Node.js 18+
- Servidor VPS (IONOS o similar)
- API Key de Google Gemini (gratuita)

## 🚀 Instalación

### 1. Clonar y configurar backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Configurar variables de entorno

Copia `.env.example` a `.env` y configura:

```env
# Google Gemini API (obtén tu clave en https://makersuite.google.com/app/apikey)
GEMINI_API_KEY=tu_api_key_aqui

# Zendesk (opcional, para integración directa)
ZENDESK_SUBDOMAIN=tu_subdominio
ZENDESK_EMAIL=tu_email@ejemplo.com
ZENDESK_API_TOKEN=tu_token

# JWT Secret
JWT_SECRET=tu_secret_super_seguro_aqui

# ChromaDB
CHROMA_DB_PATH=./chroma_db
```

### 3. Configurar frontend

```bash
cd frontend
npm install
```

### 4. Ejecutar aplicación

**Backend:**
```bash
cd backend
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Frontend:**
```bash
cd frontend
npm start
```

La aplicación estará disponible en `http://localhost:3000`

## 📖 Uso

### Primera vez: Crear usuario administrador

El primer usuario que se registre será automáticamente administrador.

### Añadir conocimiento desde Zendesk

1. Ve a "Gestionar Conocimiento"
2. Haz clic en "Sincronizar con Zendesk"
3. El sistema descargará automáticamente todos los artículos

### Añadir conocimiento manualmente

1. Ve a "Gestionar Conocimiento"
2. Haz clic en "Añadir Contenido"
3. Ingresa el título, contenido y URLs si es necesario
4. Sube imágenes si las hay

### Chat con el bot

1. Inicia sesión
2. Haz preguntas en el chat sobre procedimientos, condiciones de envío, etc.
3. El bot responderá basándose en la base de conocimiento

## 🔒 Seguridad

- Autenticación JWT
- Hash de contraseñas con bcrypt
- Protección CORS configurable
- Validación de entrada en todos los endpoints

## 📦 Despliegue en VPS

Ver `DEPLOYMENT.md` para instrucciones detalladas de despliegue en IONOS VPS.

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor, abre un issue o pull request.

## 📝 Licencia

MIT


