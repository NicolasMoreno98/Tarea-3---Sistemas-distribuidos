# Tarea 3 - Análisis de Texto con Hadoop y Apache Pig
## Sistemas Distribuidos 2025-2

Este proyecto implementa un sistema de análisis batch para comparar respuestas de Yahoo! Answers vs respuestas generadas por un LLM, utilizando Hadoop HDFS y Apache Pig para procesamiento distribuido.

---

## Descripcion

El sistema realiza análisis de frecuencia de palabras (WordCount) sobre dos conjuntos de datos:
1. **Respuestas de usuarios de Yahoo! Answers**
2. **Respuestas generadas por un LLM**

El procesamiento incluye:
- Tokenizacion de texto
- Limpieza (minusculas, eliminacion de puntuacion)
- Filtrado de stopwords (espanol e ingles)
- Conteo de frecuencia de palabras
- Analisis comparativo entre ambos conjuntos

---

## Arquitectura

```
┌─────────────────┐
│   PostgreSQL    │ ← Almacenamiento persistente
│   (responses)   │
└────────┬────────┘
         │
         ↓ Exportación
┌─────────────────┐
│  Archivos TXT   │ ← human_answers.txt, llm_answers.txt
│  (HDFS Input)   │
└────────┬────────┘
         │
         ↓ Carga a HDFS
┌─────────────────┐
│  Hadoop HDFS    │ ← Almacenamiento distribuido
│  NameNode +     │
│  DataNode       │
└────────┬────────┘
         │
         ↓ Procesamiento MapReduce
┌─────────────────┐
│  Apache Pig     │ ← Scripts de análisis
│  (WordCount)    │
└────────┬────────┘
         │
         ↓ Resultados
┌─────────────────┐
│ Output (HDFS)   │ ← Resultados del análisis
│ /output/...     │
└─────────────────┘
```

---

## Componentes

### Servicios Docker

1. **postgres**: Base de datos PostgreSQL para almacenar los datos de `response.json`
2. **dataloader**: Contenedor que carga `response.json` a PostgreSQL
3. **dataexporter**: Exporta respuestas de PostgreSQL a archivos de texto
4. **namenode**: Hadoop NameNode (coordinador de HDFS)
5. **datanode**: Hadoop DataNode (almacenamiento de datos)
6. **pig_analysis**: Ejecuta scripts de Apache Pig para análisis

### Archivos de Configuración

- `docker-compose.yml`: Orquestación de servicios
- `docker/Dockerfile.hadoop`: Imagen con Hadoop 3.3.6 y Pig 0.17.0
- `docker/Dockerfile.dataloader`: Imagen para carga de datos
- `docker/hadoop-config/*.xml`: Configuraciones de Hadoop (core-site, hdfs-site, etc.)

### Scripts

- `scripts/load_data.py`: Carga `response.json` a PostgreSQL
- `scripts/export_data.py`: Exporta datos a archivos de texto
- `scripts/start-namenode.sh`: Inicializa NameNode de Hadoop
- `scripts/start-datanode.sh`: Inicializa DataNode de Hadoop
- `scripts/run-analysis.sh`: Ejecuta el análisis completo con Pig

### Scripts de Pig

- `pig/analyze_human.pig`: Análisis de respuestas humanas
- `pig/analyze_llm.pig`: Análisis de respuestas LLM
- `pig/compare_results.pig`: Comparación entre ambos conjuntos

---

## Requisitos

- Docker Desktop
- Docker Compose
- Al menos 8 GB de RAM disponible para Docker
- 10 GB de espacio en disco

---

## Instalacion y Ejecucion

### 1. Clonar/Ubicar el proyecto

Asegúrate de tener todos los archivos en el directorio `T3`:

```
T3/
├── docker-compose.yml
├── response.json           ← Archivo de datos (9738 respuestas)
├── docker/
│   ├── Dockerfile.hadoop
│   ├── Dockerfile.dataloader
│   └── hadoop-config/
│       ├── core-site.xml
│       ├── hdfs-site.xml
│       ├── mapred-site.xml
│       └── yarn-site.xml
├── scripts/
│   ├── load_data.py
│   ├── export_data.py
│   ├── start-namenode.sh
│   ├── start-datanode.sh
│   └── run-analysis.sh
├── pig/
│   ├── analyze_human.pig
│   ├── analyze_llm.pig
│   └── compare_results.pig
├── sql/
│   └── schema.sql
├── data/
│   └── stopwords.txt
└── README.md
```

### 2. Construir las imágenes Docker

```powershell
docker-compose build
```

**Nota**: Este proceso puede tardar 10-15 minutos la primera vez, ya que descarga Hadoop (>1GB) y Pig.

