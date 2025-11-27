# Script PowerShell para exportar datos desde Windows
# Ejecuta: powershell -ExecutionPolicy Bypass -File .\EXPORTAR_DATOS_LOCAL.ps1

$ErrorActionPreference = "Stop"

$PROJECT_DIR = $PSScriptRoot
$BACKEND_DIR = Join-Path $PROJECT_DIR "backend"
$EXPORT_DIR = Join-Path $PROJECT_DIR "export_datos_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$TIMESTAMP = Get-Date -Format 'yyyyMMdd_HHmmss'

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "  Exportando Datos desde Local" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host ""

# Crear directorio de exportación
New-Item -ItemType Directory -Path $EXPORT_DIR -Force | Out-Null
Write-Host "✓ Directorio de exportación creado: $EXPORT_DIR" -ForegroundColor Green
Write-Host ""

# 1. Exportar base de datos SQLite
Write-Host "[1/4] Exportando base de datos SQLite..." -ForegroundColor Yellow
$DB_FILE = Join-Path $BACKEND_DIR "knowledge_bot.db"
if (Test-Path $DB_FILE) {
    Copy-Item $DB_FILE -Destination $EXPORT_DIR -Force
    Write-Host "✓ Base de datos SQLite exportada" -ForegroundColor Green
} else {
    Write-Host "⚠ No se encontró knowledge_bot.db" -ForegroundColor Yellow
}
Write-Host ""

# 2. Exportar ChromaDB (base de datos vectorial)
Write-Host "[2/4] Exportando ChromaDB..." -ForegroundColor Yellow
$CHROMA_DIR = Join-Path $BACKEND_DIR "chroma_db"
if (Test-Path $CHROMA_DIR) {
    Copy-Item $CHROMA_DIR -Destination $EXPORT_DIR -Recurse -Force
    Write-Host "✓ ChromaDB exportada" -ForegroundColor Green
} else {
    Write-Host "⚠ No se encontró chroma_db" -ForegroundColor Yellow
}
Write-Host ""

# 3. Exportar uploads (imágenes y archivos)
Write-Host "[3/4] Exportando archivos uploads..." -ForegroundColor Yellow
$UPLOADS_DIR = Join-Path $BACKEND_DIR "uploads"
if (Test-Path $UPLOADS_DIR) {
    Copy-Item $UPLOADS_DIR -Destination $EXPORT_DIR -Recurse -Force
    Write-Host "✓ Archivos uploads exportados" -ForegroundColor Green
} else {
    Write-Host "⚠ No se encontró directorio uploads" -ForegroundColor Yellow
}
Write-Host ""

# 4. Crear archivo de información
Write-Host "[4/4] Creando archivo de información..." -ForegroundColor Yellow
$INFO_FILE = Join-Path $EXPORT_DIR "INFO.txt"
$INFO_CONTENT = @"
Exportación de datos OSAC Knowledge Bot
Fecha: $(Get-Date)
Directorio de origen: $PROJECT_DIR

Contenido:
- knowledge_bot.db: Base de datos SQLite (usuarios, conocimiento, analytics)
- chroma_db/: Base de datos vectorial para búsqueda semántica
- uploads/: Archivos e imágenes subidos

Para importar en el servidor, ejecuta:
  ./IMPORTAR_DATOS_SERVIDOR.sh

O manualmente copia estos archivos al servidor y ejecuta:
  scp -r export_datos_* usuario@servidor:/tmp/
  # En el servidor:
  cd /opt/osac-knowledge-bot
  ./IMPORTAR_DATOS_SERVIDOR.sh /tmp/export_datos_*
"@
Set-Content -Path $INFO_FILE -Value $INFO_CONTENT
Write-Host "✓ Archivo de información creado" -ForegroundColor Green
Write-Host ""

# Comprimir todo
Write-Host "Comprimiendo datos exportados..." -ForegroundColor Yellow
$TAR_FILE = "$PROJECT_DIR\export_datos_$TIMESTAMP.tar.gz"

# Usar Compress-Archive (crea .zip) ya que tar puede no estar disponible
$ZIP_FILE = "$PROJECT_DIR\export_datos_$TIMESTAMP.zip"
Compress-Archive -Path $EXPORT_DIR -DestinationPath $ZIP_FILE -Force
Write-Host "✓ Datos comprimidos en: $ZIP_FILE" -ForegroundColor Green

# Intentar crear .tar.gz si tar está disponible
if (Get-Command tar -ErrorAction SilentlyContinue) {
    Push-Location $PROJECT_DIR
    $EXPORT_DIR_NAME = Split-Path $EXPORT_DIR -Leaf
    tar -czf "$TAR_FILE" "$EXPORT_DIR_NAME" 2>$null
    Pop-Location
    if (Test-Path $TAR_FILE) {
        Write-Host "✓ También creado archivo tar.gz: $TAR_FILE" -ForegroundColor Green
    }
}

# Eliminar directorio temporal
Remove-Item $EXPORT_DIR -Recurse -Force
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  ✅ Exportación completada!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "Archivo creado: $ZIP_FILE" -ForegroundColor Cyan
if (Test-Path $TAR_FILE) {
    Write-Host "Archivo tar.gz: $TAR_FILE" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "Para transferir al servidor:" -ForegroundColor Yellow
Write-Host "  scp $ZIP_FILE root@82.223.20.111:/tmp/" -ForegroundColor Cyan
if (Test-Path $TAR_FILE) {
    Write-Host "  O: scp $TAR_FILE root@82.223.20.111:/tmp/" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "O usa WinSCP para subir el archivo a /tmp/ en el servidor" -ForegroundColor Yellow
Write-Host ""

