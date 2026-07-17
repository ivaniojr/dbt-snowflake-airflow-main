SELECT
    HASH('FATOR_COMPLEXIDADE_UST', F.ID)                       AS SK_FATOR_COMPLEXIDADE_UST,
    F.ID                                                       AS ID_FATOR_COMPLEXIDADE_UST,
    F.FATOR_COMPLEXIDADE,
    F.ATIVO                                                    AS FL_ATIVO,
    HASH('CARGO', F.CARGO_ID)                                  AS SK_CARGO,
    C.NOME                                                     AS CARGO,
    HASH('NIVEL', F.NIVEL_ID)                                  AS SK_NIVEL,
    N.NOME                                                     AS NIVEL,
    HASH('CONTRATO', F.CONTRATO_ID)                            AS SK_CONTRATO,
    CT.NOME                                                    AS CONTRATO,
    F.ID_FATOR_OLD,
    F.DW_INGESTED_AT                                           AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_fator_complexidade_ust F
LEFT JOIN DRAGON_DB.munka_stg.stg_cargo C ON C.ID = F.CARGO_ID
LEFT JOIN DRAGON_DB.munka_stg.stg_nivel N ON N.ID = F.NIVEL_ID
LEFT JOIN DRAGON_DB.munka_stg.stg_contrato CT ON CT.ID = F.CONTRATO_ID