#!/usr/bin/env pwsh
# Script de inicio rápido para Windows PowerShell

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Tarea 3 - Sistemas Distribuidos" -ForegroundColor Cyan
Write-Host "  Análisis Hadoop + Pig" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que Docker esté corriendo
Write-Host "Verificando Docker..." -ForegroundColor Yellow
docker --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker no está instalado o no está corriendo" -ForegroundColor Red
    exit 1
}

docker-compose --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker Compose no está instalado" -ForegroundColor Red
    exit 1
}

Write-Host "OK: Docker listo" -ForegroundColor Green
Write-Host ""

# Verificar que response.json existe
if (-Not (Test-Path "response.json")) {
    Write-Host "ERROR: response.json no encontrado" -ForegroundColor Red
    Write-Host "Asegúrate de que el archivo response.json esté en el directorio actual" -ForegroundColor Yellow
    exit 1
}

Write-Host "OK: response.json encontrado" -ForegroundColor Green
Write-Host ""

# Limpiar contenedores anteriores si existen
Write-Host "Limpiando contenedores anteriores..." -ForegroundColor Yellow
docker-compose down -v 2>$null
Write-Host ""

# Construir imágenes
Write-Host "Construyendo imágenes Docker..." -ForegroundColor Yellow
Write-Host "(Esto puede tardar 10-15 minutos la primera vez)" -ForegroundColor Cyan
docker-compose build
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Fallo al construir imágenes" -ForegroundColor Red
    exit 1
}

Write-Host "OK: Imagenes construidas" -ForegroundColor Green
Write-Host ""

# Iniciar servicios
Write-Host "Iniciando servicios..." -ForegroundColor Yellow
docker-compose up -d
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Fallo al iniciar servicios" -ForegroundColor Red
    exit 1
}

Write-Host "OK: Servicios iniciados" -ForegroundColor Green
Write-Host ""

# Mostrar información
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Servicios en ejecución" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
docker-compose ps
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Interfaces Web" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "- Hadoop NameNode UI: " -NoNewline
Write-Host "http://localhost:9870" -ForegroundColor Yellow
Write-Host "- YARN ResourceManager: " -NoNewline
Write-Host "http://localhost:8088" -ForegroundColor Yellow
Write-Host "- DataNode UI: " -NoNewline
Write-Host "http://localhost:9864" -ForegroundColor Yellow
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Comandos útiles" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ver logs del análisis:" -ForegroundColor Yellow
Write-Host "  docker-compose logs -f pig_analysis" -ForegroundColor White
Write-Host ""
Write-Host "Ver todos los logs:" -ForegroundColor Yellow
Write-Host "  docker-compose logs -f" -ForegroundColor White
Write-Host ""
Write-Host "Conectarse al NameNode:" -ForegroundColor Yellow
Write-Host "  docker exec -it hadoop_namenode bash" -ForegroundColor White
Write-Host ""
Write-Host "Ver resultados en HDFS:" -ForegroundColor Yellow
Write-Host "  docker exec -it hadoop_namenode hdfs dfs -cat /output/human_top100/part-r-00000" -ForegroundColor White
Write-Host ""
Write-Host "Detener servicios:" -ForegroundColor Yellow
Write-Host "  docker-compose down" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  ¡Proceso iniciado!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "El análisis comenzará automáticamente." -ForegroundColor Cyan
Write-Host "Espera aproximadamente 5-10 minutos para que se complete." -ForegroundColor Cyan
Write-Host ""
Write-Host "Monitoreando logs del análisis..." -ForegroundColor Yellow
Write-Host "(Presiona Ctrl+C para salir de los logs)" -ForegroundColor Gray
Write-Host ""

Start-Sleep -Seconds 3
docker-compose logs -f pig_analysis
