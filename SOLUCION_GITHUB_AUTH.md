# 🔐 Solución: Autenticación GitHub para Deploy

GitHub ya no permite autenticación por contraseña. El error que ves es normal.

## ⚡ Solución Rápida: Hacer Repositorio Público

1. Ve a: https://github.com/xtianburba/knowledgechat/settings
2. Desplázate hasta el final → **Danger Zone**
3. Click en **Change visibility** → **Make public**
4. Confirma

**Ventajas:**
- ✅ Más simple (no necesitas tokens)
- ✅ Tu código no tiene información sensible (`.env` está en `.gitignore`)
- ✅ Fácil de mantener

Luego en el servidor:
```bash
cd /opt
git clone https://github.com/xtianburba/knowledgechat.git osac-knowledge-bot
cd osac-knowledge-bot
chmod +x QUICK_DEPLOY.sh
./QUICK_DEPLOY.sh
```

## 🔑 Solución Alternativa: Usar Token Personal

Si prefieres mantener el repositorio privado:

### 1. Crear Token en GitHub

1. Ve a: https://github.com/settings/tokens
2. Click **Generate new token (classic)**
3. Nombre: `IONOS Server`
4. Selecciona: `repo` (acceso completo)
5. Click **Generate token**
6. **COPIA EL TOKEN** (solo lo verás una vez)

### 2. Clonar con Token en el Servidor

```bash
cd /opt
git clone https://TU_TOKEN_AQUI@github.com/xtianburba/knowledgechat.git osac-knowledge-bot
```

Reemplaza `TU_TOKEN_AQUI` con el token que copiaste.

## 📋 Instrucciones Completas de Deploy

Una vez que resuelvas la autenticación, sigue estos pasos:

```bash
# 1. Clonar repositorio
cd /opt
git clone https://github.com/xtianburba/knowledgechat.git osac-knowledge-bot
cd osac-knowledge-bot

# 2. Ejecutar deploy automático
chmod +x QUICK_DEPLOY.sh
./QUICK_DEPLOY.sh

# 3. Configurar credenciales
nano backend/.env
# Añade: GEMINI_API_KEY, JWT_SECRET, etc.

# 4. Reiniciar aplicaciones
pm2 restart all
```

## ✅ Verificar que Funciona

```bash
# Ver estado
pm2 status

# Ver logs
pm2 logs

# Acceder a la aplicación
curl http://localhost:8001/api/health
```



