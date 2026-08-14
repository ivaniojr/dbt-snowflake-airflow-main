-- Tabela: top 15 tarefas reais com maior diferença entre as estimativas dos
-- dois modelos (sklearn vs. numpy), para auditoria dos casos mais divergentes.
SELECT
    TAREFA_ID,
    HORAS_EXECUTADAS,
    HORAS_ESTIMADAS_SKLEARN,
    HORAS_ESTIMADAS_NUMPY,
    MODELO_MAIS_PROXIMO,
    DIFERENCA_MODELOS
FROM MUNKA_ML.ML_ANALISE_RETROSPECTIVA
ORDER BY DIFERENCA_MODELOS DESC
LIMIT 15
