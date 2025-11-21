-- Script de Apache Pig para analizar respuestas HUMANAS de Yahoo
-- Análisis de frecuencia de palabras con limpieza y filtrado

-- Cargar datos desde HDFS
human_data = LOAD '/input/human_answers.txt' USING PigStorage('\t') AS (answer:chararray);

-- Tokenización: separar en palabras
tokens = FOREACH human_data GENERATE FLATTEN(TOKENIZE(LOWER(answer))) AS word;

-- Limpieza: eliminar signos de puntuación y caracteres especiales
cleaned = FOREACH tokens GENERATE REGEX_EXTRACT(word, '([a-z]+)', 1) AS word;

-- Filtrar palabras vacías (null o strings vacíos)
filtered = FILTER cleaned BY word IS NOT NULL AND word != '';

-- Cargar lista de stopwords en español e inglés
stopwords = LOAD '/input/stopwords.txt' USING PigStorage() AS (stop:chararray);

-- Realizar un LEFT JOIN para filtrar stopwords
joined = JOIN filtered BY word LEFT OUTER, stopwords BY stop;

-- Mantener solo las palabras que NO son stopwords (stop será null)
words_no_stop = FILTER joined BY stop IS NULL;

-- Extraer solo la palabra
final_words = FOREACH words_no_stop GENERATE filtered::word AS word;

-- Agrupar por palabra
grouped = GROUP final_words BY word;

-- Contar frecuencia de cada palabra
word_count = FOREACH grouped GENERATE 
    group AS word, 
    COUNT(final_words) AS count;

-- Ordenar por frecuencia descendente
sorted = ORDER word_count BY count DESC;

-- Guardar resultados en HDFS
STORE sorted INTO '/output/human_wordcount' USING PigStorage('\t');

-- Guardar también las top 100 palabras
top_100 = LIMIT sorted 100;
STORE top_100 INTO '/output/human_top100' USING PigStorage('\t');
