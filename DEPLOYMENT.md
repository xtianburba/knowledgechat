# Guía de Despliegue en VPS (IONOS)

Esta guía te ayudará a desplegar el OSAC Knowledge Bot en tu servidor VPS de IONOS.

## Requisitos Previos

- Servidor VPS con Ubuntu 20.04+ o similar
- Acceso SSH al servidor
- Dominio opcional (puedes usar la IP del servidor)

## Paso 1: Configurar el Servidor

### Actualizar el sistema

```bash
sudo apt update
sudo apt upgrade -y
```

### Instalar dependencias

```bash
# Python 3.9+
sudo apt install python3 python3-pip python3-venv -y

# Node.js 18+ (usando NodeSource)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Nginx (como proxy inverso)
sudo apt install nginx -y

# Certbot para SSL (opcional pero recomendado)
sudo apt install certbot python3-certbot-nginx -y

# Otros útiles
sudo apt install git build-essential -y
```

## Paso 2: Clonar y Configurar el Proyecto

### Clonar el repositorio

```bash
cd /var/www
sudo git clone <tu-repositorio> osac-knowledge-bot
sudo chown -R $USER:$USER osac-knowledge-bot
cd osac-knowledge-bot
```

### Configurar Backend

```bash
cd backend

# Crear entorno virtual
python3 -m venv venv
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt

# Crear archivo .env
cp .env.example .env
nano .env
```

Configura las variables en `.env`:

```env
GEMINI_API_KEY=tu_api_key_de_gemini
JWT_SECRET=genera_un_secret_seguro_aqui
CHROMA_DB_PATH=/var/www/osac-knowledge-bot/backend/chroma_db
CORS_ORIGINS=https://tu-dominio.com,https://www.tu-dominio.com
```

### Configurar Frontend

```bash
cd ../frontend

# Instalar dependencias
npm install

# Configurar variables de entorno (opcional)
# Edita src/config.js si necesitas cambiar la URL del API
```

## Paso 3: Configurar Nginx

Crea un archivo de configuración de Nginx:

```bash
sudo nano /etc/nginx/sites-available/osac-knowledge-bot
```

Contenido:

```nginx
server {
    listen 80;
    server_name tu-dominio.com www.tu-dominio.com;

    # Redirigir todo el tráfico a HTTPS (descomenta después de configurar SSL)
    # return 301 https://$server_name$request_uri;

    # Frontend
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Uploaded files
    location /api/images {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
    }
}
```

Activa la configuración:

```bash
sudo ln -s /etc/nginx/sites-available/osac-knowledge-bot /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## Paso 4: Configurar SSL (Opcional pero Recomendado)

```bash
sudo certbot --nginx -d tu-dominio.com -d www.tu-dominio.com
```

Esto configurará automáticamente HTTPS y renovará los certificados.

## Paso 5: Crear Servicios Systemd

### Servicio para el Backend

```bash
sudo nano /etc/systemd/system/osac-backend.service
```

Contenido:

```ini
[Unit]
Description=OSAC Knowledge Bot Backend
After=network.target

[Service]
User=tu-usuario
Group=tu-usuario
WorkingDirectory=/var/www/osac-knowledge-bot/backend
Environment="PATH=/var/www/osac-knowledge-bot/backend/venv/bin"
ExecStart=/var/www/osac-knowledge-bot/backend/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
Restart=always

[Install]
WantedBy=multi-user.target
```

### Servicio para el Frontend

```bash
sudo nano /etc/systemd/system/osac-frontend.service
```

Contenido:

```ini
[Unit]
Description=OSAC Knowledge Bot Frontend
After=network.target

[Service]
User=tu-usuario
Group=tu-usuario
WorkingDirectory=/var/www/osac-knowledge-bot/frontend
Environment="PORT=3000"
Environment="NODE_ENV=production"
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
```

Activa y inicia los servicios:

```bash
sudo systemctl daemon-reload
sudo systemctl enable osac-backend
sudo systemctl enable osac-frontend
sudo systemctl start osac-backend
sudo systemctl start osac-frontend
```

## Paso 6: Verificar el Despliegue

### Verificar servicios

```bash
sudo systemctl status osac-backend
sudo systemctl status osac-frontend
```

### Ver logs

```bash
# Logs del backend
sudo journalctl -u osac-backend -f

# Logs del frontend
sudo journalctl -u osac-frontend -f
```

### Verificar que todo funciona

1. Accede a `http://tu-dominio.com` o `https://tu-dominio.com`
2. Deberías ver la página de login
3. Crea una cuenta (el primer usuario será admin)
4. Prueba el chat y la gestión de conocimiento

## Paso 7: Configurar Firewall

Si usas UFW:

```bash
sudo ufw allow 'Nginx Full'
sudo ufw allow ssh
sudo ufw enable
```

## Mantenimiento

### Actualizar el código

```bash
cd /var/www/osac-knowledge-bot
git pull

# Backend
cd backend
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart osac-backend

# Frontend
cd ../frontend
npm install
npm run build
sudo systemctl restart osac-frontend
```

### Backup

Configura backups regulares de:

- `/var/www/osac-knowledge-bot/backend/knowledge_bot.db` (base de datos SQLite)
- `/var/www/osac-knowledge-bot/backend/chroma_db` (base de datos vectorial)
- `/var/www/osac-knowledge-bot/backend/uploads` (imágenes)

Ejemplo de script de backup:

```bash
#!/bin/bash
BACKUP_DIR="/backup/osac-knowledge-bot"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
cp /var/www/osac-knowledge-bot/backend/knowledge_bot.db $BACKUP_DIR/knowledge_bot_$DATE.db

# Backup vector database
tar -czf $BACKUP_DIR/chroma_db_$DATE.tar.gz /var/www/osac-knowledge-bot/backend/chroma_db

# Backup uploads
tar -czf $BACKUP_DIR/uploads_$DATE.tar.gz /var/www/osac-knowledge-bot/backend/uploads

# Eliminar backups antiguos (más de 30 días)
find $BACKUP_DIR -type f -mtime +30 -delete
```

## Solución de Problemas

### El backend no inicia

- Verifica los logs: `sudo journalctl -u osac-backend -n 50`
- Verifica que el puerto 8000 no esté en uso: `sudo netstat -tlnp | grep 8000`
- Verifica las variables de entorno en `.env`

### El frontend no inicia

- Verifica los logs: `sudo journalctl -u osac-frontend -n 50`
- Verifica que el puerto 3000 no esté en uso
- Intenta ejecutar manualmente: `cd frontend && npm start`

### Error de conexión a la API

- Verifica que el backend esté corriendo
- Verifica la configuración de Nginx
- Verifica los CORS_ORIGINS en el .env del backend

## Soporte

Para más ayuda, consulta los logs o revisa la documentación en el README.md principal.


