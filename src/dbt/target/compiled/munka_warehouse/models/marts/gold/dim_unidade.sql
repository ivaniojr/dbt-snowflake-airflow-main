SELECT
    HASH('UNIDADE', U.ID)                                      AS SK_UNIDADE,
    U.ID                                                       AS ID_UNIDADE,
    U.NOME_UNIDADE,
    U.SIGLA,
    U.RESPONSAVEL,
    SHA2(LOWER(TRIM(U.EMAIL)), 256)                            AS EMAIL_HASH,
    U.TELEFONE,
    U.CODIGO_SEI,
    U.UNIDADE_SUPERIOR_ID                                      AS ID_UNIDADE_SUPERIOR,
    S.NOME_UNIDADE                                             AS NOME_UNIDADE_SUPERIOR,
    S.SIGLA                                                    AS SIGLA_UNIDADE_SUPERIOR,
    U.DW_INGESTED_AT                                           AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_unidade_adm U
LEFT JOIN DRAGON_DB.munka_stg.stg_unidade_adm_superior S ON S.ID = U.UNIDADE_SUPERIOR_ID