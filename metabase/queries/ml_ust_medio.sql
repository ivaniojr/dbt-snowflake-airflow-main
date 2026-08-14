-- KPI: média de UST (Unidade de Serviço Técnico) faturada por tarefa
SELECT ROUND(AVG(TOTAL_UST), 2) AS UST_MEDIO
FROM MUNKA_ML.ML_TAREFA_FEATURES
