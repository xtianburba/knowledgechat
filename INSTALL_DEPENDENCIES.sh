#!/bin/bash
# Script para instalar dependencias del backend, incluyendo google-generativeai

set -e

echo "📦 Instalando google-generativeai (permitiendo pre-release)..."
pip install --pre google-generativeai || pip install google-generativeai==0.1.0rc1

echo "📦 Instalando resto de dependencias..."
pip install -r requirements.txt

echo "✅ Dependencias instaladas correctamente!"

