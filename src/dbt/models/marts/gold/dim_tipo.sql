SELECT
    HASH('TIPO', T.ID)                                         AS SK_TIPO,
    T.ID                                                       AS ID_TIPO,
    T.NOME,
    HASH('UNIDADE', T.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    T.DW_INGESTED_AT                                           AS DT_CARGA
FROM {{ ref('stg_tipo') }} T
LEFT JOIN {{ ref('stg_unidade_adm') }} U ON U.ID = T.UNIDADE_ADM_ID
