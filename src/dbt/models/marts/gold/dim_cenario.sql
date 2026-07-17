SELECT
    HASH('CENARIO', C.ID)                                      AS SK_CENARIO,
    C.ID                                                       AS ID_CENARIO,
    C.NOME,
    C.PONTUACAO,
    C.CENARIO_PADRAO,
    HASH('REQUISITO', C.REQUISITO_ID)                          AS SK_REQUISITO,
    R.NOME                                                     AS REQUISITO,
    HASH('UNIDADE', C.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    C.DW_INGESTED_AT                                           AS DT_CARGA
FROM {{ ref('stg_cenario') }} C
LEFT JOIN {{ ref('stg_requisito') }} R ON R.ID = C.REQUISITO_ID
LEFT JOIN {{ ref('stg_unidade_adm') }} U ON U.ID = C.UNIDADE_ADM_ID