### 3. Iniciar todos los servicios

```powershell
docker-compose up -d
```

Esto iniciará los servicios en el siguiente orden:
1. PostgreSQL
2. Dataloader (carga `response.json`)
3. Dataexporter (exporta a TXT)
4. NameNode y DataNode (Hadoop)
5. Pig Analysis (ejecuta análisis)

### 4. Verificar el progreso

Puedes ver los logs en tiempo real:

```powershell
# Ver todos los logs
docker-compose logs -f

# Ver solo los logs del análisis de Pig
docker-compose logs -f pig_analysis

# Ver logs del NameNode
docker-compose logs -f namenode
```

---

## Acceso a Interfaces Web

Una vez que los servicios estén corriendo:

- **Hadoop NameNode UI**: http://localhost:9870
  - Ver estado de HDFS
  - Explorar archivos: http://localhost:9870/explorer.html

- **YARN ResourceManager**: http://localhost:8088
  - Ver jobs de MapReduce en ejecución
  - Historial de jobs

- **DataNode UI**: http://localhost:9864

---

## Resultados del Analisis

### Ubicación de Resultados en HDFS

Los resultados se guardan en HDFS bajo `/output/`:

```
/output/
├── human_wordcount/       ← Conteo completo de palabras (respuestas humanas)
├── human_top100/          ← Top 100 palabras más frecuentes (humanos)
├── llm_wordcount/         ← Conteo completo de palabras (respuestas LLM)
├── llm_top100/            ← Top 100 palabras más frecuentes (LLM)
├── comparison/            ← Comparación completa palabra por palabra
└── top_differences/       ← Top 50 palabras con mayor diferencia
```

### Ver Resultados

#### Opción 1: Desde los logs del análisis

Los resultados principales se muestran automáticamente al finalizar:

```powershell
docker-compose logs pig_analysis | tail -100
```

#### Opción 2: Conectarse al contenedor

```powershell
# Conectarse al NameNode
docker exec -it hadoop_namenode bash

# Ver top 20 palabras en respuestas humanas
hdfs dfs -cat /output/human_top100/part-r-00000 | head -20

# Ver top 20 palabras en respuestas LLM
hdfs dfs -cat /output/llm_top100/part-r-00000 | head -20

# Ver palabras con mayor diferencia
hdfs dfs -cat /output/top_differences/part-r-00000 | head -20

# Descargar resultados completos
hdfs dfs -get /output/human_wordcount ./results_human
hdfs dfs -get /output/llm_wordcount ./results_llm
hdfs dfs -get /output/comparison ./results_comparison
```

#### Opción 3: Copiar resultados al host

```powershell
# Crear directorio para resultados
New-Item -ItemType Directory -Force -Path ".\results"

# Copiar desde el contenedor
docker cp hadoop_namenode:/opt/hadoop/results_human .\results\
docker cp hadoop_namenode:/opt/hadoop/results_llm .\results\
docker cp hadoop_namenode:/opt/hadoop/results_comparison .\results\
```

---

## Formato de Resultados

### WordCount (human_wordcount, llm_wordcount)

Formato: `palabra\tconteo`

Ejemplo:
```
answer	5234
question	4891
information	3456
help	2987
...
```

### Comparación (comparison, top_differences)

Formato: `palabra\tconteo_humano\tconteo_llm\tdiferencia_absoluta`

Ejemplo:
```
answer	5234	4123	1111
question	4891	5234	343
information	3456	2987	469
...
```

---

## Comandos Utiles

### Gestión de Contenedores

```powershell
# Iniciar servicios
docker-compose up -d

# Detener servicios
docker-compose down

# Reiniciar un servicio específico
docker-compose restart namenode

# Ver estado de los servicios
docker-compose ps

# Ver logs en tiempo real
docker-compose logs -f

# Eliminar todo (incluyendo volúmenes)
docker-compose down -v
```

### Interacción con HDFS

```powershell
# Conectarse al NameNode
docker exec -it hadoop_namenode bash

# Listar archivos en HDFS
hdfs dfs -ls /

# Ver contenido de un archivo
hdfs dfs -cat /input/human_answers.txt | head -10

# Verificar salud del cluster
hdfs dfsadmin -report

# Ver uso de espacio
hdfs dfs -du -h /
```

### Ejecutar Análisis Manualmente

Si necesitas re-ejecutar el análisis:

```powershell
# Eliminar outputs anteriores
docker exec -it hadoop_namenode hdfs dfs -rm -r /output/*

# Ejecutar análisis de nuevo
docker exec -it hadoop_namenode bash /scripts/run-analysis.sh
```

---

## 🧹 Limpieza

Para limpiar completamente el entorno:

