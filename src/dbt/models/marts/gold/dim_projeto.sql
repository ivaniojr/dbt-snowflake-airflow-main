SELECT
    HASH('PROJETO', P.ID)                                      AS SK_PROJETO,
    P.ID                                                       AS ID_PROJETO,
    P.NOME,
    P.DESCRICAO,
    P.ABRANGENCIA,
    P.ACESSO,
    P.NUMERO_SEI,
    P.JUSTIFICATIVA,
    P.INATIVO                                                  AS FL_INATIVO,
    HASH('PRODUTO', P.PRODUTO_ID)                              AS SK_PRODUTO,
    PR.NOME                                                    AS PRODUTO,
    HASH('STATUS', P.STATUS_ID)                                AS SK_STATUS,
    S.NOME                                                     AS STATUS,
    HASH('UNIDADE', P.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    HASH('UNIDADE_SUPERIOR', P.UNIDADE_SUPERIOR_ID)            AS SK_UNIDADE_SUPERIOR,
    US.NOME_UNIDADE                                            AS UNIDADE_SUPERIOR,
    P.DATA_SOLICITACAO,
    P.DATA_PROTOTIPO,
    P.LINK_PROTOTIPO,
    P.DATA_DESENV,
    P.LINK_DESENV,
    P.DATA_HOMOLOG,
    P.DATA_PROD,
    P.DATA_PREVISAO_INICIO,
    P.DATA_PREVISAO_TERMINO,
    P.PROGRESSO,
    P.OBS_PROGRESSO,
    P.DW_INGESTED_AT                                           AS DT_CARGA
FROM {{ ref('stg_projeto') }} P
LEFT JOIN {{ ref('stg_produto') }} PR ON PR.ID = P.PRODUTO_ID
LEFT JOIN {{ ref('stg_status') }} S ON S.ID = P.STATUS_ID
LEFT JOIN {{ ref('stg_unidade_adm') }} U ON U.ID = P.UNIDADE_ADM_ID
LEFT JOIN {{ ref('stg_unidade_adm_superior') }} US ON US.ID = P.UNIDADE_SUPERIOR_ID
