SELECT
    HASH('REGRA', R.ID)                                        AS SK_REGRA,
    R.ID                                                       AS ID_REGRA,
    HASH('SERVICO', R.SERVICO_ID)                              AS SK_SERVICO,
    S.NOME                                                     AS SERVICO,
    HASH('COMPLEXIDADE', R.COMPLEXIDADE_ID)                    AS SK_COMPLEXIDADE,
    C.NOME                                                     AS COMPLEXIDADE,
    HASH('CARGO', R.CARGO_ID)                                  AS SK_CARGO,
    CA.NOME                                                    AS CARGO,
    HASH('NIVEL', R.NIVEL_ID)                                  AS SK_NIVEL,
    N.NOME                                                     AS NIVEL,
    R.HET_MAX,
    R.DESATIVADA                                               AS FL_DESATIVADA,
    R.FATOR_AJUSTE,
    R.ID_REGRA_OLD,
    R.DW_INGESTED_AT                                           AS DT_CARGA
FROM {{ ref('stg_regra') }} R
LEFT JOIN {{ ref('stg_servico') }} S ON S.ID = R.SERVICO_ID
LEFT JOIN {{ ref('stg_complexidade') }} C ON C.ID = R.COMPLEXIDADE_ID
LEFT JOIN {{ ref('stg_cargo') }} CA ON CA.ID = R.CARGO_ID
LEFT JOIN {{ ref('stg_nivel') }} N ON N.ID = R.NIVEL_ID
