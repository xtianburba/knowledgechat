#!/bin/bash
# Solución para instalar tokenizers: instalar Rust primero

set -e

echo "🔧 Instalando Rust y dependencias de compilación..."

# Instalar Rust (necesario para compilar tokenizers)
echo "📦 Instalando Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Cargar Rust en el PATH
source $HOME/.cargo/env

# Instalar dependencias de compilación
echo "📦 Instalando dependencias de compilación..."
apt-get update -qq
apt-get install -y -qq build-essential python3-dev

# Ir al backend y activar venv
cd /opt/osac-knowledge-bot/backend
source venv/bin/activate

# Actualizar pip
pip install --upgrade pip setuptools wheel

# Instalar tokenizers (ahora debería compilar correctamente)
echo "📦 Instalando tokenizers..."
pip install tokenizers

# Instalar resto de dependencias
echo "📦 Instalando resto de dependencias..."
pip install -r requirements.txt

echo "✅ Instalación completada!"

