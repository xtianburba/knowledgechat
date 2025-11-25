# 🚀 Guía de Deploy Rápido - OSAC Knowledge Bot

## Deploy en Servidor IONOS (82.223.20.111)

### Opción 1: Deploy Automático (Recomendado)

Conéctate al servidor y ejecuta:

```bash
ssh root@82.223.20.111

# Clonar el repositorio
cd /opt
git clone https://github.com/xtianburba/knowledgechat.git osac-knowledge-bot
cd osac-knowledge-bot

# Ejecutar deploy rápido
chmod +x QUICK_DEPLOY.sh
./QUICK_DEPLOY.sh
```

### Opción 2: Deploy Manual (Paso a Paso)

Sigue la guía completa en: **DEPLOY_IONOS.md**

## ⚠️ Configuración Requerida

**IMPORTANTE:** Después del deploy, debes configurar el archivo `.env`:

```bash
nano /opt/osac-knowledge-bot/backend/.env
```

Añade tus credenciales:

```env
GEMINI_API_KEY=tu_api_key_aqui
JWT_SECRET=genera_un_secret_seguro_de_al_menos_32_caracteres
CORS_ORIGINS=http://82.223.20.111

# Zendesk (opcional)
ZENDESK_SUBDOMAIN=tu_subdominio
ZENDESK_EMAIL=tu_email@ejemplo.com
ZENDESK_API_TOKEN=tu_token

# Paths
CHROMA_DB_PATH=/opt/osac-knowledge-bot/backend/chroma_db
UPLOAD_DIR=/opt/osac-knowledge-bot/backend/uploads
```

## 📋 Comandos Útiles

### Ver estado de aplicaciones
```bash
pm2 status
pm2 list
```

### Ver logs
```bash
pm2 logs osac-backend
pm2 logs osac-frontend
pm2 logs  # Ver todos los logs
```

### Reiniciar aplicaciones
```bash
pm2 restart osac-backend
pm2 restart osac-frontend
pm2 restart all
```

### Detener aplicaciones
```bash
pm2 stop osac-backend
pm2 stop osac-frontend
```

### Actualizar código
```bash
cd /opt/osac-knowledge-bot
git pull
cd backend && source venv/bin/activate && pip install -r requirements.txt
cd ../frontend && npm install && npm run build
pm2 restart all
```

## 🌐 Acceso

- **Frontend**: http://82.223.20.111
- **Backend API**: http://82.223.20.111/api
- **Health Check**: http://82.223.20.111/api/health

## 🔧 Troubleshooting

### Verificar que las aplicaciones están corriendo
```bash
pm2 status
netstat -tlnp | grep 8001  # Backend
netstat -tlnp | grep 3001  # Frontend
```

### Ver logs de Apache
```bash
tail -f /var/log/apache2/osac-knowledge-bot-error.log
tail -f /var/log/apache2/osac-knowledge-bot-access.log
```

### Verificar configuración de Apache
```bash
apache2ctl -S
apache2ctl configtest
```

## 📚 Documentación Completa

- **DEPLOY_IONOS.md** - Guía completa paso a paso
- **DEPLOYMENT.md** - Guía general de deployment

## ⚡ Notas Importantes

- ✅ No interfiere con tus otras aplicaciones PM2
- ✅ Usa puertos específicos (8001, 3001) para evitar conflictos
- ✅ Apache actúa como reverse proxy sin modificar configuraciones existentes
- ✅ Todas las aplicaciones PM2 se gestionan de forma unificada

