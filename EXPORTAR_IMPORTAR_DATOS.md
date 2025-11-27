# Guía para Exportar e Importar Datos

Esta guía te ayudará a transferir tus datos (usuarios, conocimiento, imágenes) desde tu entorno local al servidor.

## 📤 Paso 1: Exportar Datos desde Local

### Usando PowerShell (Windows)

1. En tu máquina local, ejecuta PowerShell y:
   ```powershell
   cd C:\Users\krystian\Desktop\osac_knowledge
   powershell -ExecutionPolicy Bypass -File .\EXPORTAR_DATOS_SIMPLE.ps1
   ```

   Esto creará un archivo `export_datos_YYYYMMDD_HHMMSS.zip` con todos tus datos.

### Opción B: Manualmente

1. **Crear directorio de exportación:**
   ```bash
   mkdir export_datos
   ```

2. **Copiar base de datos SQLite:**
   ```bash
   cp backend/knowledge_bot.db export_datos/
   ```

3. **Copiar ChromaDB:**
   ```bash
   cp -r backend/chroma_db export_datos/
   ```

4. **Copiar uploads:**
   ```bash
   cp -r backend/uploads export_datos/
   ```

5. **Comprimir todo:**
   ```bash
   tar -czf export_datos.tar.gz export_datos/
   ```

## 📦 Paso 2: Transferir al Servidor

### Opción A: Usando SCP (Recomendado)

Desde PowerShell en Windows:
```powershell
scp export_datos_*.zip root@82.223.20.111:/tmp/
```

Si te pide contraseña, ingrésala.

### Opción B: Transferencia Manual vía SSH (Sin herramientas externas)

Si no tienes SCP, puedes usar este método:

1. **En Windows PowerShell**, codifica el archivo en base64:
   ```powershell
   $content = [Convert]::ToBase64String([IO.File]::ReadAllBytes("export_datos_YYYYMMDD_HHMMSS.zip"))
   $content | Out-File -Encoding ASCII "export_base64.txt"
   ```

2. **Copia el contenido del archivo `export_base64.txt`** (puede ser muy grande)

3. **En el servidor SSH**, crea el archivo:
   ```bash
   nano /tmp/export_base64.txt
   # Pega todo el contenido aquí
   # Guarda: Ctrl+O, Enter, Ctrl+X
   ```

4. **Decodifica en el servidor**:
   ```bash
   base64 -d /tmp/export_base64.txt > /tmp/export_datos_YYYYMMDD_HHMMSS.zip
   rm /tmp/export_base64.txt
   ```

**NOTA**: Este método puede ser lento para archivos grandes. Si el archivo es muy grande, mejor usa SCP o pide ayuda para instalar WinSCP.

## 📥 Paso 3: Importar Datos en el Servidor

1. **Conéctate al servidor:**
   ```bash
   ssh root@82.223.20.111
   ```

2. **Ejecuta el script de importación:**
   ```bash
   cd /opt/osac-knowledge-bot
   git pull
   chmod +x IMPORTAR_DATOS_SERVIDOR.sh
   sudo ./IMPORTAR_DATOS_SERVIDOR.sh
   ```

   O especifica el archivo:
   ```bash
   sudo ./IMPORTAR_DATOS_SERVIDOR.sh /tmp/export_datos_YYYYMMDD_HHMMSS.tar.gz
   ```

3. **El script hará:**
   - Detener el backend
   - Crear backups de datos existentes
   - Importar la base de datos SQLite
   - Importar ChromaDB
   - Importar archivos uploads
   - Reiniciar el backend

## ⚠️ Importante

- **Backups automáticos**: El script crea backups automáticos antes de importar
- **Datos existentes**: Si hay datos en el servidor, se hará merge (los nuevos sobrescribirán los antiguos)
- **Permisos**: El script ajusta los permisos automáticamente

## 🔍 Verificar Importación

Después de importar, verifica:

1. **Usuarios:**
   ```bash
   cd /opt/osac-knowledge-bot/backend
   source venv/bin/activate
   python crear_usuario.py --list
   ```

2. **Base de datos:**
   ```bash
   ls -lh /opt/osac-knowledge-bot/backend/knowledge_bot.db
   ```

3. **ChromaDB:**
   ```bash
   ls -lh /opt/osac-knowledge-bot/backend/chroma_db/
   ```

## 📝 Notas

- El proceso detiene el backend temporalmente
- Los backups se guardan en `/opt/osac-knowledge-bot/backup_*`
- Si algo sale mal, puedes restaurar desde los backups

