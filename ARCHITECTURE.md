# Arquitectura del Sistema - Tarea 3

## Visión General

Este documento describe la arquitectura del sistema de análisis batch implementado para comparar respuestas de Yahoo! Answers vs respuestas generadas por un LLM.

---

## Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────────┐
│                        DOCKER COMPOSE NETWORK                        │
│                         (hadoop_network)                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐        │
│  │  PostgreSQL  │────>│  DataLoader  │────>│ DataExporter │        │
│  │  (responses) │     │  (Python)    │     │  (Python)    │        │
│  │              │     │              │     │              │        │
│  │  Port: 5432  │     │ Carga JSON   │     │ Export TXT   │        │
│  └──────────────┘     └──────────────┘     └──────┬───────┘        │
│                                                     │                │
│                                                     v                │
│                                          ┌──────────────────┐       │
│                                          │ Shared Volume    │       │
│                                          │ (hadoop_data)    │       │
│                                          │                  │       │
│                                          │ - human_answers  │       │
│                                          │ - llm_answers    │       │
│                                          │ - stopwords      │       │
│                                          └────────┬─────────┘       │
│                                                   │                 │
│  ┌────────────────────────────────────────────────┘                │
│  │                                                                  │
│  v                                                                  │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │                    HADOOP CLUSTER                         │     │
│  │                                                            │     │
│  │  ┌─────────────────┐         ┌─────────────────┐        │     │
│  │  │   NameNode      │◄────────│   DataNode      │        │     │
│  │  │                 │         │                 │        │     │
│  │  │ - HDFS Master   │         │ - HDFS Storage  │        │     │
│  │  │ - Port: 9870    │         │ - Port: 9864    │        │     │
│  │  │ - Port: 9000    │         │                 │        │     │
│  │  │                 │         │                 │        │     │
│  │  │ /input/         │         │                 │        │     │
│  │  │ /output/        │         │                 │        │     │
│  │  │                 │         │                 │        │     │
│  │  │ YARN RM         │         │ YARN NM         │        │     │
│  │  │ - Port: 8088    │         │                 │        │     │
│  │  └─────────────────┘         └─────────────────┘        │     │
│  │                                                            │     │
│  └──────────────────────────────────────────────────────────┘     │
│                          │                                          │
│                          v                                          │
│  ┌──────────────────────────────────────────────────────────┐     │
│  │              Apache Pig Analysis                          │     │
│  │                                                            │     │
│  │  ┌─────────────────┐  ┌─────────────────┐               │     │
│  │  │ analyze_human   │  │  analyze_llm    │               │     │
│  │  │   .pig          │  │    .pig         │               │     │
│  │  │                 │  │                 │               │     │
│  │  │ 1. Load         │  │ 1. Load         │               │     │
│  │  │ 2. Tokenize     │  │ 2. Tokenize     │               │     │
│  │  │ 3. Clean        │  │ 3. Clean        │               │     │
│  │  │ 4. Filter       │  │ 4. Filter       │               │     │
│  │  │    stopwords    │  │    stopwords    │               │     │
│  │  │ 5. Group & Count│  │ 5. Group & Count│               │     │
│  │  │ 6. Sort         │  │ 6. Sort         │               │     │
│  │  └────────┬────────┘  └────────┬────────┘               │     │
│  │           │                     │                         │     │
│  │           └──────────┬──────────┘                        │     │
│  │                      v                                    │     │
│  │           ┌─────────────────┐                            │     │
│  │           │ compare_results │                            │     │
│  │           │     .pig        │                            │     │
│  │           │                 │                            │     │
│  │           │ 1. Join         │                            │     │
│  │           │ 2. Calculate    │                            │     │
│  │           │    differences  │                            │     │
│  │           │ 3. Sort by diff │                            │     │
│  │           └────────┬────────┘                            │     │
│  │                    │                                      │     │
│  └────────────────────┼──────────────────────────────────┘     │
│                       │                                          │
│                       v                                          │
│            ┌──────────────────┐                                 │
│            │  HDFS Output     │                                 │
│            │                  │                                 │
│            │ /output/         │                                 │
│            │ ├─ human_*       │                                 │
│            │ ├─ llm_*         │                                 │
│            │ └─ comparison/   │                                 │
│            └──────────────────┘                                 │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Flujo de Datos

