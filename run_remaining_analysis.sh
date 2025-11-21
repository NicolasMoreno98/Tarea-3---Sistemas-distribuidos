#!/bin/bash
# Script para ejecutar los 3 análisis secuencialmente monitoreando YARN

check_job_complete() {
    local app_id=$1
    while true; do
        status=$(yarn application -status $app_id 2>/dev/null | grep "Final-State" | awk '{print $3}')
        if [[ "$status" == "SUCCEEDED" ]]; then
            echo "OK: Job completado exitosamente"
            return 0
        elif [[ "$status" == "FAILED" ]] || [[ "$status" == "KILLED" ]]; then
            echo "ERROR: Job fallo"
            return 1
        fi
        sleep 5
    done
}

wait_for_pig() {
    echo "Esperando a que Pig termine..."
    sleep 30
    # Esperar a que no haya procesos pig corriendo
    while pgrep -f "pig.*analyze" > /dev/null; do
        sleep 5
    done
    sleep 5
}

echo "=========================================="
echo "Ejecutando los 3 análisis de Pig"
echo "=========================================="

# Análisis 2: LLM
echo ""
echo "[2/3] Iniciando análisis de respuestas LLM..."
cd /pig
nohup pig -x mapreduce analyze_llm.pig > /tmp/llm.log 2>&1 &
LLM_PID=$!
echo "PID: $LLM_PID"

wait_for_pig

# Verificar resultados LLM
if hdfs dfs -test -e /output/llm_wordcount; then
    echo "OK: Analisis LLM completado"
else
    echo "ADVERTENCIA: No se encontraron resultados LLM"
fi

# Análisis 3: Comparación
echo ""
echo "[3/3] Iniciando análisis comparativo..."
nohup pig -x mapreduce compare_results.pig > /tmp/compare.log 2>&1 &
CMP_PID=$!
echo "PID: $CMP_PID"

wait_for_pig

echo ""
echo "=========================================="
echo "TODOS LOS ANÁLISIS COMPLETADOS"
echo "=========================================="

# Mostrar estructura de salida
echo ""
echo "Archivos generados en HDFS:"
hdfs dfs -ls -R /output/

echo ""
echo "=========================================="
echo "RESULTADOS - Top 20"
echo "=========================================="

echo ""
echo "Palabras mas frecuentes - HUMANOS:"
hdfs dfs -cat /output/human_top100/part-r-00000 2>/dev/null | head -20

echo ""
echo "Palabras mas frecuentes - LLM:"
hdfs dfs -cat /output/llm_top100/part-r-00000 2>/dev/null | head -20

echo ""
echo "Mayores diferencias entre HUMANOS y LLM:"
hdfs dfs -cat /output/top_differences/part-r-00000 2>/dev/null | head -20

echo ""
echo "EXITO: Proceso completo finalizado"
