-- Gráfico 3 — Evolução temporal de horas previstas x realizadas (Line chart)
-- Agrupado por mês de conclusão da tarefa (DATA_FIM).
SELECT
    DATE_TRUNC('month', f.DATA_FIM)     AS MES,
    ROUND(SUM(r.HET_MAX), 1)            AS HORAS_PREVISTAS,
    ROUND(SUM(f.HORAS_EXECUTADAS), 1)   AS HORAS_REALIZADAS
FROM MUNKA_GOLD.FCT_TAREFA f
JOIN MUNKA_GOLD.DIM_REGRA r ON r.SK_REGRA = f.SK_REGRA
LEFT JOIN MUNKA_GOLD.DIM_PROJETO p ON p.SK_PROJETO = f.SK_PROJETO
WHERE f.HORAS_EXECUTADAS IS NOT NULL
  AND r.HET_MAX IS NOT NULL
  AND f.DATA_FIM IS NOT NULL
  [[AND {{complexidade}}]]
  [[AND {{periodo}}]]
GROUP BY 1
ORDER BY 1
