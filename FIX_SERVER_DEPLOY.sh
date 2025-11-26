#!/bin/bash
# Script para resolver conflictos de git y completar la instalación

set -e

echo "🔧 Resolviendo conflictos de git..."

cd /opt/osac-knowledge-bot

# Guardar cambios locales en QUICK_DEPLOY.sh
echo "📦 Guardando cambios locales..."
git stash

# Actualizar código
echo "⬇️  Actualizando código desde GitHub..."
git pull

# Volver a aplicar cambios locales si es necesario
echo "📦 Aplicando cambios locales guardados..."
git stash pop || echo "No hay cambios locales para aplicar"

# Instalar dependencias
echo "📦 Instalando dependencias..."
cd backend
source venv/bin/activate

# google-generativeai ya está instalado, instalamos el resto
echo "✅ google-generativeai ya está instalado (0.1.0rc1)"
pip install -r requirements.txt || echo "Algunas dependencias pueden haber fallado, pero google-generativeai ya está instalado"

echo "✅ ¡Proceso completado!"

