-- KPI: Total de horas previstas (Number)
-- "Previsto" = HET_MAX (Horas Estimadas Teto máximo) da regra de negócio MUNKA
-- (MUNKA_GOLD.DIM_REGRA.HET_MAX), o mesmo campo usado como feature de entrada
-- do modelo de ML (ver MUNKA_ML.ML_TAREFA_FEATURES / RELATORIO_TECNICO seção 7.4.1).
-- As previsões geradas em tempo real pelo modelo (batch_inference.py) não são
-- persistidas no Snowflake — ver limitação documentada em docs/metabase/README.md.
SELECT
    ROUND(SUM(r.HET_MAX), 1) AS HORAS_PREVISTAS
FROM MUNKA_GOLD.FCT_TAREFA f
JOIN MUNKA_GOLD.DIM_REGRA r ON r.SK_REGRA = f.SK_REGRA
LEFT JOIN MUNKA_GOLD.DIM_PROJETO p ON p.SK_PROJETO = f.SK_PROJETO
WHERE f.HORAS_EXECUTADAS IS NOT NULL
  AND r.HET_MAX IS NOT NULL
  [[AND {{complexidade}}]]
  [[AND {{periodo}}]]
