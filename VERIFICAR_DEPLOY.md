# ✅ Verificación de Deploy - OSAC Knowledge Bot

Después de ejecutar `./QUICK_DEPLOY.sh`, verifica que todo esté funcionando:

## 1. Verificar Estado de PM2

```bash
pm2 status
```

Deberías ver:
- `osac-backend` - status: online
- `osac-frontend` - status: online

## 2. Ver Logs de las Aplicaciones

```bash
# Ver todos los logs
pm2 logs

# Ver logs específicos
pm2 logs osac-backend --lines 50
pm2 logs osac-frontend --lines 50
```

## 3. Verificar que los Puertos están Activos

```bash
# Backend en puerto 8001
netstat -tlnp | grep 8001

# Frontend en puerto 3001
netstat -tlnp | grep 3001
```

## 4. Probar Backend Directamente

```bash
curl http://localhost:8001/api/health
```

Debería responder: `{"status":"ok"}`

## 5. Verificar Archivo .env

```bash
nano /opt/osac-knowledge-bot/backend/.env
```

**IMPORTANTE:** Debes configurar:
- `GEMINI_API_KEY=tu_api_key`
- `JWT_SECRET=un_secret_seguro_minimo_32_caracteres`
- `CORS_ORIGINS=http://82.223.20.111`

Después de editar `.env`, reinicia el backend:
```bash
pm2 restart osac-backend
```

## 6. Verificar Configuración de Apache

```bash
# Ver si el sitio está habilitado
apache2ctl -S | grep osac

# Ver logs de Apache
tail -f /var/log/apache2/osac-knowledge-bot-error.log
```

## 7. Acceder a la Aplicación

Desde tu navegador:
- **http://82.223.20.111** (a través de Apache)
- O directamente: **http://82.223.20.111:3001** (frontend)

## Comandos Útiles

### Reiniciar aplicaciones
```bash
pm2 restart all
pm2 restart osac-backend
pm2 restart osac-frontend
```

### Detener aplicaciones
```bash
pm2 stop all
```

### Ver información detallada
```bash
pm2 show osac-backend
pm2 show osac-frontend
```

### Verificar que Apache está sirviendo correctamente
```bash
curl http://82.223.20.111
curl http://82.223.20.111/api/health
```

## Solución de Problemas Comunes

### Si el backend no inicia

```bash
# Ver errores
pm2 logs osac-backend --err

# Verificar .env
cat /opt/osac-knowledge-bot/backend/.env

# Probar manualmente
cd /opt/osac-knowledge-bot/backend
source venv/bin/activate
python main.py
```

### Si el frontend no inicia

```bash
# Ver errores
pm2 logs osac-frontend --err

# Verificar que el build existe
ls -la /opt/osac-knowledge-bot/frontend/build
```

### Si Apache no redirige

```bash
# Verificar configuración
apache2ctl configtest

# Verificar módulos
apache2ctl -M | grep proxy

# Ver errores
tail -f /var/log/apache2/error.log
```

## Próximos Pasos

1. ✅ Configurar `.env` con tus credenciales
2. ✅ Reiniciar aplicaciones: `pm2 restart all`
3. ✅ Acceder a http://82.223.20.111
4. ✅ Crear el primer usuario (será admin)



