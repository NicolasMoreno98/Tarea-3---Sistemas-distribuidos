-- Schema para almacenar las respuestas de Yahoo y LLM
CREATE TABLE IF NOT EXISTS responses (
    id SERIAL PRIMARY KEY,
    question_id VARCHAR(50) NOT NULL,
    question TEXT NOT NULL,
    human_answer TEXT,
    llm_answer TEXT,
    source VARCHAR(20),
    score FLOAT,
    timestamp BIGINT
);

-- Índices para mejorar las consultas
CREATE INDEX IF NOT EXISTS idx_question_id ON responses(question_id);
CREATE INDEX IF NOT EXISTS idx_source ON responses(source);