### Fase 1: Ingesta (PostgreSQL)

1. **DataLoader** lee `response.json`
2. Parsea el JSON (9738 respuestas)
3. Conecta a PostgreSQL
4. Ejecuta `schema.sql` para crear tabla
5. Inserta respuestas con información:
   - question_id
   - question
   - human_answer
   - llm_answer
   - source
   - score
   - timestamp

### Fase 2: Exportación

1. **DataExporter** conecta a PostgreSQL
2. Ejecuta query: `SELECT human_answer FROM responses WHERE human_answer IS NOT NULL`
3. Escribe a `human_answers.txt` (un answer por línea)
4. Ejecuta query: `SELECT llm_answer FROM responses WHERE llm_answer IS NOT NULL`
5. Escribe a `llm_answers.txt` (un answer por línea)
6. Los archivos se guardan en volumen compartido `hadoop_data`

### Fase 3: Carga a HDFS

1. **NameNode** inicia y formatea HDFS
2. **DataNode** se conecta al NameNode
3. Script `run-analysis.sh` copia archivos a HDFS:
   ```bash
   hdfs dfs -put human_answers.txt /input/
   hdfs dfs -put llm_answers.txt /input/
   hdfs dfs -put stopwords.txt /input/
   ```

### Fase 4: Procesamiento MapReduce con Pig

#### Análisis de Respuestas Humanas (`analyze_human.pig`)

```
Input: /input/human_answers.txt
      ↓
   TOKENIZE → words
      ↓
   CLEAN (regex) → cleaned_words
      ↓
   FILTER nulls/empty
      ↓
   FILTER stopwords
      ↓
   GROUP BY word
      ↓
   COUNT
      ↓
   ORDER BY count DESC
      ↓
Output: /output/human_wordcount/
        /output/human_top100/
```

#### Análisis de Respuestas LLM (`analyze_llm.pig`)

Mismo flujo que arriba, pero con:
```
Input: /input/llm_answers.txt
Output: /output/llm_wordcount/
        /output/llm_top100/
```

#### Análisis Comparativo (`compare_results.pig`)

```
Input: /output/human_wordcount/ + /output/llm_wordcount/
      ↓
   FULL OUTER JOIN by word
      ↓
   CALCULATE differences
      ↓
   ORDER BY difference DESC
      ↓
Output: /output/comparison/
        /output/top_differences/
```

---

## Tecnologías y Versiones

| Componente | Versión | Propósito |
|------------|---------|-----------|
| PostgreSQL | 15-alpine | Base de datos relacional |
| Python | 3.9-slim | Scripts de ETL |
| Hadoop | 3.3.6 | Framework distribuido + HDFS |
| Apache Pig | 0.17.0 | Lenguaje de análisis (MapReduce) |
| Java | OpenJDK 8 | Runtime para Hadoop/Pig |
| Docker | Latest | Containerización |
| Docker Compose | Latest | Orquestación |

---

## Comunicación entre Servicios

### Red Docker

Todos los servicios están en la red `hadoop_network` (bridge driver).

### DNS Interno

Los servicios se comunican por nombre de host:
- `postgres` → PostgreSQL (puerto 5432)
- `namenode` → Hadoop NameNode (puerto 9000, 9870)
- `datanode` → Hadoop DataNode (puerto 9864)

### Volúmenes Compartidos

1. **postgres_data**: Persistencia de PostgreSQL
2. **namenode_data**: Metadata de HDFS
3. **datanode_data**: Bloques de datos de HDFS
4. **hadoop_data**: Intercambio de archivos entre contenedores

---

## MapReduce en Pig

### Pig Latin → MapReduce

Pig traduce scripts de alto nivel a jobs MapReduce:

