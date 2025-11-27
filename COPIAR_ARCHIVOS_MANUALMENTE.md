# Copiar Archivos Manualmente al Servidor

Si no tienes SCP, puedes copiar los archivos manualmente siguiendo estos pasos:

## Método Simple: Copiar archivos directamente

### Paso 1: En Windows, copia estos archivos a un lugar fácil de encontrar:

1. `backend\knowledge_bot.db`
2. `backend\chroma_db\` (toda la carpeta)
3. `backend\uploads\` (toda la carpeta)

### Paso 2: En el servidor SSH, crea estos directorios:

```bash
mkdir -p /tmp/datos_importacion
cd /tmp/datos_importacion
```

### Paso 3: Copia los archivos usando uno de estos métodos:

**Método A: Usar el editor nano/vim para crear archivos pequeños**

Para archivos pequeños, puedes copiar el contenido. Para archivos grandes como la base de datos, mejor usa el método B.

**Método B: Transferir archivo por archivo usando base64**

1. **En Windows PowerShell**, codifica cada archivo:
   ```powershell
   # Para la base de datos
   $content = [Convert]::ToBase64String([IO.File]::ReadAllBytes("backend\knowledge_bot.db"))
   $content | Out-File -Encoding ASCII "db_base64.txt"
   ```

2. **Copia el contenido del archivo** `db_base64.txt`

3. **En el servidor SSH**, crea el archivo:
   ```bash
   nano /tmp/datos_importacion/db_base64.txt
   # Pega todo el contenido aquí
   # Guarda: Ctrl+O, Enter, Ctrl+X
   ```

4. **Decodifica en el servidor**:
   ```bash
   base64 -d /tmp/datos_importacion/db_base64.txt > /tmp/datos_importacion/knowledge_bot.db
   rm /tmp/datos_importacion/db_base64.txt
   ```

5. **Repite para cada archivo/carpeta**

### Paso 4: Una vez que tengas todos los archivos en el servidor:

```bash
cd /opt/osac-knowledge-bot/backend

# Hacer backup de lo existente
cp -r knowledge_bot.db knowledge_bot.db.backup 2>/dev/null || true
cp -r chroma_db chroma_db.backup 2>/dev/null || true
cp -r uploads uploads.backup 2>/dev/null || true

# Copiar los nuevos
cp /tmp/datos_importacion/knowledge_bot.db ./
cp -r /tmp/datos_importacion/chroma_db ./
cp -r /tmp/datos_importacion/uploads ./

# Reiniciar backend
pm2 restart osac-backend
```

## ⚠️ Nota

Este método es laborioso para archivos grandes. Si el archivo ZIP es muy grande, mejor:
- Usa SCP que viene con Windows 10+
- O pide ayuda para transferir los archivos

