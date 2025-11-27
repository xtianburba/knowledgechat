# Configurar Apache con el Subdominio

Para hacer que la aplicación sea accesible desde `http://osac-knowledge-bot.perfumesclub-helping.com/`, sigue estos pasos:

## Paso 1: Configurar Apache en el servidor

Ejecuta estos comandos en el servidor SSH:

```bash
cd /opt/osac-knowledge-bot
git pull

# Configurar Apache con el subdominio
chmod +x CONFIGURAR_SUBDOMINIO.sh
sudo ./CONFIGURAR_SUBDOMINIO.sh
```

## Paso 2: Actualizar CORS en el backend

```bash
# Actualizar CORS_ORIGINS en .env
chmod +x ACTUALIZAR_CORS.sh
./ACTUALIZAR_CORS.sh

# Reiniciar backend
pm2 restart osac-backend
```

## Paso 3: Verificar DNS

Asegúrate de que el DNS apunte el subdominio a la IP del servidor:

```
osac-knowledge-bot.perfumesclub-helping.com  →  82.223.20.111
```

Puedes verificar con:
```bash
nslookup osac-knowledge-bot.perfumesclub-helping.com
```

## Paso 4: Verificar que todo funciona

1. **Backend**: http://osac-knowledge-bot.perfumesclub-helping.com/api/health
2. **Frontend**: http://osac-knowledge-bot.perfumesclub-helping.com/

## Notas Importantes

- El frontend está corriendo en modo desarrollo (puerto 3001) a través de PM2
- El backend está en el puerto 8001
- Apache actúa como reverse proxy redirigiendo:
  - `/` → `http://localhost:3001/` (frontend)
  - `/api` → `http://localhost:8001/api` (backend)

## Si quieres servir el frontend compilado directamente

Si prefieres servir los archivos estáticos compilados de React directamente desde Apache (sin el servidor de desarrollo):

1. Compila el frontend:
   ```bash
   cd /opt/osac-knowledge-bot/frontend
   npm run build
   ```

2. Actualiza la configuración de Apache para servir los archivos estáticos:
   ```apache
   # En lugar de ProxyPass a localhost:3001
   DocumentRoot /opt/osac-knowledge-bot/frontend/build
   
   <Directory /opt/osac-knowledge-bot/frontend/build>
       Options -Indexes +FollowSymLinks
       AllowOverride None
       Require all granted
       
       # Para React Router
       RewriteEngine On
       RewriteBase /
       RewriteRule ^index\.html$ - [L]
       RewriteCond %{REQUEST_FILENAME} !-f
       RewriteCond %{REQUEST_FILENAME} !-d
       RewriteRule . /index.html [L]
   </Directory>
   ```

Pero por ahora, con el servidor de desarrollo funcionará bien.

