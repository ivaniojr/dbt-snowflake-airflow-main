-- Métricas MAE / RMSE / R² calculadas via SQL nativo no Metabase sobre o Snowflake
-- (não há tabela model_metrics no Snowflake com métricas do modelo de ML — ver
-- limitação documentada em docs/metabase/README.md). Estas métricas avaliam a
-- qualidade da estimativa de regra de negócio (HET_MAX) frente ao executado.
-- Versão CTE (evita erro de parênteses aninhados no editor SQL do Metabase).
WITH base AS (
    SELECT
        r.HET_MAX AS PREVISTO,
        f.HORAS_EXECUTADAS AS REALIZADO
    FROM MUNKA_GOLD.FCT_TAREFA f
    JOIN MUNKA_GOLD.DIM_REGRA r ON r.SK_REGRA = f.SK_REGRA
    WHERE f.HORAS_EXECUTADAS IS NOT NULL
      AND r.HET_MAX IS NOT NULL
),
media AS (
    SELECT AVG(REALIZADO) AS MEDIA_REALIZADO FROM base
)
SELECT
    ROUND(AVG(ABS(PREVISTO - REALIZADO)), 2) AS MAE,
    ROUND(SQRT(AVG(POWER(PREVISTO - REALIZADO, 2))), 2) AS RMSE,
    ROUND(
        1 - SUM(POWER(PREVISTO - REALIZADO, 2)) / NULLIF(SUM(POWER(REALIZADO - MEDIA_REALIZADO, 2)), 0),
        2
    ) AS R2
FROM base, media
