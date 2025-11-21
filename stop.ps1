#!/usr/bin/env pwsh
# Script para detener todos los servicios

Write-Host "Deteniendo servicios de Hadoop y Pig..." -ForegroundColor Yellow

docker-compose down

Write-Host ""
Write-Host "✓ Servicios detenidos" -ForegroundColor Green
Write-Host ""
Write-Host "Para eliminar también los datos persistentes, ejecuta:" -ForegroundColor Cyan
Write-Host "  docker-compose down -v" -ForegroundColor White
