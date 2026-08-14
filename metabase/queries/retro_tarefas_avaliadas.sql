-- KPI: total de tarefas reais do Snowflake avaliadas retrospectivamente
-- (previsão do modelo de ML treinado vs. horas realmente executadas).
SELECT COUNT(*) AS TAREFAS_AVALIADAS
FROM MUNKA_ML.ML_ANALISE_RETROSPECTIVA
