SELECT
    HASH('ORIGEM', O.ID)                                       AS SK_ORIGEM,
    O.ID                                                       AS ID_ORIGEM,
    O.NOME,
    O.ENDERECO,
    O.DESCRICAO,
    HASH('UNIDADE', O.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    O.DW_INGESTED_AT                                           AS DT_CARGA
FROM {{ ref('stg_origem') }} O
LEFT JOIN {{ ref('stg_unidade_adm') }} U ON U.ID = O.UNIDADE_ADM_ID
