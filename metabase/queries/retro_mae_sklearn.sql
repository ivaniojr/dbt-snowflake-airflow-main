-- KPI: MAE (erro médio absoluto) do modelo sklearn treinado, avaliado
-- retrospectivamente sobre tarefas reais do Snowflake (horas executadas reais).
SELECT ROUND(AVG(ERRO_ABSOLUTO_SKLEARN), 2) AS MAE_SKLEARN
FROM MUNKA_ML.ML_ANALISE_RETROSPECTIVA
