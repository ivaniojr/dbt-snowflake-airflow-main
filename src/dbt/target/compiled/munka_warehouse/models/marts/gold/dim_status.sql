SELECT
    HASH('STATUS', S.ID)                                       AS SK_STATUS,
    S.ID                                                       AS ID_STATUS,
    S.NOME,
    S.ORDEM,
    S.MOSTRAR_QUADRO,
    HASH('UNIDADE', S.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    S.DW_INGESTED_AT                                           AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_status S
LEFT JOIN DRAGON_DB.munka_stg.stg_unidade_adm U ON U.ID = S.UNIDADE_ADM_ID