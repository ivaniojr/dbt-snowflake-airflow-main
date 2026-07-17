SELECT
    HASH('STATUS', S.ID)                                       AS SK_STATUS,
    S.ID                                                       AS ID_STATUS,
    S.NOME,
    S.ORDEM,
    S.MOSTRAR_QUADRO,
    HASH('UNIDADE', S.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    S.DW_INGESTED_AT                                           AS DT_CARGA
FROM {{ ref('stg_status') }} S
LEFT JOIN {{ ref('stg_unidade_adm') }} U ON U.ID = S.UNIDADE_ADM_ID
