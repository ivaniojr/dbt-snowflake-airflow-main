SELECT
    HASH('TECNOLOGIA', T.ID)                                   AS SK_TECNOLOGIA,
    T.ID                                                       AS ID_TECNOLOGIA,
    T.NOME,
    HASH('UNIDADE', T.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    T.ID_TECNOLOGIA_OLD,
    T.DW_INGESTED_AT                                           AS DT_CARGA
FROM {{ ref('stg_tecnologia') }} T
LEFT JOIN {{ ref('stg_unidade_adm') }} U ON U.ID = T.UNIDADE_ADM_ID