```pig
grouped = GROUP words BY word;
count = FOREACH grouped GENERATE group, COUNT(words);
```

Se convierte en:

```
MAP:    (word) → (word, 1)
REDUCE: (word, [1,1,1,...]) → (word, sum)
```

### Ejecución Distribuida

1. Pig envía job a YARN ResourceManager
2. ResourceManager asigna NodeManager
3. NodeManager ejecuta Map tasks en DataNodes
4. Shuffle & Sort distribuye datos
5. Reduce tasks agregan resultados
6. Output se escribe a HDFS

---

## Escalabilidad

### Configuración Actual (Single Node)

- 1 NameNode
- 1 DataNode
- Replicación: 1 (sin redundancia)
- Ideal para desarrollo/pruebas

### Configuración Multi-Nodo (Producción)

Para escalar horizontalmente:

```yaml
# docker-compose.yml modificado
services:
  datanode1:
    ...
  datanode2:
    ...
  datanode3:
    ...

# hdfs-site.xml modificado
<property>
  <name>dfs.replication</name>
  <value>3</value>  <!-- 3 réplicas -->
</property>
```

---

## Seguridad

### Configuraciones de Seguridad

- **HDFS Permissions**: Deshabilitadas (`dfs.permissions.enabled=false`)
- **PostgreSQL**: Usuario/contraseña en variables de entorno
- **Network**: Red aislada bridge
- **Puertos**: Expuestos solo los necesarios para UI

### Mejoras de Seguridad Recomendadas

Para producción:
1. Habilitar autenticación Kerberos en Hadoop
2. Usar secretos de Docker para credenciales
3. Configurar SSL/TLS para PostgreSQL
4. Habilitar permisos de HDFS
5. Limitar acceso a red externa

---

## Monitoreo y Debugging

### Interfaces Web

- **Hadoop NameNode UI** (9870): Estado de HDFS, utilización
- **YARN ResourceManager** (8088): Jobs MapReduce, métricas
- **DataNode UI** (9864): Estado del DataNode

### Logs

```bash
# Ver logs en tiempo real
docker-compose logs -f [servicio]

# Logs de Hadoop
docker exec hadoop_namenode cat /opt/hadoop/logs/*.log

# Logs de Pig
docker exec pig_analysis cat /tmp/pig*.log
```

### Métricas HDFS

```bash
# Reporte de salud
hdfs dfsadmin -report

# Uso de espacio
hdfs dfs -du -h /

# Estado del cluster
yarn node -list
```

---

## Optimizaciones

### Configuraciones de Rendimiento

1. **Memoria YARN**: Ajustable en `yarn-site.xml`
2. **Paralelismo Pig**: Configurar PARALLEL en scripts
3. **Tamaño de bloques HDFS**: Default 128MB
4. **Replicación**: Ajustar según disponibilidad vs espacio

### Ejemplo de Optimización en Pig

```pig
-- Sin optimización
grouped = GROUP words BY word;

-- Con optimización
grouped = GROUP words BY word PARALLEL 4;
```

---

## Limitaciones Conocidas

1. **Single Node**: No hay alta disponibilidad
2. **Sin Kerberos**: Seguridad básica
3. **Replicación 1**: Sin redundancia de datos
4. **Memoria**: Requiere mínimo 8GB RAM
5. **Windows**: Puede requerir ajustes en scripts bash

---

## Futuras Mejoras

1. Integración con Apache Hive para queries SQL
2. Dashboard de visualización (Grafana)
3. Automatización de re-procesamiento
4. Export de resultados a CSV/JSON
5. API REST para consultar resultados
6. Integración con Apache Spark para procesamiento más rápido
7. Implementación de Apache Sqoop para import desde PostgreSQL

---

## Referencias

- [Apache Hadoop Documentation](https://hadoop.apache.org/docs/r3.3.6/)
- [Apache Pig Documentation](https://pig.apache.org/docs/r0.17.0/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/15/)

---

**Última actualización**: 2025-01-27
