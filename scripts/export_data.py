#!/usr/bin/env python3
"""
Script para exportar respuestas de PostgreSQL a archivos de texto
para procesamiento con Pig
"""
import psycopg2
import os
import time

def wait_for_postgres(host, port, database, user, password, max_retries=30):
    """Espera a que PostgreSQL esté disponible"""
    print(f"Esperando a que PostgreSQL esté disponible en {host}:{port}...")
    for i in range(max_retries):
        try:
            conn = psycopg2.connect(
                host=host,
                port=port,
                database=database,
                user=user,
                password=password
            )
            conn.close()
            print("PostgreSQL está listo!")
            return True
        except psycopg2.OperationalError:
            print(f"Intento {i+1}/{max_retries}: PostgreSQL no disponible, esperando...")
            time.sleep(2)
    return False

def export_data():
    """Exporta respuestas humanas y LLM a archivos separados"""
    
    # Configuración de conexión
    db_config = {
        'host': os.getenv('POSTGRES_HOST', 'postgres'),
        'port': os.getenv('POSTGRES_PORT', '5432'),
        'database': os.getenv('POSTGRES_DB', 'responses_db'),
        'user': os.getenv('POSTGRES_USER', 'postgres'),
        'password': os.getenv('POSTGRES_PASSWORD', 'postgres')
    }
    
    # Esperar a que PostgreSQL esté disponible
    if not wait_for_postgres(**db_config):
        print("ERROR: No se pudo conectar a PostgreSQL")
        return
    
    # Conectar a PostgreSQL
    print("Conectando a PostgreSQL...")
    conn = psycopg2.connect(**db_config)
    cursor = conn.cursor()
    
    # Crear directorio de salida
    output_dir = '/data/export'
    os.makedirs(output_dir, exist_ok=True)
    
    # Exportar respuestas humanas
    print("\nExportando respuestas humanas...")
    cursor.execute("SELECT human_answer FROM responses WHERE human_answer IS NOT NULL")
    
    with open(f'{output_dir}/human_answers.txt', 'w', encoding='utf-8') as f:
        count = 0
        for row in cursor.fetchall():
            if row[0]:
                # Limpiar y escribir
                answer = row[0].replace('\n', ' ').replace('\t', ' ').strip()
                if answer:
                    f.write(answer + '\n')
                    count += 1
    print(f"Exportadas {count} respuestas humanas")
    
    # Exportar respuestas LLM
    print("\nExportando respuestas LLM...")
    cursor.execute("SELECT llm_answer FROM responses WHERE llm_answer IS NOT NULL")
    
    with open(f'{output_dir}/llm_answers.txt', 'w', encoding='utf-8') as f:
        count = 0
        for row in cursor.fetchall():
            if row[0]:
                # Limpiar y escribir
                answer = row[0].replace('\n', ' ').replace('\t', ' ').strip()
                if answer:
                    f.write(answer + '\n')
                    count += 1
    print(f"Exportadas {count} respuestas LLM")
    
    cursor.close()
    conn.close()
    print("\n¡Exportación completada exitosamente!")

if __name__ == "__main__":
    export_data()
