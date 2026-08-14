-- Gráfico: dispersão entre horas realmente executadas e horas estimadas pelo
-- modelo sklearn treinado, tarefa a tarefa (avaliação retrospectiva real).
SELECT
    TAREFA_ID,
    HORAS_EXECUTADAS,
    HORAS_ESTIMADAS_SKLEARN
FROM MUNKA_ML.ML_ANALISE_RETROSPECTIVA
