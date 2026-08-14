-- Gráfico 4 — Distribuição do erro (previsto - realizado), em faixas (Bar chart/Histograma)
SELECT
    CASE
        WHEN (r.HET_MAX - f.HORAS_EXECUTADAS) <= -20 THEN '01. <= -20h (subestimou muito)'
        WHEN (r.HET_MAX - f.HORAS_EXECUTADAS) <= -5  THEN '02. -20h a -5h (subestimou)'
        WHEN (r.HET_MAX - f.HORAS_EXECUTADAS) <  5   THEN '03. -5h a 5h (próximo do real)'
        WHEN (r.HET_MAX - f.HORAS_EXECUTADAS) <  20  THEN '04. 5h a 20h (superestimou)'
        ELSE '05. >= 20h (superestimou muito)'
    END AS FAIXA_ERRO,
    COUNT(*) AS QTD_TAREFAS
FROM MUNKA_GOLD.FCT_TAREFA f
JOIN MUNKA_GOLD.DIM_REGRA r ON r.SK_REGRA = f.SK_REGRA
LEFT JOIN MUNKA_GOLD.DIM_PROJETO p ON p.SK_PROJETO = f.SK_PROJETO
WHERE f.HORAS_EXECUTADAS IS NOT NULL
  AND r.HET_MAX IS NOT NULL
  [[AND {{complexidade}}]]
  [[AND {{periodo}}]]
GROUP BY 1
ORDER BY 1
