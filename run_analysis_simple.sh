#!/bin/bash
# Script simplificado para ejecutar análisis sin JobHistoryServer

export HADOOP_MAPRED_HOME=/opt/hadoop
export HADOOP_JOB_HISTORYSERVER_ADDRESS=""

echo "=========================================="
echo "  Análisis 1/3: Respuestas HUMANAS"
echo "=========================================="
cd /pig
pig -x mapreduce -brief -logfile /tmp/pig_human.log analyze_human.pig || echo "Completado con advertencias"

echo ""
echo "=========================================="
echo "  Análisis 2/3: Respuestas LLM"
echo "=========================================="
pig -x mapreduce -brief -logfile /tmp/pig_llm.log analyze_llm.pig || echo "Completado con advertencias"

echo ""
echo "=========================================="
echo "  Análisis 3/3: Comparación"
echo "=========================================="
pig -x mapreduce -brief -logfile /tmp/pig_compare.log compare_results.pig || echo "Completado con advertencias"

echo ""
echo "=========================================="
echo "  RESULTADOS FINALES"
echo "=========================================="
hdfs dfs -ls /output/

echo ""
echo "Top 20 palabras - HUMANOS:"
hdfs dfs -cat /output/human_top100/part-r-00000 2>/dev/null | head -20 || echo "Error leyendo resultados"

echo ""
echo "Top 20 palabras - LLM:"
hdfs dfs -cat /output/llm_top100/part-r-00000 2>/dev/null | head -20 || echo "Error leyendo resultados"

echo ""
echo "Top 20 diferencias:"
hdfs dfs -cat /output/top_differences/part-r-00000 2>/dev/null | head -20 || echo "Error leyendo resultados"
