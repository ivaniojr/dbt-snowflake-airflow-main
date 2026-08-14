-- KPI: score médio de qualidade da evidência extraída (feature de entrada do modelo)
SELECT ROUND(AVG(SCORE_QUALIDADE_EVIDENCIA), 2) AS SCORE_QUALIDADE_MEDIO
FROM MUNKA_ML.ML_TAREFA_FEATURES
