SELECT
    HASH('MOV_CONTRATO', 'AJUSTE', A.ID)                       AS SK_MOVIMENTO_CONTRATO,
    'AJUSTE'                                                   AS TIPO_MOVIMENTO,
    A.ID                                                       AS ID_MOVIMENTO,
    HASH('CONTRATO', A.CONTRATO_ID)                            AS SK_CONTRATO,
    A.DATA_INICIO,
    A.DATA_FIM,
    A.TIPO                                                     AS SUBTIPO,
    A.UST_VALOR,
    A.UST_CONTRATADAS,
    NULL::FLOAT                                                AS UST_RENOVADAS,
    A.DW_INGESTED_AT                                           AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_ajuste A
UNION ALL
SELECT
    HASH('MOV_CONTRATO', 'REAJUSTE', R.ID),
    'REAJUSTE',
    R.ID,
    HASH('CONTRATO', R.CONTRATO_ID),
    R.DATA_INICIO,
    R.DATA_FIM,
    NULL,
    R.UST_VALOR,
    NULL,
    NULL,
    R.DW_INGESTED_AT
FROM DRAGON_DB.munka_stg.stg_reajuste R
UNION ALL
SELECT
    HASH('MOV_CONTRATO', 'RENOVACAO', R.ID),
    'RENOVACAO',
    R.ID,
    HASH('CONTRATO', R.CONTRATO_ID),
    R.DATA_INICIO,
    R.DATA_FIM,
    NULL,
    NULL,
    NULL,
    R.UST_CONTRATADAS,
    R.DW_INGESTED_AT
FROM DRAGON_DB.munka_stg.stg_renovacao R