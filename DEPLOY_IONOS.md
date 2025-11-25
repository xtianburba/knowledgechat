# Deploy OSAC Knowledge Bot - Servidor IONOS (82.223.20.111)

**⚠️ IMPORTANTE: Este script NO modificará ni interferirá con tus aplicaciones existentes que usan Apache y PM2**

## Información del Servidor

- **IP**: 82.223.20.111
- **Usuario**: root
- **GitHub Repo**: https://github.com/xtianburba/knowledgechat
- **Aplicaciones existentes**: 4 aplicaciones con PM2 + Apache

## Estrategia de Deploy Seguro

1. ✅ Usaremos PM2 (como tus otras apps) para backend y frontend
2. ✅ Apache como reverse proxy (sin tocar configuraciones existentes)
3. ✅ Puertos específicos: Backend 8001, Frontend 3001 (para evitar conflictos)
4. ✅ Instalación en `/opt/osac-knowledge-bot` (separado de otras apps)

## Pasos de Deploy

### Paso 1: Conectar al Servidor

```bash
ssh root@82.223.20.111
```

### Paso 2: Ejecutar Script de Deploy Automático

Una vez conectado, ejecuta:

```bash
curl -fsSL https://raw.githubusercontent.com/xtianburba/knowledgechat/main/deploy.sh | bash
```

O manualmente:

```bash
# Clonar el repo
cd /opt
git clone https://github.com/xtianburba/knowledgechat.git osac-knowledge-bot
cd osac-knowledge-bot

# Ejecutar script de deploy
chmod +x deploy.sh
./deploy.sh
```

### Paso 3: Configurar Variables de Entorno

Después del deploy, configura el archivo `.env`:

```bash
nano /opt/osac-knowledge-bot/backend/.env
```

Añade tus credenciales:

```env
GEMINI_API_KEY=tu_api_key_aqui
JWT_SECRET=genera_un_secret_seguro_aqui_minimo_32_caracteres
CORS_ORIGINS=http://82.223.20.111,http://82.223.20.111:3001

# Zendesk (opcional)
ZENDESK_SUBDOMAIN=tu_subdominio
ZENDESK_EMAIL=tu_email@ejemplo.com
ZENDESK_API_TOKEN=tu_token

# Paths
CHROMA_DB_PATH=/opt/osac-knowledge-bot/backend/chroma_db
UPLOAD_DIR=/opt/osac-knowledge-bot/backend/uploads

# Base de datos SQLite (ruta absoluta)
DATABASE_URL=sqlite:////opt/osac-knowledge-bot/backend/knowledge_bot.db
```

### Paso 4: Iniciar Aplicaciones con PM2

```bash
# Iniciar backend
cd /opt/osac-knowledge-bot
pm2 start ecosystem.config.js --only backend

# Iniciar frontend
pm2 start ecosystem.config.js --only frontend

# Ver estado
pm2 status

# Ver logs
pm2 logs osac-backend
pm2 logs osac-frontend

# Guardar configuración PM2 (para que se inicien automáticamente)
pm2 save
pm2 startup
```

### Paso 5: Configurar Apache como Reverse Proxy

Crea el archivo de configuración de Apache:

```bash
nano /etc/apache2/sites-available/osac-knowledge-bot.conf
```

Contenido:

```apache
<VirtualHost *:80>
    ServerName 82.223.20.111
    ServerAlias osac-knowledge-bot.local
    
    # Logs
    ErrorLog ${APACHE_LOG_DIR}/osac-knowledge-bot-error.log
    CustomLog ${APACHE_LOG_DIR}/osac-knowledge-bot-access.log combined
    
    # Frontend (React)
    ProxyPreserveHost On
    ProxyPass / http://localhost:3001/
    ProxyPassReverse / http://localhost:3001/
    
    # Backend API
    ProxyPass /api http://localhost:8001/api
    ProxyPassReverse /api http://localhost:8001/api
    
    # Headers para CORS y WebSockets
    <Location />
        Header set Access-Control-Allow-Origin "*"
        Header set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"
        Header set Access-Control-Allow-Headers "Content-Type, Authorization"
    </Location>
</VirtualHost>
```

Activa el sitio:

```bash
# Habilitar módulos necesarios de Apache
a2enmod proxy
a2enmod proxy_http
a2enmod headers
a2enmod rewrite

# Habilitar el sitio
a2ensite osac-knowledge-bot.conf

# Verificar configuración
apache2ctl configtest

# Recargar Apache (NO reinicia, solo recarga)
systemctl reload apache2
```

