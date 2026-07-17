SELECT
    HASH('USUARIO_REGISTRO', ID)                               AS SK_USUARIO_REGISTRO,
    ID                                                         AS ID_USUARIO_REGISTRO,
    FIRST_NAME                                                 AS NOME,
    LAST_NAME                                                  AS SOBRENOME,
    CONCAT_WS(' ', FIRST_NAME, LAST_NAME)                      AS NOME_COMPLETO,
    USERNAME,
    SHA2(LOWER(TRIM(EMAIL)), 256)                              AS EMAIL_HASH,
    REGISTRATION_DATE,
    DW_INGESTED_AT                                             AS DT_CARGA
FROM {{ ref('stg_ab_register_user') }}
