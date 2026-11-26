# ============================================================
# PASO 2: cargar-en-otra-pc.ps1
# Ejecutar en la PC del DOCENTE (o laboratorio) desde la USB.
# ============================================================
# Requisito: Docker Desktop instalado y corriendo en esa PC.
# Uso: Abre PowerShell en la RAIZ del proyecto (desde la USB) y ejecuta:
#      .\cargar-en-otra-pc.ps1
# ============================================================

$ErrorActionPreference = "Stop"
$PROYECTO = $PSScriptRoot

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " SISTEMA DE VOTACIONES UNP - Cargar en PC" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# -- Verificar que Docker este corriendo --------------------------------------
Write-Host "`n[1/4] Verificando que Docker Desktop este corriendo ..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "    OK - Docker esta activo" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "    ERROR: Docker Desktop no esta corriendo." -ForegroundColor Red
    Write-Host "    Abrelo desde el menu Inicio y espera a que el icono"
    Write-Host "    de la ballena (en la barra de tareas) deje de animarse."
    Write-Host "    Luego vuelve a ejecutar este script."
    Read-Host "Presiona Enter para salir"
    exit 1
}

# -- Cargar las imagenes desde el .tar ----------------------------------------
Write-Host "`n[2/4] Cargando imagenes Docker desde USB (puede tardar 1-3 min) ..." -ForegroundColor Yellow
$tarFile = "$PROYECTO\imagenes_sistema.tar"
if (-not (Test-Path $tarFile)) {
    Write-Host ""
    Write-Host "    ERROR: No se encontro el archivo imagenes_sistema.tar" -ForegroundColor Red
    Write-Host "    Asegurate de que el archivo este en la misma carpeta que este script."
    Read-Host "Presiona Enter para salir"
    exit 1
}
docker load -i $tarFile
Write-Host "    OK - imagenes cargadas en Docker" -ForegroundColor Green

# -- Levantar el sistema completo ---------------------------------------------
Write-Host "`n[3/4] Levantando el sistema (BD + Backend + Frontend) ..." -ForegroundColor Yellow
Set-Location $PROYECTO
docker compose up -d --no-build
Write-Host "    OK - contenedores iniciando..." -ForegroundColor Green

# -- Esperar y mostrar estado -------------------------------------------------
Write-Host "`n[4/4] Esperando que todos los servicios esten listos (30 seg) ..." -ForegroundColor Yellow
Start-Sleep -Seconds 30
docker compose ps

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  SISTEMA LISTO!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Abre tu navegador en:  http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Si la pagina no carga aun, espera 30 seg mas" -ForegroundColor Yellow
Write-Host "  (MariaDB tarda en inicializar la primera vez)." -ForegroundColor Yellow
Write-Host ""
Write-Host "  Para APAGAR el sistema cuando termines:"
Write-Host "    docker compose down"
Write-Host ""
Read-Host "Presiona Enter para abrir el navegador automaticamente"
Start-Process "http://localhost:3000"
