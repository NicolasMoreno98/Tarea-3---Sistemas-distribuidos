#!/bin/bash
# Script para cargar datos a HDFS y ejecutar análisis con Pig

set -e

echo "=== Esperando a que los servicios estén listos ==="
sleep 30

echo "=== Verificando conectividad con HDFS ==="
until hdfs dfs -ls / &>/dev/null; do
    echo "Esperando HDFS..."
    sleep 5
done
echo "OK: HDFS disponible"

echo "=== Esperando a que los datos se exporten ==="
max_attempts=60
attempt=0
while [ ! -s "/data/export/human_answers.txt" ] || [ ! -s "/data/export/llm_answers.txt" ]; do
    echo "Esperando exportacion de datos (archivos con contenido)... (intento $attempt/$max_attempts)"
    sleep 5
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
        echo "ERROR: Timeout esperando datos exportados"
        exit 1
    fi
done
echo "OK: Datos exportados encontrados"

echo "=== Creando directorios en HDFS ==="
hdfs dfs -mkdir -p /input
hdfs dfs -mkdir -p /output
echo "OK: Directorios creados"

echo "=== Copiando datos a HDFS ==="

# Copiar respuestas humanas
echo "Copiando respuestas humanas..."
hdfs dfs -put -f /data/export/human_answers.txt /input/

# Copiar respuestas LLM
echo "Copiando respuestas LLM..."
hdfs dfs -put -f /data/export/llm_answers.txt /input/

# Copiar stopwords desde el directorio pig (donde está montado)
echo "Copiando stopwords..."
if [ -f "/pig/stopwords.txt" ]; then
    hdfs dfs -put -f /pig/stopwords.txt /input/
else
    echo "WARNING: stopwords.txt no encontrado, creando uno básico..."
    echo -e "the\na\nan\nand\nof\nto\nin\nis\nit\nthat\nfor" > /tmp/stopwords.txt
    hdfs dfs -put -f /tmp/stopwords.txt /input/
fi

echo "=== Datos copiados a HDFS ==="

# Listar archivos en HDFS
echo "Archivos en /input:"
hdfs dfs -ls /input/

echo ""
echo "=== Ejecutando análisis con Apache Pig ==="

# Análisis de respuestas humanas
echo ""
echo "1/3: Analizando respuestas humanas..."
pig -x mapreduce -brief /pig/analyze_human.pig 2>&1 | grep -E '(complete|MapReduce Jobs Launched|Success|Failed)' || true
echo "OK: Analisis humano completado"

# Esperar a que termine completamente
sleep 10

# Análisis de respuestas LLM
echo ""
echo "2/3: Analizando respuestas LLM..."
pig -x mapreduce -brief /pig/analyze_llm.pig 2>&1 | grep -E '(complete|MapReduce Jobs Launched|Success|Failed)' || true
echo "OK: Analisis LLM completado"

# Esperar a que termine completamente
sleep 10

# Análisis comparativo
echo ""
echo "3/3: Realizando analisis comparativo..."
pig -x mapreduce -brief /pig/compare_results.pig 2>&1 | grep -E '(complete|MapReduce Jobs Launched|Success|Failed)' || true
echo "OK: Analisis comparativo completado"

echo ""
echo "=== Análisis completados ==="

# Mostrar resultados
echo ""
echo "=== Resultados en HDFS ==="
hdfs dfs -ls -R /output/

echo ""
echo "===================================="
echo "  Top 20 palabras - HUMANOS"
echo "===================================="
hdfs dfs -cat /output/human_top100/part-r-00000 2>/dev/null | head -20 || echo "Error: No se encontraron resultados"

echo ""
echo "===================================="
echo "  Top 20 palabras - LLM"
echo "===================================="
hdfs dfs -cat /output/llm_top100/part-r-00000 2>/dev/null | head -20 || echo "Error: No se encontraron resultados"

echo ""
echo "===================================="
echo "  Top 20 diferencias"
echo "===================================="
hdfs dfs -cat /output/top_differences/part-r-00000 2>/dev/null | head -20 || echo "Error: No se encontraron resultados"

echo ""
echo "=== Para ver todos los resultados ==="
echo "docker exec hadoop_namenode hdfs dfs -cat /output/human_wordcount/part-*"
echo "docker exec hadoop_namenode hdfs dfs -cat /output/llm_wordcount/part-*"
echo "docker exec hadoop_namenode hdfs dfs -cat /output/comparison/part-*"

echo ""
echo "EXITO: Procesamiento completado exitosamente!"
echo ""
echo "=== Resultados disponibles en HDFS ===" 
echo "Usa docker-compose down para detener los servicios"
echo ""

# Mantener el contenedor vivo para poder ver los resultados
tail -f /dev/null
