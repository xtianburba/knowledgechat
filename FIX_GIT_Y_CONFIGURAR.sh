#!/bin/bash
# Script para resolver conflictos de git y configurar Apache

set -e

echo "🔧 Resolviendo conflicto de git..."

cd /opt/osac-knowledge-bot

# Guardar cambios locales temporalmente
git stash

# Actualizar desde el repositorio
git pull

# Aplicar cambios locales de nuevo (opcional, pero probablemente no sean necesarios)
# git stash pop || true

echo "✅ Repositorio actualizado"
echo ""
echo "📦 Configurando Apache con subdominio..."

# Ejecutar el script de configuración
chmod +x CONFIGURAR_TODO_SUBDOMINIO.sh
sudo ./CONFIGURAR_TODO_SUBDOMINIO.sh

