SELECT
    HASH('UNIDADE_SUPERIOR', ID)                               AS SK_UNIDADE_SUPERIOR,
    ID                                                         AS ID_UNIDADE_SUPERIOR,
    NOME_UNIDADE,
    SIGLA,
    RESPONSAVEL,
    SHA2(LOWER(TRIM(EMAIL)), 256)                              AS EMAIL_HASH,
    TELEFONE,
    CODIGO_SEI,
    DW_INGESTED_AT                                             AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_unidade_adm_superior