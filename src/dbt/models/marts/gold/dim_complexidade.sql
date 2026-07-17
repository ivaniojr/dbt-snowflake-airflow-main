SELECT
    HASH('COMPLEXIDADE', C.ID)                                 AS SK_COMPLEXIDADE,
    C.ID                                                       AS ID_COMPLEXIDADE,
    C.NOME,
    C.PONTUACAO_MAIOR_QUE,
    C.PONTUACAO_MENOR_QUE,
    HASH('UNIDADE', C.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    C.DW_INGESTED_AT                                           AS DT_CARGA
FROM {{ ref('stg_complexidade') }} C
LEFT JOIN {{ ref('stg_unidade_adm') }} U ON U.ID = C.UNIDADE_ADM_ID
