SELECT
    HASH('COORDENACAO', C.ID)                                  AS SK_COORDENACAO,
    C.ID                                                       AS ID_COORDENACAO,
    C.NOME,
    C.COR,
    HASH('UNIDADE', C.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    C.DW_INGESTED_AT                                           AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_coordenacao C
LEFT JOIN DRAGON_DB.munka_stg.stg_unidade_adm U ON U.ID = C.UNIDADE_ADM_ID