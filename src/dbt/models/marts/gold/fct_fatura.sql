SELECT
    HASH('FATURA', F.ID)                                       AS SK_FATURA,
    F.ID                                                       AS ID_FATURA,
    HASH('CONTRATO', F.CONTRATO_ID)                            AS SK_CONTRATO,
    F.REAJUSTE_ID                                              AS ID_REAJUSTE,
    F.RENOVACAO_ID                                             AS ID_RENOVACAO,
    TO_NUMBER(TO_CHAR(F.DATA_INICIO::DATE, 'YYYYMMDD'))        AS SK_DATA_INICIO,
    TO_NUMBER(TO_CHAR(F.DATA_FIM::DATE, 'YYYYMMDD'))           AS SK_DATA_FIM,
    IFF(F.DATA_CRIACAO IS NULL, NULL, TO_NUMBER(TO_CHAR(F.DATA_CRIACAO::DATE, 'YYYYMMDD'))) AS SK_DATA_CRIACAO,
    F.DATA_INICIO,
    F.DATA_FIM,
    F.DATA_CRIACAO,
    DATEDIFF('DAY', F.DATA_INICIO, F.DATA_FIM) + 1             AS QUANTIDADE_DIAS_PERIODO,
    COALESCE(T.QTD_TAREFAS, 0)                                 AS QUANTIDADE_TAREFAS,
    COALESCE(T.QTD_TAREFAS_APROVADAS, 0)                       AS QUANTIDADE_TAREFAS_APROVADAS,
    COALESCE(T.HORAS_EXECUTADAS, 0)                            AS HORAS_EXECUTADAS,
    COALESCE(T.TOTAL_UST, 0)                                   AS TOTAL_UST,
    COALESCE(T.VALOR_FATURADO, 0)                              AS VALOR_FATURADO,
    F.ID_FATURA_OLD,
    F.DW_INGESTED_AT                                           AS DT_CARGA
FROM {{ ref('stg_fatura') }} F
LEFT JOIN (
    SELECT
        FATURA_ID,
        COUNT(*)                                                AS QTD_TAREFAS,
        COUNT_IF(APROVADA)                                      AS QTD_TAREFAS_APROVADAS,
        SUM(COALESCE(HORAS_EXECUTADAS, 0))                      AS HORAS_EXECUTADAS,
        SUM(COALESCE(TOTAL_UST, 0))                             AS TOTAL_UST,
        SUM(COALESCE(VALOR_FATURADO, 0))                        AS VALOR_FATURADO
    FROM {{ ref('stg_tarefa') }}
    WHERE FATURA_ID IS NOT NULL
    GROUP BY FATURA_ID
) T ON T.FATURA_ID = F.ID
