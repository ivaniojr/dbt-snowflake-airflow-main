-- Gráfico: contagem de tarefas em que cada modelo (sklearn/numpy) ficou
-- mais próximo do valor real executado.
SELECT MODELO_MAIS_PROXIMO, COUNT(*) AS QTD_TAREFAS
FROM MUNKA_ML.ML_ANALISE_RETROSPECTIVA
GROUP BY MODELO_MAIS_PROXIMO
ORDER BY QTD_TAREFAS DESC
