#!/bin/bash
# Script simple para configurar SSL - requiere información del usuario

set -e

SUBDOMAIN="osac-knowledge-bot.perfumesclub-helping.com"

echo "═══════════════════════════════════════════════════════════"
echo "  Configuración SSL/HTTPS con Let's Encrypt"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Verificar root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Por favor, ejecuta como root: sudo $0"
    exit 1
fi

# Instalar certbot
if ! command -v certbot &> /dev/null; then
    echo "📦 Instalando Certbot..."
    apt-get update
    apt-get install -y certbot python3-certbot-apache
fi

echo "✅ Certbot instalado"
echo ""

# Solicitar email (opcional, pero recomendado)
echo "Ingresa tu email para notificaciones de renovación de certificado:"
echo "(Presiona Enter para usar admin@perfumesclub.com)"
read -r EMAIL
EMAIL=${EMAIL:-admin@perfumesclub.com}

echo ""
echo "🔒 Obteniendo certificado SSL para $SUBDOMAIN..."
echo ""

# Ejecutar certbot
certbot --apache \
    -d "$SUBDOMAIN" \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    --redirect || {
    
    echo ""
    echo "⚠️  Fallo en modo no-interactivo. Ejecutando modo interactivo..."
    echo ""
    certbot --apache -d "$SUBDOMAIN"
}

echo ""
echo "✅ ¡SSL configurado exitosamente!"
echo ""
echo "La aplicación está disponible en:"
echo "  🌐 https://$SUBDOMAIN"
echo ""
echo "El certificado se renovará automáticamente."
echo ""

