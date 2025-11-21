#!/bin/bash
# Script de inicialización para el DataNode de Hadoop

set -e

echo "=== Iniciando DataNode de Hadoop ==="

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

# Esperar a que el NameNode esté disponible
echo "Esperando a que el NameNode esté disponible..."
sleep 15

# Iniciar DataNode
echo "Iniciando DataNode..."
$HADOOP_HOME/bin/hdfs --daemon start datanode

# Iniciar NodeManager para YARN
echo "Iniciando NodeManager..."
$HADOOP_HOME/sbin/yarn-daemon.sh start nodemanager

echo "=== DataNode iniciado correctamente ==="

# Mantener el contenedor corriendo
tail -f $HADOOP_HOME/logs/*.log
