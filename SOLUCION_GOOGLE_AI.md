# Solución para instalar google-generativeai

El problema es que `google-generativeai` solo tiene versiones pre-release disponibles, y pip no las instala por defecto.

## Solución rápida

Ejecuta estos comandos en el servidor (dentro del venv):

```bash
cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Instalar google-generativeai primero con flag --pre
pip install --pre google-generativeai

# O instalar versión específica disponible
pip install google-generativeai==0.1.0rc1

# Luego instalar el resto de dependencias (saltará google-generativeai porque ya está instalado)
pip install -r requirements.txt
```

## Solución alternativa (usando el script)

Si prefieres usar el script automatizado:

```bash
cd /opt/osac-knowledge-bot
git pull  # Actualizar código

cd backend
source venv/bin/activate
chmod +x ../INSTALL_DEPENDENCIES.sh
../INSTALL_DEPENDENCIES.sh
```

## Verificación

Después de instalar, verifica que todo esté correcto:

```bash
pip list | grep google-generativeai
python -c "import google.generativeai as genai; print('✅ google-generativeai instalado correctamente')"
```

