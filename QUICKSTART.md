# 🚀 Inicio Rápido - Tarea 3

## Ejecución en 3 Pasos

### 1️⃣ Construir e iniciar
```powershell
.\start.ps1
```

### 2️⃣ Esperar (5-10 minutos)
El script mostrará los logs automáticamente. Espera a ver:
```
✓ ¡Procesamiento completado exitosamente!
```

### 3️⃣ Ver resultados
```powershell
.\view-results.ps1
```

---

## 📊 Interfaces Web

Mientras se ejecuta el análisis, puedes monitorear:

- **Hadoop HDFS**: http://localhost:9870
- **YARN Jobs**: http://localhost:8088
- **DataNode**: http://localhost:9864

---

## 🛑 Detener

```powershell
.\stop.ps1
```

---

## 📚 Documentación Completa

Para más detalles, consulta:
- `README.md` - Guía completa
- `ARCHITECTURE.md` - Arquitectura del sistema

---

## ⚡ Comandos Rápidos

```powershell
# Ver logs en tiempo real
docker-compose logs -f pig_analysis

# Ver estado de servicios
docker-compose ps

# Conectarse al NameNode
docker exec -it hadoop_namenode bash

# Ver archivos en HDFS
docker exec -it hadoop_namenode hdfs dfs -ls /output/

# Reiniciar todo
docker-compose restart

# Limpiar todo (incluyendo datos)
docker-compose down -v
```

---

## 🔧 Troubleshooting

### Problema: "Docker no está corriendo"
**Solución**: Inicia Docker Desktop

### Problema: Puertos en uso
**Solución**: Detén otros servicios en puertos 5432, 9000, 9870, 9864, 8088

### Problema: Poco espacio en disco
**Solución**: 
```powershell
docker system prune -a
```

### Problema: Análisis no completa
**Solución**:
```powershell
# Ver logs para errores
docker-compose logs pig_analysis

# Reintentar
docker-compose restart pig_analysis
```

---

## 📈 Qué Esperar

El sistema procesará **9,738 respuestas** y generará:

✅ Análisis de palabras en respuestas humanas  
✅ Análisis de palabras en respuestas LLM  
✅ Comparación entre ambos conjuntos  
✅ Top 100 palabras más frecuentes  
✅ Top 50 palabras con mayor diferencia  

---

## 💡 Tips

- **Primera vez**: La construcción de imágenes tarda 10-15 min
- **Siguientes ejecuciones**: Solo 5-10 min
- **RAM mínima**: 8 GB disponibles para Docker
- **Espacio**: ~10 GB (Hadoop + datos)

---

**¿Listo?**

```powershell
.\start.ps1
```

🎉 ¡Disfruta del análisis!
