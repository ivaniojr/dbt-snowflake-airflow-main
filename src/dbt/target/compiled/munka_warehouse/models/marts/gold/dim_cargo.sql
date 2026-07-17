SELECT
    HASH('CARGO', C.ID)                                        AS SK_CARGO,
    C.ID                                                       AS ID_CARGO,
    C.NOME,
    C.FATURAVEL,
    HASH('UNIDADE', C.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    C.DW_INGESTED_AT                                           AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_cargo C
LEFT JOIN DRAGON_DB.munka_stg.stg_unidade_adm U ON U.ID = C.UNIDADE_ADM_ID