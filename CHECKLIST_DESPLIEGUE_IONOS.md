# Checklist de Despliegue en IONOS VPS

## 📋 Pre-requisitos Antes de Desplegar

### 1. **En tu VPS de IONOS, necesitas:**

✅ **Sistema Operativo**: Ubuntu 20.04+ o similar (Linux)
✅ **Acceso SSH**: Debes poder conectarte por SSH
✅ **Acceso root o sudo**: Para instalar paquetes del sistema
✅ **Dominio (opcional)**: Puedes usar la IP del servidor si no tienes dominio

### 2. **Software necesario en el VPS:**

- Python 3.9+ (normalmente viene preinstalado)
- Node.js 18+ (debes instalarlo)
- Nginx (servidor web - debes instalarlo)
- Git (para clonar el código)
- Certbot (para SSL - opcional pero recomendado)

### 3. **En tu máquina local:**

✅ **Código del proyecto**: Ya lo tienes en `C:\Users\krystian\Desktop\osac_knowledge`
✅ **API Key de Gemini**: Ya la tienes configurada en `.env`
✅ **Acceso SSH al VPS**: Usuario y contraseña o clave SSH

---

## 🚀 Pasos para Desplegar

### Paso 1: Subir el código al VPS

**Opción A: Usar Git (recomendado)**
```bash
# En tu máquina local, crea un repositorio Git (si no lo tienes)
cd C:\Users\krystian\Desktop\osac_knowledge
git init
git add .
git commit -m "Initial commit"

# Luego en el VPS, clona el repositorio
```

**Opción B: Subir archivos directamente**
- Usa SFTP/SCP para subir la carpeta completa
- O crea un archivo ZIP y súbelo

**Opción C: Usar GitHub/GitLab**
- Sube el código a GitHub (privado)
- Clona en el VPS

### Paso 2: Conectarte al VPS por SSH

```bash
ssh tu_usuario@tu_ip_vps
# O
ssh tu_usuario@tu_dominio.com
```

### Paso 3: Instalar dependencias del sistema

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Python y herramientas
sudo apt install python3 python3-pip python3-venv git build-essential -y

# Instalar Node.js 18+
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Instalar Nginx
sudo apt install nginx -y

# Instalar Certbot para SSL (opcional)
sudo apt install certbot python3-certbot-nginx -y
```

### Paso 4: Configurar el proyecto en el VPS

```bash
# Crear directorio para la aplicación
sudo mkdir -p /var/www/osac-knowledge-bot
sudo chown -R $USER:$USER /var/www/osac-knowledge-bot

# Si usaste Git, clona el repositorio:
cd /var/www/osac-knowledge-bot
git clone <tu-repositorio> .

# O si subiste archivos, muévelos aquí
```

### Paso 5: Configurar Backend

```bash
cd /var/www/osac-knowledge-bot/backend

# Crear entorno virtual
python3 -m venv venv
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt

# Crear archivo .env
nano .env
```

**Contenido del `.env` (añade tus valores reales):**
```env
GEMINI_API_KEY=tu_api_key_aqui
JWT_SECRET=genera_un_secret_seguro_aqui
CHROMA_DB_PATH=/var/www/osac-knowledge-bot/backend/chroma_db
CORS_ORIGINS=https://tu-dominio.com,https://www.tu-dominio.com
ZENDESK_SUBDOMAIN=tu_subdominio
ZENDESK_EMAIL=tu_email@ejemplo.com
ZENDESK_API_TOKEN=tu_token
```

**Generar JWT_SECRET seguro:**
```bash
openssl rand -hex 32
```

### Paso 6: Configurar Frontend

```bash
cd /var/www/osac-knowledge-bot/frontend

# Instalar dependencias
npm install

