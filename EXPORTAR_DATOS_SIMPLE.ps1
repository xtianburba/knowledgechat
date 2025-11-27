# Script PowerShell simple para exportar datos
# Ejecuta: powershell -ExecutionPolicy Bypass -File .\EXPORTAR_DATOS_SIMPLE.ps1

$ErrorActionPreference = "Stop"

$BACKEND_DIR = "backend"
$EXPORT_DIR = "export_datos"
$TIMESTAMP = Get-Date -Format 'yyyyMMdd_HHmmss'

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  Exportando Datos" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path $BACKEND_DIR)) {
    Write-Host "Error: No se encontró el directorio 'backend'" -ForegroundColor Red
    Write-Host "Ejecuta este script desde la raíz del proyecto" -ForegroundColor Yellow
    exit 1
}

# Crear directorio de exportación
if (Test-Path $EXPORT_DIR) {
    Remove-Item $EXPORT_DIR -Recurse -Force
}
New-Item -ItemType Directory -Path $EXPORT_DIR | Out-Null
Write-Host "✓ Directorio creado: $EXPORT_DIR" -ForegroundColor Green
Write-Host ""

# Copiar archivos
Write-Host "Copiando archivos..." -ForegroundColor Yellow

# Base de datos
$DB_FILE = Join-Path $BACKEND_DIR "knowledge_bot.db"
if (Test-Path $DB_FILE) {
    Copy-Item $DB_FILE -Destination $EXPORT_DIR -Force
    Write-Host "✓ Base de datos SQLite copiada" -ForegroundColor Green
} else {
    Write-Host "⚠ No se encontró knowledge_bot.db" -ForegroundColor Yellow
}

# ChromaDB
$CHROMA_DIR = Join-Path $BACKEND_DIR "chroma_db"
if (Test-Path $CHROMA_DIR) {
    Copy-Item $CHROMA_DIR -Destination $EXPORT_DIR -Recurse -Force
    Write-Host "✓ ChromaDB copiada" -ForegroundColor Green
} else {
    Write-Host "⚠ No se encontró chroma_db" -ForegroundColor Yellow
}

# Uploads
$UPLOADS_DIR = Join-Path $BACKEND_DIR "uploads"
if (Test-Path $UPLOADS_DIR) {
    Copy-Item $UPLOADS_DIR -Destination $EXPORT_DIR -Recurse -Force
    Write-Host "✓ Uploads copiados" -ForegroundColor Green
} else {
    Write-Host "⚠ No se encontró uploads" -ForegroundColor Yellow
}

Write-Host ""

# Comprimir
Write-Host "Comprimiendo..." -ForegroundColor Yellow
$ZIP_FILE = "export_datos_$TIMESTAMP.zip"
Compress-Archive -Path $EXPORT_DIR\* -DestinationPath $ZIP_FILE -Force
Remove-Item $EXPORT_DIR -Recurse -Force
Write-Host "✓ Archivo creado: $ZIP_FILE" -ForegroundColor Green
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ Exportación completada!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Archivo creado: $ZIP_FILE" -ForegroundColor Cyan
Write-Host ""
Write-Host "PRÓXIMOS PASOS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Copia este archivo al servidor usando uno de estos métodos:" -ForegroundColor White
Write-Host ""
Write-Host "   Opción A - Usando SCP (si tienes OpenSSH en Windows):" -ForegroundColor Cyan
Write-Host "   scp $ZIP_FILE root@82.223.20.111:/tmp/" -ForegroundColor White
Write-Host ""
Write-Host "   Opción B - Usando PowerShell SCP:" -ForegroundColor Cyan
Write-Host "   scp $ZIP_FILE root@82.223.20.111`:/tmp/" -ForegroundColor White
Write-Host ""
Write-Host "   Opción C - Manual (si no tienes SCP):" -ForegroundColor Cyan
Write-Host "   - Conéctate al servidor por SSH" -ForegroundColor White
Write-Host "   - Usa 'cat' o 'base64' para transferir (ver instrucciones en EXPORTAR_IMPORTAR_DATOS.md)" -ForegroundColor White
Write-Host ""
Write-Host "2. En el servidor, ejecuta:" -ForegroundColor Yellow
Write-Host "   cd /opt/osac-knowledge-bot" -ForegroundColor White
Write-Host "   git pull" -ForegroundColor White
Write-Host "   sudo ./IMPORTAR_DATOS_SERVIDOR.sh /tmp/$ZIP_FILE" -ForegroundColor White
Write-Host ""

