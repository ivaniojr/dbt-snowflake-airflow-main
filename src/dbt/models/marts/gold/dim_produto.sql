SELECT
    HASH('PRODUTO', P.ID)                                      AS SK_PRODUTO,
    P.ID                                                       AS ID_PRODUTO,
    P.NOME,
    P.DESCRICAO,
    P.DATA_SOLICITACAO,
    P.LINK_GIT,
    P.LINK_HOMOLOG,
    P.LINK_PROD,
    P.INF_ADICIONAL,
    HASH('UNIDADE', P.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    HASH('UNIDADE', P.UNIDADE_EXECUTANTE_ID)                   AS SK_UNIDADE_EXECUTANTE,
    UE.NOME_UNIDADE                                            AS UNIDADE_EXECUTANTE,
    HASH('UNIDADE_SUPERIOR', P.UNIDADE_SUPERIOR_ID)            AS SK_UNIDADE_SUPERIOR,
    US.NOME_UNIDADE                                            AS UNIDADE_SUPERIOR,
    P.DW_INGESTED_AT                                           AS DT_CARGA
FROM {{ ref('stg_produto') }} P
LEFT JOIN {{ ref('stg_unidade_adm') }} U ON U.ID = P.UNIDADE_ADM_ID
LEFT JOIN {{ ref('stg_unidade_adm') }} UE ON UE.ID = P.UNIDADE_EXECUTANTE_ID
LEFT JOIN {{ ref('stg_unidade_adm_superior') }} US ON US.ID = P.UNIDADE_SUPERIOR_ID
