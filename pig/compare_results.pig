-- Script de Apache Pig para análisis comparativo
-- Combina resultados de ambos análisis para comparación

-- Cargar resultados de análisis humano
human_words = LOAD '/output/human_wordcount' USING PigStorage('\t') 
    AS (word:chararray, human_count:long);

-- Cargar resultados de análisis LLM
llm_words = LOAD '/output/llm_wordcount' USING PigStorage('\t') 
    AS (word:chararray, llm_count:long);

-- Join completo (outer join) para comparar todas las palabras
compared = JOIN human_words BY word FULL OUTER, llm_words BY word;

-- Generar estadísticas comparativas
stats = FOREACH compared GENERATE 
    (human_words::word IS NOT NULL ? human_words::word : llm_words::word) AS word,
    (human_words::human_count IS NOT NULL ? human_words::human_count : 0) AS human_count,
    (llm_words::llm_count IS NOT NULL ? llm_words::llm_count : 0) AS llm_count,
    ABS((human_words::human_count IS NOT NULL ? human_words::human_count : 0) - 
        (llm_words::llm_count IS NOT NULL ? llm_words::llm_count : 0)) AS diff;

-- Ordenar por diferencia para ver las palabras más distintivas
sorted_diff = ORDER stats BY diff DESC;

-- Guardar resultados comparativos
STORE sorted_diff INTO '/output/comparison' USING PigStorage('\t');

-- Top 50 palabras con mayor diferencia
top_diff = LIMIT sorted_diff 50;
STORE top_diff INTO '/output/top_differences' USING PigStorage('\t');
