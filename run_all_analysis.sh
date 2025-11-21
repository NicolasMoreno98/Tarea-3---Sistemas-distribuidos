#!/bin/bash
# Script para ejecutar todos los análisis de Pig secuencialmente

set -e

echo "========================================"
echo "  ANÁLISIS COMPLETO DE DATOS"
echo "========================================"
echo ""

# Verificar que los datos están en HDFS
echo "Verificando datos en HDFS..."
hdfs dfs -ls /input/
echo ""

# Análisis 1: Respuestas Humanas
echo "========================================"
echo "1/3: Analizando respuestas HUMANAS"
echo "========================================"
cd /pig
pig -x mapreduce analyze_human.pig
echo "✓ Análisis humano completado"
echo ""

# Análisis 2: Respuestas LLM
echo "========================================"
echo "2/3: Analizando respuestas LLM"
echo "========================================"
pig -x mapreduce analyze_llm.pig
echo "✓ Análisis LLM completado"
echo ""

# Análisis 3: Comparación
echo "========================================"
echo "3/3: Realizando análisis comparativo"
echo "========================================"
pig -x mapreduce compare_results.pig
echo "✓ Análisis comparativo completado"
echo ""

echo "========================================"
echo "  RESULTADOS"
echo "========================================"
echo ""
echo "Top 20 palabras más frecuentes - HUMANOS:"
echo "----------------------------------------"
hdfs dfs -cat /output/human_top100/part-r-00000 | head -20
echo ""
echo "Top 20 palabras más frecuentes - LLM:"
echo "----------------------------------------"
hdfs dfs -cat /output/llm_top100/part-r-00000 | head -20
echo ""
echo "Top 20 palabras con MAYOR DIFERENCIA:"
echo "----------------------------------------"
hdfs dfs -cat /output/top_differences/part-r-00000 | head -20
echo ""
echo "========================================"
echo "  ✓ ANÁLISIS COMPLETADO EXITOSAMENTE"
echo "========================================"
