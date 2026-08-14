-- Gráfico 2 — Erro das previsões por Complexidade (Bar chart)
-- erro = previsto - realizado (positivo = modelo/regra superestimou;
-- negativo = subestimou). erro_absoluto = |erro|.
SELECT
    r.COMPLEXIDADE                                          AS COMPLEXIDADE,
    ROUND(AVG(r.HET_MAX - f.HORAS_EXECUTADAS), 2)           AS ERRO_MEDIO,
    ROUND(AVG(ABS(r.HET_MAX - f.HORAS_EXECUTADAS)), 2)      AS ERRO_MEDIO_ABSOLUTO,
    COUNT(*)                                                AS QTD_TAREFAS
FROM MUNKA_GOLD.FCT_TAREFA f
JOIN MUNKA_GOLD.DIM_REGRA r ON r.SK_REGRA = f.SK_REGRA
LEFT JOIN MUNKA_GOLD.DIM_PROJETO p ON p.SK_PROJETO = f.SK_PROJETO
WHERE f.HORAS_EXECUTADAS IS NOT NULL
  AND r.HET_MAX IS NOT NULL
  [[AND {{complexidade}}]]
  [[AND {{periodo}}]]
GROUP BY r.COMPLEXIDADE
ORDER BY ERRO_MEDIO_ABSOLUTO DESC