```powershell
# Detener y eliminar contenedores
docker-compose down

# Eliminar volúmenes (datos persistentes)
docker-compose down -v

# Eliminar imágenes construidas
docker rmi $(docker images | grep 't3' | awk '{print $3}')

# Limpiar sistema Docker completo (opcional)
docker system prune -a
```

---

## Troubleshooting

### Problema: PostgreSQL no inicia

**Error**: `FATAL: data directory "/var/lib/postgresql/data" has wrong ownership`

**Solución**:
```powershell
docker-compose down -v
docker-compose up -d postgres
```

### Problema: NameNode no formatea

**Error**: `NameNode is not formatted`

**Solución**:
```powershell
docker exec -it hadoop_namenode hdfs namenode -format -force
docker-compose restart namenode
```

### Problema: DataNode no se conecta

**Error**: `DataNode: Incompatible clusterIDs`

**Solución**:
```powershell
docker-compose down
docker volume rm t3_datanode_data t3_namenode_data
docker-compose up -d
```

### Problema: Pig no encuentra archivos

**Error**: `Input path does not exist`

**Solución**:
```powershell
# Verificar que los archivos estén en HDFS
docker exec -it hadoop_namenode hdfs dfs -ls /input/

# Si no están, copiarlos manualmente
docker exec -it hadoop_namenode bash
hdfs dfs -put /data/export/human_answers.txt /input/
hdfs dfs -put /data/export/llm_answers.txt /input/
hdfs dfs -put /data/stopwords.txt /input/
```

### Verificar salud del sistema

```powershell
# Ver estado de servicios
docker-compose ps

# Verificar logs de errores
docker-compose logs | grep -i error

# Verificar conectividad entre contenedores
docker exec -it hadoop_namenode ping datanode
```

---

## Tecnologias Utilizadas

- **PostgreSQL 15**: Base de datos relacional
- **Hadoop 3.3.6**: Framework de procesamiento distribuido
- **Apache Pig 0.17.0**: Lenguaje de alto nivel para análisis de datos
- **Docker & Docker Compose**: Containerización y orquestación
- **Python 3.9**: Scripts de carga y exportación
- **Java 8**: Runtime para Hadoop y Pig

---

## Estructura de Datos

### Schema de PostgreSQL

```sql
CREATE TABLE responses (
    id SERIAL PRIMARY KEY,
    question_id VARCHAR(50) NOT NULL,
    question TEXT NOT NULL,
    human_answer TEXT,
    llm_answer TEXT,
    source VARCHAR(20),
    score FLOAT,
    timestamp BIGINT
);
```

### Datos de Entrada

- **Total respuestas**: 9,738
- **Respuestas únicas de humanos**: ~9,738
- **Respuestas del LLM**: ~9,738
- **Fuente**: Yahoo! Answers dataset

---

## Caracteristicas Implementadas

### Requisitos Cumplidos

- [x] **Ingesta de Datos**: Extracción desde PostgreSQL
- [x] **Ecosistema Hadoop**: HDFS configurado y funcionando
- [x] **Apache Pig**: Scripts de análisis implementados
- [x] **Tokenización**: Separación en palabras individuales
- [x] **Limpieza**: Minúsculas, eliminación de puntuación
- [x] **Filtrado de Stopwords**: Lista español/inglés
- [x] **Conteo (WordCount)**: Frecuencia de palabras
- [x] **Análisis Comparativo**: Humanos vs LLM por separado
- [x] **Docker**: Completamente containerizado
- [x] **Docker Compose**: Orquestación de servicios

### Caracteristicas Adicionales

- [x] Top 100 palabras más frecuentes por cada conjunto
- [x] Análisis de diferencias entre conjuntos
- [x] Interfaces web para monitoreo (Hadoop UI, YARN)
- [x] Scripts de inicialización automática
- [x] Healthchecks para servicios
- [x] Persistencia de datos con volúmenes Docker

---

## Autor

**Tarea 3 - Sistemas Distribuidos 2025-2**

---

## Licencia

Este proyecto es parte de una tarea académica para el curso de Sistemas Distribuidos.

---

## Agradecimientos

- Dataset basado en Yahoo! Answers
- Apache Hadoop y Apache Pig communities
- Docker community

---

## Soporte

Si encuentras problemas:

1. Revisa la sección de **Troubleshooting**
2. Verifica los logs: `docker-compose logs`
3. Asegúrate de tener suficiente RAM (8GB+)
4. Verifica que los puertos 5432, 9000, 9870, 9864, 8088 estén libres

---

**Listo para ejecutar!**

```powershell
docker-compose up -d
docker-compose logs -f pig_analysis
```

Espera aproximadamente 5-10 minutos para que todo el proceso se complete.
