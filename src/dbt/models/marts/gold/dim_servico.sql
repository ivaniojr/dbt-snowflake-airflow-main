SELECT
    HASH('SERVICO', S.ID)                                      AS SK_SERVICO,
    S.ID                                                       AS ID_SERVICO,
    S.NOME,
    S.ESCOPO,
    S.ENTREGAVEIS,
    S.ATIVIDADES,
    S.FATURAVEL,
    HASH('CONTRATO', S.CONTRATO_ID)                            AS SK_CONTRATO,
    C.NOME                                                     AS CONTRATO,
    S.DW_INGESTED_AT                                           AS DT_CARGA
FROM {{ ref('stg_servico') }} S
LEFT JOIN {{ ref('stg_contrato') }} C ON C.ID = S.CONTRATO_ID
