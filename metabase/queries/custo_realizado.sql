-- KPI: Custo realizado (Number) = SUM(VALOR_FATURADO), campo monetário real já
-- existente em MUNKA_GOLD.FCT_TAREFA. Não há "custo_hora" nem "custo_previsto"
-- persistido no Snowflake — ver limitação em docs/metabase/README.md (seção 4
-- do DASHBOARD_METABASE.md proíbe inventar custo_hora).
SELECT
    ROUND(SUM(f.VALOR_FATURADO), 2) AS CUSTO_REALIZADO
FROM MUNKA_GOLD.FCT_TAREFA f
JOIN MUNKA_GOLD.DIM_REGRA r ON r.SK_REGRA = f.SK_REGRA
LEFT JOIN MUNKA_GOLD.DIM_PROJETO p ON p.SK_PROJETO = f.SK_PROJETO
WHERE f.HORAS_EXECUTADAS IS NOT NULL
  AND r.HET_MAX IS NOT NULL
  [[AND {{complexidade}}]]
  [[AND {{periodo}}]]
