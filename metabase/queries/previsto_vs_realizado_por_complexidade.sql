-- Gráfico 1 — Previsto x Realizado, agregado por Complexidade (Bar/Line chart)
-- Compara a média de horas previstas (HET_MAX) com a média de horas realizadas
-- (HORAS_EXECUTADAS) por categoria de complexidade.
SELECT
    r.COMPLEXIDADE                            AS COMPLEXIDADE,
    ROUND(AVG(r.HET_MAX), 2)                  AS MEDIA_HORAS_PREVISTAS,
    ROUND(AVG(f.HORAS_EXECUTADAS), 2)         AS MEDIA_HORAS_REALIZADAS,
    COUNT(*)                                  AS QTD_TAREFAS
FROM MUNKA_GOLD.FCT_TAREFA f
JOIN MUNKA_GOLD.DIM_REGRA r ON r.SK_REGRA = f.SK_REGRA
LEFT JOIN MUNKA_GOLD.DIM_PROJETO p ON p.SK_PROJETO = f.SK_PROJETO
WHERE f.HORAS_EXECUTADAS IS NOT NULL
  AND r.HET_MAX IS NOT NULL
  [[AND {{complexidade}}]]
  [[AND {{periodo}}]]
GROUP BY r.COMPLEXIDADE
ORDER BY QTD_TAREFAS DESC
