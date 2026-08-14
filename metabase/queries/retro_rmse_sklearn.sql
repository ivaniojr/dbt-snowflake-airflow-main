-- KPI: RMSE do modelo sklearn treinado, avaliado retrospectivamente sobre
-- tarefas reais do Snowflake (horas executadas reais).
SELECT ROUND(SQRT(AVG(ERRO_QUADRATICO_SKLEARN)), 2) AS RMSE_SKLEARN
FROM MUNKA_ML.ML_ANALISE_RETROSPECTIVA
