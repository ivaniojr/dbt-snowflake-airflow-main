SELECT
    HASH('USUARIO', U.ID)                                      AS SK_USUARIO,
    U.ID                                                       AS ID_USUARIO,
    U.FIRST_NAME                                               AS NOME,
    U.LAST_NAME                                                AS SOBRENOME,
    CONCAT_WS(' ', U.FIRST_NAME, U.LAST_NAME)                  AS NOME_COMPLETO,
    U.USERNAME,
    SHA2(LOWER(TRIM(U.EMAIL)), 256)                            AS EMAIL_HASH,
    U.ACTIVE                                                   AS FL_ATIVO,
    U.LAST_LOGIN,
    U.LOGIN_COUNT,
    U.FAIL_LOGIN_COUNT,
    U.CREATED_ON,
    U.CHANGED_ON,
    U.JORNADA_SEMANAL,
    HASH('CARGO', U.CARGO_ID)                                  AS SK_CARGO,
    C.NOME                                                     AS CARGO,
    HASH('NIVEL', U.NIVEL_ID)                                  AS SK_NIVEL,
    N.NOME                                                     AS NIVEL,
    HASH('COORDENACAO', U.COORDENACAO_ID)                      AS SK_COORDENACAO,
    CO.NOME                                                    AS COORDENACAO,
    HASH('USUARIO', U.CREATED_BY_FK)                           AS SK_USUARIO_CRIADOR,
    HASH('USUARIO', U.CHANGED_BY_FK)                           AS SK_USUARIO_ALTERADOR,
    U.DW_INGESTED_AT                                           AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_ab_user U
LEFT JOIN DRAGON_DB.munka_stg.stg_cargo C ON C.ID = U.CARGO_ID
LEFT JOIN DRAGON_DB.munka_stg.stg_nivel N ON N.ID = U.NIVEL_ID
LEFT JOIN DRAGON_DB.munka_stg.stg_coordenacao CO ON CO.ID = U.COORDENACAO_ID