### Paso 6: Verificar que Todo Funciona

```bash
# Ver estado de PM2
pm2 status

# Ver logs
pm2 logs

# Probar backend directamente
curl http://localhost:8001/api/health

# Probar frontend directamente
curl http://localhost:3001
```

### Paso 7: Acceder a la Aplicación

Abre tu navegador y ve a:
- **http://82.223.20.111** (a través de Apache)
- O directamente: **http://82.223.20.111:3001** (frontend) y **http://82.223.20.111:8001/api/health** (backend)

## Comandos Útiles

### PM2 - Gestión de Aplicaciones

```bash
# Ver todas las aplicaciones PM2 (incluye tus otras apps)
pm2 list

# Ver solo las aplicaciones de OSAC
pm2 list | grep osac

# Reiniciar aplicaciones
pm2 restart osac-backend
pm2 restart osac-frontend

# Detener aplicaciones
pm2 stop osac-backend
pm2 stop osac-frontend

# Ver logs en tiempo real
pm2 logs osac-backend --lines 50
pm2 logs osac-frontend --lines 50

# Eliminar aplicaciones (si es necesario)
pm2 delete osac-backend
pm2 delete osac-frontend
```

### Actualizar Código

```bash
cd /opt/osac-knowledge-bot
git pull origin main

# Backend
cd backend
source venv/bin/activate
pip install -r requirements.txt
pm2 restart osac-backend

# Frontend
cd ../frontend
npm install
npm run build
pm2 restart osac-frontend
```

### Verificar Logs

```bash
# Logs de Apache
tail -f /var/log/apache2/osac-knowledge-bot-error.log
tail -f /var/log/apache2/osac-knowledge-bot-access.log

# Logs de PM2
pm2 logs osac-backend --lines 100
pm2 logs osac-frontend --lines 100
```

## Troubleshooting

### Si el backend no inicia

```bash
# Ver logs detallados
pm2 logs osac-backend --err

# Probar manualmente
cd /opt/osac-knowledge-bot/backend
source venv/bin/activate
python main.py

# Verificar puerto
netstat -tlnp | grep 8001
```

### Si el frontend no inicia

```bash
# Ver logs
pm2 logs osac-frontend --err

# Verificar puerto
netstat -tlnp | grep 3001

# Probar manualmente
cd /opt/osac-knowledge-bot/frontend
npm start
```

### Si Apache no redirige correctamente

```bash
# Verificar configuración
apache2ctl -S | grep osac

# Ver errores
tail -f /var/log/apache2/error.log

# Verificar que los módulos estén habilitados
apache2ctl -M | grep proxy
```

### Si hay conflictos de puerto

```bash
# Ver qué está usando los puertos
netstat -tlnp | grep 8001
netstat -tlnp | grep 3001

# Si hay conflictos, edita ecosystem.config.js y cambia los puertos
```

## Estructura de Archivos en el Servidor

```
/opt/osac-knowledge-bot/
├── backend/
│   ├── venv/
│   ├── .env                    # ⚠️ Configurar con tus credenciales
│   ├── knowledge_bot.db        # Base de datos SQLite
│   ├── chroma_db/              # Base de datos vectorial
│   └── uploads/                # Imágenes subidas
├── frontend/
│   ├── build/                  # Build de producción
│   └── node_modules/
├── deploy.sh                   # Script de deploy
└── ecosystem.config.js         # Configuración PM2
```

## Seguridad

1. ✅ La aplicación corre en puertos internos (8001, 3001)
2. ✅ Solo Apache expone la aplicación al exterior
3. ✅ JWT para autenticación
4. ✅ CORS configurado

## Notas Importantes

- ⚠️ **NO** modifica archivos de configuración de Apache existentes
- ⚠️ **NO** interfiere con tus otras aplicaciones PM2
- ✅ Todas las aplicaciones PM2 se listan juntas con `pm2 list`
- ✅ Puedes gestionar todas desde PM2 de forma unificada

## Próximos Pasos

1. Configura SSL/HTTPS con Let's Encrypt (si tienes dominio)
2. Configura backups automáticos de la base de datos
3. Configura monitoreo y alertas

## Soporte

Si algo no funciona, revisa:
1. Logs de PM2: `pm2 logs`
2. Logs de Apache: `/var/log/apache2/`
3. Estado de servicios: `pm2 status` y `systemctl status apache2`

