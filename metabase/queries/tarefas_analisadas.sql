-- KPI: Quantidade de tarefas analisadas (Number)
-- Fonte: MUNKA_GOLD.FCT_TAREFA + MUNKA_GOLD.DIM_REGRA
-- Considera apenas tarefas concluídas (HORAS_EXECUTADAS preenchida) cuja regra de
-- complexidade define uma estimativa de horas (HET_MAX), ou seja, o universo
-- comparável de "previsto x realizado".
SELECT
    COUNT(*) AS QTD_TAREFAS_ANALISADAS
FROM MUNKA_GOLD.FCT_TAREFA f
JOIN MUNKA_GOLD.DIM_REGRA r ON r.SK_REGRA = f.SK_REGRA
LEFT JOIN MUNKA_GOLD.DIM_PROJETO p ON p.SK_PROJETO = f.SK_PROJETO
WHERE f.HORAS_EXECUTADAS IS NOT NULL
  AND r.HET_MAX IS NOT NULL
  [[AND {{complexidade}}]]
  [[AND {{periodo}}]]
