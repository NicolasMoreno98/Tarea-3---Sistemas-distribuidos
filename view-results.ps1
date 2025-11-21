#!/usr/bin/env pwsh
# Script para ver los resultados del análisis

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Resultados del Análisis" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que el NameNode esté corriendo
$namenode = docker ps --filter "name=hadoop_namenode" --format "{{.Names}}"
if (-Not $namenode) {
    Write-Host "ERROR: El contenedor hadoop_namenode no está corriendo" -ForegroundColor Red
    Write-Host "Inicia los servicios primero: .\start.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "Top 20 palabras en RESPUESTAS HUMANAS:" -ForegroundColor Green
Write-Host "---------------------------------------" -ForegroundColor Gray
docker exec hadoop_namenode hdfs dfs -cat /output/human_top100/part-r-00000 2>$null | Select-Object -First 20
Write-Host ""

Write-Host "Top 20 palabras en RESPUESTAS LLM:" -ForegroundColor Blue
Write-Host "---------------------------------------" -ForegroundColor Gray
docker exec hadoop_namenode hdfs dfs -cat /output/llm_top100/part-r-00000 2>$null | Select-Object -First 20
Write-Host ""

Write-Host "Top 20 palabras con MAYOR DIFERENCIA:" -ForegroundColor Magenta
Write-Host "---------------------------------------" -ForegroundColor Gray
docker exec hadoop_namenode hdfs dfs -cat /output/top_differences/part-r-00000 2>$null | Select-Object -First 20
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Formato: palabra <TAB> conteo" -ForegroundColor Gray
Write-Host ""
Write-Host "Para ver resultados completos:" -ForegroundColor Yellow
Write-Host "  docker exec -it hadoop_namenode bash" -ForegroundColor White
Write-Host "  hdfs dfs -cat /output/human_wordcount/part-*" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
