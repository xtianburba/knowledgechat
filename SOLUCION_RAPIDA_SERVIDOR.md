# Solución Rápida para Completar Instalación en Servidor

## Situación Actual
- ✅ `google-generativeai` ya está instalado correctamente (0.1.0rc1)
- ❌ `requirements.txt` en el servidor tiene versión antigua porque `git pull` falló
- ⚠️ Hay cambios locales en `QUICK_DEPLOY.sh` que bloquean el `git pull`

## Solución Rápida (Opción 1) - Recomendada

Instalar todas las dependencias manualmente, excepto `google-generativeai`:

```bash
cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

pip install fastapi uvicorn[standard] python-dotenv pydantic pydantic-settings python-jose[cryptography] passlib[bcrypt] python-multipart sqlalchemy chromadb requests beautifulsoup4 lxml aiohttp Pillow python-slugify email_validator apscheduler
```

## Solución Completa (Opción 2)

Resolver el conflicto de git y actualizar:

```bash
cd /opt/osac-knowledge-bot
git stash                    # Guardar cambios locales
git pull                     # Actualizar código
cd backend
source venv/bin/activate
pip install -r requirements.txt
```

## Usar Script Automático

```bash
cd /opt/osac-knowledge-bot
git pull                     # Actualizar para obtener FIX_SERVER_DEPLOY.sh
chmod +x FIX_SERVER_DEPLOY.sh
./FIX_SERVER_DEPLOY.sh
```

## Verificación

Después de instalar, verifica que todo esté correcto:

```bash
pip list | grep google-generativeai
python -c "import google.generativeai as genai; print('✅ OK')"
```

