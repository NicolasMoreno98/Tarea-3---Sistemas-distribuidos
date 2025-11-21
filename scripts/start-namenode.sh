#!/bin/bash
# Script de inicialización para el NameNode de Hadoop

set -e

echo "=== Iniciando NameNode de Hadoop ==="

# Copiar configuraciones
cp /config/*.xml $HADOOP_CONF_DIR/

# Configurar JAVA_HOME en hadoop-env.sh
echo "export JAVA_HOME=${JAVA_HOME}" >> $HADOOP_CONF_DIR/hadoop-env.sh

# Configurar variables de usuario para YARN
export YARN_RESOURCEMANAGER_USER=root
export YARN_NODEMANAGER_USER=root
export HDFS_NAMENODE_USER=root
export HDFS_DATANODE_USER=root
export HDFS_SECONDARYNAMENODE_USER=root

# Iniciar servicio SSH
service ssh start

# Formatear NameNode si es necesario
if [ ! -d "/hadoop/dfs/name/current" ]; then
    echo "Formateando NameNode..."
    $HADOOP_HOME/bin/hdfs namenode -format -force
fi

# Iniciar NameNode
echo "Iniciando NameNode..."
$HADOOP_HOME/bin/hdfs --daemon start namenode

# Iniciar ResourceManager para YARN
echo "Iniciando ResourceManager..."
$HADOOP_HOME/sbin/start-yarn.sh

# Esperar a que HDFS esté disponible
echo "Esperando a que HDFS esté disponible..."
sleep 10

# Crear directorios en HDFS
echo "Creando directorios en HDFS..."
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /input
$HADOOP_HOME/bin/hdfs dfs -mkdir -p /output

echo "=== NameNode iniciado correctamente ==="

# Mantener el contenedor corriendo
tail -f $HADOOP_HOME/logs/*.log
