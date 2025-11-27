# Solución: Autenticación GitHub en el Servidor

GitHub ya no permite autenticación por contraseña. Tienes dos opciones:

## Opción 1: Hacer el Repositorio Público (Más Rápido)

1. Ve a tu repositorio en GitHub: https://github.com/xtianburba/knowledgechat
2. Ve a **Settings** (Configuración)
3. Desplázate hacia abajo hasta **Danger Zone**
4. Haz clic en **Change visibility** → **Make public**
5. Confirma el cambio

Luego en el servidor puedes clonar sin problemas:
```bash
git clone https://github.com/xtianburba/knowledgechat.git osac-knowledge-bot
```

## Opción 2: Usar Token de Acceso Personal (Mantener Repositorio Privado)

### Paso 1: Crear Token en GitHub

1. Ve a GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. O directamente: https://github.com/settings/tokens
3. Haz clic en **Generate new token (classic)**
4. Dale un nombre: `IONOS Server Deploy`
5. Selecciona permisos:
   - ✅ `repo` (acceso completo a repositorios privados)
6. Genera el token y **CÓPIALO** (solo lo verás una vez)

### Paso 2: Configurar Token en el Servidor

**Opción A: Usar Token en la URL (temporal)**
```bash
cd /opt
git clone https://TU_TOKEN@github.com/xtianburba/knowledgechat.git osac-knowledge-bot
```

**Opción B: Configurar Git Credential Helper (permanente)**
```bash
# Instalar git-credential-store
apt install -y git

# Configurar credenciales
git config --global credential.helper store

# Clonar (te pedirá usuario y contraseña/token)
git clone https://github.com/xtianburba/knowledgechat.git osac-knowledge-bot
# Usuario: xtianburba
# Contraseña: Pega aquí tu token de acceso personal
```

**Opción C: Usar SSH (recomendado para producción)**

1. Generar clave SSH en el servidor:
```bash
ssh-keygen -t ed25519 -C "deploy@ionos-server"
# Presiona Enter para aceptar ubicación por defecto
# Opcional: añade una passphrase o déjala vacía
```

2. Mostrar la clave pública:
```bash
cat ~/.ssh/id_ed25519.pub
```

3. Copiar la clave y añadirla en GitHub:
   - Ve a: https://github.com/settings/keys
   - Click **New SSH key**
   - Título: `IONOS Server`
   - Pega la clave pública
   - Click **Add SSH key**

4. Cambiar el remote del repositorio a SSH:
```bash
cd /opt/osac-knowledge-bot
git remote set-url origin git@github.com:xtianburba/knowledgechat.git
```

## Recomendación

Para un servidor de producción, **recomiendo hacer el repositorio público** ya que:
- ✅ Es más simple y no requiere gestión de tokens
- ✅ El código no contiene información sensible (las credenciales están en `.env` que está en `.gitignore`)
- ✅ No necesitas preocuparte por expiración de tokens
- ✅ Más fácil de mantener y actualizar

La información sensible (API keys, passwords) ya está protegida porque:
- El archivo `.env` está en `.gitignore`
- Las bases de datos no se suben a GitHub
- Los uploads tampoco se suben



