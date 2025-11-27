# Guía para Exportar e Importar Datos

Esta guía te ayudará a transferir tus datos (usuarios, conocimiento, imágenes) desde tu entorno local al servidor.

## 📤 Paso 1: Exportar Datos desde Local

### Opción A: Usando el script (Recomendado)

1. En tu máquina local, ejecuta:
   ```bash
   cd C:\Users\krystian\Desktop\osac_knowledge
   chmod +x EXPORTAR_DATOS_LOCAL.sh
   ./EXPORTAR_DATOS_LOCAL.sh
   ```

   O en Windows PowerShell:
   ```powershell
   cd C:\Users\krystian\Desktop\osac_knowledge
   bash EXPORTAR_DATOS_LOCAL.sh
   ```

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

### Opción A: Usando SCP

Desde tu máquina local:
```bash
scp export_datos_*.tar.gz root@82.223.20.111:/tmp/
```

### Opción B: Usando WinSCP o FileZilla

1. Conéctate al servidor con WinSCP/FileZilla
2. Navega a `/tmp/`
3. Sube el archivo `export_datos_*.tar.gz`

### Opción C: Usando Git (si el archivo no es muy grande)

```bash
# Añadir a .gitignore temporalmente no, mejor usar scp
```

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

