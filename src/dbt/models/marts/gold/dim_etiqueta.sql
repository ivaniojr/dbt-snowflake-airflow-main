SELECT
    HASH('ETIQUETA', E.ID)                                     AS SK_ETIQUETA,
    E.ID                                                       AS ID_ETIQUETA,
    E.NOME,
    E.COR,
    HASH('UNIDADE', E.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    E.DW_INGESTED_AT                                           AS DT_CARGA
FROM {{ ref('stg_etiqueta') }} E
LEFT JOIN {{ ref('stg_unidade_adm') }} U ON U.ID = E.UNIDADE_ADM_ID
