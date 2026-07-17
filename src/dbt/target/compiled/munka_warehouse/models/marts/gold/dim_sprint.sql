SELECT
    HASH('SPRINT', S.ID)                                       AS SK_SPRINT,
    S.ID                                                       AS ID_SPRINT,
    S.DATA_INICIO,
    S.DATA_FIM,
    S.OBJETIVOS,
    S.DESCRICAO_CURTA,
    HASH('COORDENACAO', S.COORDENACAO_ID)                      AS SK_COORDENACAO,
    C.NOME                                                     AS COORDENACAO,
    S.ID_SPRINT_OLD,
    S.DW_INGESTED_AT                                           AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_sprint S
LEFT JOIN DRAGON_DB.munka_stg.stg_coordenacao C ON C.ID = S.COORDENACAO_ID