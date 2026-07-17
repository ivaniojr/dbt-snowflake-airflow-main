SELECT
    HASH('OBJETIVO', O.ID)                                     AS SK_OBJETIVO,
    O.ID                                                       AS ID_OBJETIVO,
    O.NUMERO,
    O.TITULO,
    O.DESCRICAO,
    HASH('UNIDADE', O.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    O.DW_INGESTED_AT                                           AS DT_CARGA
FROM {{ ref('stg_objetivo') }} O
LEFT JOIN {{ ref('stg_unidade_adm') }} U ON U.ID = O.UNIDADE_ADM_ID
