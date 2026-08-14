-- KPI: percentual de tarefas em que o modelo sklearn ficou mais próximo do
-- valor real executado do que o modelo baseline (numpy).
SELECT
    ROUND(100.0 * SUM(CASE WHEN MODELO_MAIS_PROXIMO = 'SKLEARN' THEN 1 ELSE 0 END) / COUNT(*), 1) AS PCT_SKLEARN_MAIS_PROXIMO
FROM MUNKA_ML.ML_ANALISE_RETROSPECTIVA
