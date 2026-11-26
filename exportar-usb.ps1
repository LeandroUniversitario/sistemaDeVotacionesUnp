# ============================================================
# PASO 1: exportar-usb.ps1
# Ejecutar en TU PC para preparar todo lo que va en la USB.
# ============================================================
# Uso: Abre PowerShell en la RAIZ del proyecto y ejecuta:
#      .\exportar-usb.ps1
# ============================================================

$ErrorActionPreference = "Stop"
$PROYECTO = $PSScriptRoot

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " SISTEMA DE VOTACIONES UNP - Exportar USB" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# -- Paso 1: Cachear dependencias Maven (para build offline) ------------------
Write-Host "`n[1/5] Cacheando dependencias Maven en backend/.m2 ..." -ForegroundColor Yellow
Set-Location "$PROYECTO\backend"
docker run --rm `
    -v "${PROYECTO}\backend:/app" `
    -v "${PROYECTO}\backend\.m2:/root/.m2" `
    -w /app `
    maven:3.9-eclipse-temurin-21-alpine `
    mvn dependency:go-offline -B
Write-Host "    OK - dependencias Maven cacheadas en backend\.m2" -ForegroundColor Green

# -- Paso 2: Build de imagenes Docker -----------------------------------------
Write-Host "`n[2/5] Construyendo imagenes Docker (backend + frontend) ..." -ForegroundColor Yellow
Set-Location $PROYECTO
docker compose build --no-cache
Write-Host "    OK - imagenes construidas" -ForegroundColor Green

# -- Paso 3: Exportar imagenes a un archivo .tar ------------------------------
Write-Host "`n[3/5] Exportando imagenes a archivo .tar (puede tardar ~2 min) ..." -ForegroundColor Yellow
docker pull mariadb:10.11
$imagenes = @(
    "mariadb:10.11",
    "elecciones-unp-backend:1.0",
    "elecciones-unp-frontend:1.0"
)

Write-Host "    Imagenes a exportar: $($imagenes -join ', ')"
docker save -o "$PROYECTO\imagenes_sistema.tar" @imagenes
Write-Host "    OK - imagenes guardadas en imagenes_sistema.tar" -ForegroundColor Green

# -- Paso 4: Verificar tamano -------------------------------------------------
$tam = (Get-Item "$PROYECTO\imagenes_sistema.tar").Length / 1GB
Write-Host "`n[4/5] Tamano del archivo de imagenes: $([math]::Round($tam, 2)) GB" -ForegroundColor Yellow

# -- Paso 5: Instrucciones finales --------------------------------------------
Write-Host "`n[5/5] LISTO. Copia SOLO estos 4 elementos a una carpeta en tu USB:" -ForegroundColor Green
Write-Host ""
Write-Host "   [CARPETA] base-de-datos\        (contiene el script SQL con tablas y datos)"
Write-Host "   [ARCHIVO] docker-compose.yml"
Write-Host "   [ARCHIVO] imagenes_sistema.tar  (el mas pesado, tiene Backend + Frontend + MariaDB)"
Write-Host "   [ARCHIVO] cargar-en-otra-pc.ps1"
Write-Host ""
Write-Host "   (Ya NO necesitas copiar backend\ ni frontend\ a la USB porque van compilados dentro del .tar)" -ForegroundColor Cyan
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Exportacion completada con exito!" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
