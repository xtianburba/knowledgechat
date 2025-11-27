# Script PowerShell para exportar datos
# Ejecuta: .\EXPORTAR_DATOS_SIMPLE.ps1

$ErrorActionPreference = "Stop"

$BACKEND_DIR = "backend"
$EXPORT_DIR = "export_datos"
$TIMESTAMP = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "Exportando Datos..." -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path $BACKEND_DIR)) {
    Write-Host "Error: No se encontro el directorio backend" -ForegroundColor Red
    exit 1
}

if (Test-Path $EXPORT_DIR) {
    Remove-Item $EXPORT_DIR -Recurse -Force
}
New-Item -ItemType Directory -Path $EXPORT_DIR | Out-Null
Write-Host "Directorio creado: $EXPORT_DIR" -ForegroundColor Green
Write-Host ""

Write-Host "Copiando archivos..." -ForegroundColor Yellow

$DB_FILE = Join-Path $BACKEND_DIR "knowledge_bot.db"
if (Test-Path $DB_FILE) {
    Copy-Item $DB_FILE -Destination $EXPORT_DIR -Force
    Write-Host "Base de datos copiada" -ForegroundColor Green
}

$CHROMA_DIR = Join-Path $BACKEND_DIR "chroma_db"
if (Test-Path $CHROMA_DIR) {
    Copy-Item $CHROMA_DIR -Destination $EXPORT_DIR -Recurse -Force
    Write-Host "ChromaDB copiada" -ForegroundColor Green
}

$UPLOADS_DIR = Join-Path $BACKEND_DIR "uploads"
if (Test-Path $UPLOADS_DIR) {
    Copy-Item $UPLOADS_DIR -Destination $EXPORT_DIR -Recurse -Force
    Write-Host "Uploads copiados" -ForegroundColor Green
}

Write-Host ""

Write-Host "Comprimiendo..." -ForegroundColor Yellow
$ZIP_FILE = "export_datos_$TIMESTAMP.zip"

if (Test-Path $ZIP_FILE) {
    Remove-Item $ZIP_FILE -Force
}

Compress-Archive -Path "$EXPORT_DIR\*" -DestinationPath $ZIP_FILE -Force
Remove-Item $EXPORT_DIR -Recurse -Force
Write-Host "Archivo creado: $ZIP_FILE" -ForegroundColor Green
Write-Host ""

Write-Host "=== Exportacion completada ===" -ForegroundColor Green
Write-Host ""
Write-Host "Archivo: $ZIP_FILE" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para transferir al servidor:" -ForegroundColor Yellow
Write-Host "  scp $ZIP_FILE root@82.223.20.111:/tmp/" -ForegroundColor White
Write-Host ""
