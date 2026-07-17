
  
    

        create or replace transient table DRAGON_DB.munka_gold.fct_sprint
         as
        (SELECT
    HASH('SPRINT', S.ID)                                       AS SK_SPRINT,
    S.ID                                                       AS ID_SPRINT,
    HASH('COORDENACAO', S.COORDENACAO_ID)                      AS SK_COORDENACAO,
    TO_NUMBER(TO_CHAR(S.DATA_INICIO::DATE, 'YYYYMMDD'))        AS SK_DATA_INICIO,
    TO_NUMBER(TO_CHAR(S.DATA_FIM::DATE, 'YYYYMMDD'))           AS SK_DATA_FIM,
    DATEDIFF('DAY', S.DATA_INICIO, S.DATA_FIM) + 1             AS QUANTIDADE_DIAS,
    COALESCE(T.QTD_TAREFAS, 0)                                 AS QUANTIDADE_TAREFAS,
    COALESCE(T.QTD_CONCLUIDAS, 0)                              AS QUANTIDADE_CONCLUIDAS,
    COALESCE(T.QTD_APROVADAS, 0)                               AS QUANTIDADE_APROVADAS,
    COALESCE(T.HORAS_EXECUTADAS, 0)                            AS HORAS_EXECUTADAS,
    COALESCE(T.TOTAL_UST, 0)                                   AS TOTAL_UST,
    S.DW_INGESTED_AT                                           AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_sprint S
LEFT JOIN (
    SELECT
        SPRINT_ID,
        COUNT(*)                                                AS QTD_TAREFAS,
        COUNT_IF(DATA_FIM IS NOT NULL)                          AS QTD_CONCLUIDAS,
        COUNT_IF(APROVADA)                                      AS QTD_APROVADAS,
        SUM(COALESCE(HORAS_EXECUTADAS, 0))                      AS HORAS_EXECUTADAS,
        SUM(COALESCE(TOTAL_UST, 0))                             AS TOTAL_UST
    FROM DRAGON_DB.munka_stg.stg_tarefa
    WHERE SPRINT_ID IS NOT NULL
    GROUP BY SPRINT_ID
) T ON T.SPRINT_ID = S.ID
        );
      
  