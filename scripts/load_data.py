#!/usr/bin/env python3
"""
Script para cargar datos de response.json a PostgreSQL
"""
import json
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

def load_json_to_postgres():
    """Carga los datos de response.json a PostgreSQL"""
    
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
    
    # Leer el archivo JSON
    json_file = '/data/response.json'
    print(f"Leyendo archivo {json_file}...")
    
    try:
        with open(json_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"ERROR: Archivo {json_file} no encontrado")
        return
    except json.JSONDecodeError as e:
        print(f"ERROR: Error al decodificar JSON: {e}")
        return
    
    # Conectar a PostgreSQL
    print("Conectando a PostgreSQL...")
    conn = psycopg2.connect(**db_config)
    cursor = conn.cursor()
    
    # Crear la tabla si no existe
    print("Creando tabla responses...")
    with open('/sql/schema.sql', 'r') as f:
        schema = f.read()
        cursor.execute(schema)
    conn.commit()
    
    # Insertar datos
    responses = data.get('responses', [])
    print(f"Insertando {len(responses)} respuestas...")
    
    insert_query = """
    INSERT INTO responses (question_id, question, human_answer, llm_answer, source, score, timestamp)
    VALUES (%s, %s, %s, %s, %s, %s, %s)
    """
    
    inserted = 0
    for response in responses:
        try:
            cursor.execute(insert_query, (
                response.get('question_id'),
                response.get('question'),
                response.get('human_answer'),
                response.get('llm_answer'),
                response.get('source'),
                response.get('score'),
                response.get('timestamp')
            ))
            inserted += 1
            if inserted % 1000 == 0:
                print(f"Insertadas {inserted} respuestas...")
                conn.commit()
        except Exception as e:
            print(f"Error al insertar respuesta {response.get('question_id')}: {e}")
            continue
    
    conn.commit()
    
    # Verificar inserción
    cursor.execute("SELECT COUNT(*) FROM responses")
    count = cursor.fetchone()[0]
    print(f"\nTotal de respuestas insertadas: {count}")
    
    cursor.execute("SELECT source, COUNT(*) FROM responses GROUP BY source")
    for row in cursor.fetchall():
        print(f"  {row[0]}: {row[1]}")
    
    cursor.close()
    conn.close()
    print("\n¡Carga completada exitosamente!")

if __name__ == "__main__":
    load_json_to_postgres()