# Compilar para producción
npm run build
```

### Paso 7: Configurar Nginx

```bash
sudo nano /etc/nginx/sites-available/osac-knowledge-bot
```

**Contenido del archivo:**
```nginx
server {
    listen 80;
    server_name tu-dominio.com www.tu-dominio.com;

    # Frontend
    location / {
        root /var/www/osac-knowledge-bot/frontend/build;
        try_files $uri $uri/ /index.html;
        index index.html;
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

**Activar configuración:**
```bash
sudo ln -s /etc/nginx/sites-available/osac-knowledge-bot /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Paso 8: Configurar SSL (HTTPS) - Opcional pero Recomendado

```bash
sudo certbot --nginx -d tu-dominio.com -d www.tu-dominio.com
```

### Paso 9: Crear servicios systemd para que corran automáticamente

**Servicio Backend:**
```bash
sudo nano /etc/systemd/system/osac-backend.service
```

**Contenido:**
```ini
[Unit]
Description=OSAC Knowledge Bot Backend
After=network.target

[Service]
User=tu_usuario
Group=tu_usuario
WorkingDirectory=/var/www/osac-knowledge-bot/backend
Environment="PATH=/var/www/osac-knowledge-bot/backend/venv/bin"
ExecStart=/var/www/osac-knowledge-bot/backend/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Nota:** Cambia `tu_usuario` por tu usuario del VPS (ej: `ubuntu`, `root`, etc.)

**Activar servicios:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable osac-backend
sudo systemctl start osac-backend
```

### Paso 10: Configurar firewall

```bash
sudo ufw allow 'Nginx Full'
sudo ufw allow ssh
sudo ufw enable
```

---

## ✅ Verificación Final

1. **Verificar que el backend está corriendo:**
   ```bash
   sudo systemctl status osac-backend
   curl http://localhost:8000/api/health
   ```

2. **Verificar que Nginx está corriendo:**
   ```bash
   sudo systemctl status nginx
   ```

3. **Verificar logs si hay problemas:**
   ```bash
   # Logs del backend
   sudo journalctl -u osac-backend -f

   # Logs de Nginx
   sudo tail -f /var/log/nginx/error.log
   ```

4. **Abrir en el navegador:**
   - `http://tu-ip-vps` o
   - `https://tu-dominio.com`

---

## 🔧 Comandos Útiles

### Gestionar servicios:
```bash
# Ver estado
sudo systemctl status osac-backend

# Iniciar
sudo systemctl start osac-backend

# Detener
sudo systemctl stop osac-backend

# Reiniciar
sudo systemctl restart osac-backend

# Ver logs
sudo journalctl -u osac-backend -f
```

### Actualizar código:
```bash
cd /var/www/osac-knowledge-bot
git pull  # Si usas Git

# Backend
cd backend
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart osac-backend

# Frontend
cd ../frontend
npm install
npm run build
sudo systemctl restart nginx
```

### Backup:
```bash
# Backup de base de datos
cp /var/www/osac-knowledge-bot/backend/knowledge_bot.db /backup/knowledge_bot_$(date +%Y%m%d).db

# Backup de ChromaDB
tar -czf /backup/chroma_db_$(date +%Y%m%d).tar.gz /var/www/osac-knowledge-bot/backend/chroma_db
```

---

## 📝 Checklist Resumen

- [ ] Acceso SSH al VPS de IONOS
- [ ] Sistema operativo actualizado
- [ ] Python 3.9+ instalado
- [ ] Node.js 18+ instalado
- [ ] Nginx instalado y configurado
- [ ] Código subido al VPS
- [ ] Backend configurado con `.env`
- [ ] Frontend compilado (`npm run build`)
- [ ] Servicios systemd configurados
- [ ] SSL configurado (opcional)
- [ ] Firewall configurado
- [ ] Servicios corriendo y verificados
- [ ] Dominio apuntando al VPS (si usas dominio)

---

## 🆘 Solución de Problemas Comunes

### Error: "Puerto 8000 ya en uso"
```bash
sudo lsof -i :8000
sudo kill -9 <PID>
```

### Error: "Permission denied"
```bash
sudo chown -R tu_usuario:tu_usuario /var/www/osac-knowledge-bot
```

### El frontend no carga
```bash
# Verificar que el build existe
ls -la /var/www/osac-knowledge-bot/frontend/build

# Verificar permisos de Nginx
sudo chown -R www-data:www-data /var/www/osac-knowledge-bot/frontend/build
```

### El backend no responde
```bash
# Ver logs
sudo journalctl -u osac-backend -n 50

# Verificar que está corriendo
sudo systemctl status osac-backend
curl http://localhost:8000/api/health
```

---

## 📚 Documentación Adicional

Para más detalles, consulta `DEPLOYMENT.md` que tiene instrucciones más detalladas.

¡Listo para desplegar! 🚀


