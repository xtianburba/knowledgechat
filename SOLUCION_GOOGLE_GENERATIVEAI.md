# Solución: Error con google-generativeai

El paquete `google-generativeai==0.3.1` no está disponible en PyPI. 

## Solución Rápida en el Servidor:

Ejecuta estos comandos:

```bash
cd /opt/osac-knowledge-bot

# Actualizar código
git pull

# Recrear entorno virtual
cd backend
rm -rf venv
python3 -m venv venv
source venv/bin/activate

# Actualizar pip
pip install --upgrade pip

# Instalar dependencias (ahora con versión flexible)
pip install -r requirements.txt
```

Si sigue fallando, instala manualmente:

```bash
cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Instalar versión más reciente
pip install google-generativeai

# O instalar todas las dependencias manualmente
pip install fastapi uvicorn python-dotenv pydantic pydantic-settings python-jose[cryptography] passlib[bcrypt] python-multipart sqlalchemy chromadb google-generativeai requests beautifulsoup4 aiohttp Pillow python-slugify email_validator apscheduler
```

## Continuar el Deploy

Después de instalar las dependencias:

```bash
cd /opt/osac-knowledge-bot
./QUICK_DEPLOY.sh
```

El script continuará desde donde se quedó.

