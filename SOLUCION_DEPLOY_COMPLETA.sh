#!/bin/bash

# Solución completa para problemas de deploy

echo "=========================================="
echo "Solución Completa de Deploy"
echo "=========================================="
echo ""

cd /opt/osac-knowledge-bot

# 1. Resolver conflicto de git
echo "[1/5] Resolviendo conflictos de git..."
git stash
git pull

# 2. Verificar que requirements.txt está actualizado
echo ""
echo "[2/5] Verificando requirements.txt..."
if grep -q "google-generativeai==0.3.1" backend/requirements.txt; then
    echo "  ⚠ requirements.txt todavía tiene versión antigua, actualizando manualmente..."
    sed -i 's/google-generativeai==0.3.1/google-generativeai>=0.1.0/g' backend/requirements.txt
    echo "  ✓ Actualizado manualmente"
else
    echo "  ✓ requirements.txt ya está actualizado"
fi

# 3. Recrear entorno virtual
echo ""
echo "[3/5] Recreando entorno virtual..."
cd backend
rm -rf venv
python3 -m venv venv
source venv/bin/activate

# 4. Actualizar pip e instalar dependencias
echo ""
echo "[4/5] Instalando dependencias..."
pip install --upgrade pip setuptools wheel
pip install -r requirements.txt

# 5. Verificar instalación
echo ""
echo "[5/5] Verificando instalación..."
python3 -c "import google.generativeai; print('✓ google-generativeai instalado correctamente')" || {
    echo "  ⚠ Instalando google-generativeai manualmente..."
    pip install google-generativeai
}

echo ""
echo "=========================================="
echo "✓ Configuración del backend completada!"
echo "=========================================="
echo ""
echo "Ahora puedes continuar con:"
echo "  cd /opt/osac-knowledge-bot"
echo "  ./QUICK_DEPLOY.sh"
echo ""

