-- KPI: MAE do modelo baseline (numpy) avaliado sobre as mesmas tarefas reais,
-- para comparação direta com o modelo sklearn treinado.
SELECT ROUND(AVG(ERRO_ABSOLUTO_NUMPY), 2) AS MAE_NUMPY
FROM MUNKA_ML.ML_ANALISE_RETROSPECTIVA
