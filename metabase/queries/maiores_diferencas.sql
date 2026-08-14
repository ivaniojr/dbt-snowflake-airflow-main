-- Tabela de apoio — Top 15 tarefas com maior diferença absoluta entre previsto e realizado
SELECT
    f.ID_TAREFA,
    f.NOME,
    p.NOME                                        AS PROJETO,
    r.COMPLEXIDADE,
    r.HET_MAX                                     AS HORAS_PREVISTAS,
    f.HORAS_EXECUTADAS                            AS HORAS_REALIZADAS,
    ROUND(r.HET_MAX - f.HORAS_EXECUTADAS, 2)       AS ERRO,
    ROUND(ABS(r.HET_MAX - f.HORAS_EXECUTADAS), 2)  AS ERRO_ABSOLUTO
FROM MUNKA_GOLD.FCT_TAREFA f
JOIN MUNKA_GOLD.DIM_REGRA r ON r.SK_REGRA = f.SK_REGRA
LEFT JOIN MUNKA_GOLD.DIM_PROJETO p ON p.SK_PROJETO = f.SK_PROJETO
WHERE f.HORAS_EXECUTADAS IS NOT NULL
  AND r.HET_MAX IS NOT NULL
  [[AND {{complexidade}}]]
  [[AND {{periodo}}]]
ORDER BY ERRO_ABSOLUTO DESC
LIMIT 15
