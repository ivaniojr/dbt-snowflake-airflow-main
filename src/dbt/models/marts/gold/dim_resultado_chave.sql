SELECT
    HASH('RESULTADO_CHAVE', R.ID)                              AS SK_RESULTADO_CHAVE,
    R.ID                                                       AS ID_RESULTADO_CHAVE,
    R.NUMERO,
    R.TITULO,
    R.DESCRICAO,
    HASH('OBJETIVO', R.OBJETIVO_ID)                            AS SK_OBJETIVO,
    O.TITULO                                                   AS OBJETIVO,
    HASH('UNIDADE', R.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    R.DW_INGESTED_AT                                           AS DT_CARGA
FROM {{ ref('stg_resultado_chave') }} R
LEFT JOIN {{ ref('stg_objetivo') }} O ON O.ID = R.OBJETIVO_ID
LEFT JOIN {{ ref('stg_unidade_adm') }} U ON U.ID = R.UNIDADE_ADM_ID
