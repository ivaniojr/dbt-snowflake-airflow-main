USE DATABASE DRAGON_DB;
USE SCHEMA MUNKA_RAW;

-- ============================================================================
-- 4. DIMENSÕES
-- ============================================================================
-- As SKs são determinísticas, calculadas com HASH(entidade, chave natural).

CREATE OR REPLACE TABLE DIM_DATA AS
SELECT
    TO_NUMBER(TO_CHAR(DT, 'YYYYMMDD'))                         AS SK_DATA,
    DT                                                         AS DATA,
    YEAR(DT)                                                   AS ANO,
    QUARTER(DT)                                                AS TRIMESTRE,
    MONTH(DT)                                                  AS MES_NUMERO,
    MONTHNAME(DT)                                              AS MES_NOME,
    WEEKOFYEAR(DT)                                             AS SEMANA_ANO,
    DAY(DT)                                                    AS DIA_MES,
    DAYOFWEEKISO(DT)                                           AS DIA_SEMANA_NUMERO,
    DAYNAME(DT)                                                AS DIA_SEMANA_NOME,
    IFF(DAYOFWEEKISO(DT) IN (6, 7), TRUE, FALSE)              AS FL_FIM_SEMANA,
    DATE_TRUNC('MONTH', DT)                                    AS PRIMEIRO_DIA_MES,
    LAST_DAY(DT, 'MONTH')                                      AS ULTIMO_DIA_MES
FROM (
    SELECT DATEADD(DAY, SEQ4(), '2000-01-01'::DATE) AS DT
    FROM TABLE(GENERATOR(ROWCOUNT => 13149))
);

CREATE OR REPLACE TABLE DIM_UNIDADE_SUPERIOR AS
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
FROM STG_UNIDADE_ADM_SUPERIOR;

CREATE OR REPLACE TABLE DIM_UNIDADE AS
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
FROM STG_UNIDADE_ADM U
LEFT JOIN STG_UNIDADE_ADM_SUPERIOR S ON S.ID = U.UNIDADE_SUPERIOR_ID;

CREATE OR REPLACE TABLE DIM_NIVEL AS
SELECT HASH('NIVEL', ID) AS SK_NIVEL, ID AS ID_NIVEL, NOME, DW_INGESTED_AT AS DT_CARGA
FROM STG_NIVEL;


CREATE OR REPLACE TABLE DIM_COMPLEXIDADE AS
SELECT
    HASH('COMPLEXIDADE', C.ID)                                 AS SK_COMPLEXIDADE,
    C.ID                                                       AS ID_COMPLEXIDADE,
    C.NOME,
    C.PONTUACAO_MAIOR_QUE,
    C.PONTUACAO_MENOR_QUE,
    HASH('UNIDADE', C.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    C.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_COMPLEXIDADE C
LEFT JOIN STG_UNIDADE_ADM U ON U.ID = C.UNIDADE_ADM_ID;

CREATE OR REPLACE TABLE DIM_CARGO AS
SELECT
    HASH('CARGO', C.ID)                                        AS SK_CARGO,
    C.ID                                                       AS ID_CARGO,
    C.NOME,
    C.FATURAVEL,
    HASH('UNIDADE', C.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    C.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_CARGO C
LEFT JOIN STG_UNIDADE_ADM U ON U.ID = C.UNIDADE_ADM_ID;

CREATE OR REPLACE TABLE DIM_COORDENACAO AS
SELECT
    HASH('COORDENACAO', C.ID)                                  AS SK_COORDENACAO,
    C.ID                                                       AS ID_COORDENACAO,
    C.NOME,
    C.COR,
    HASH('UNIDADE', C.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    C.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_COORDENACAO C
LEFT JOIN STG_UNIDADE_ADM U ON U.ID = C.UNIDADE_ADM_ID;

CREATE OR REPLACE TABLE DIM_USUARIO AS
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
FROM STG_AB_USER U
LEFT JOIN STG_CARGO C ON C.ID = U.CARGO_ID
LEFT JOIN STG_NIVEL N ON N.ID = U.NIVEL_ID
LEFT JOIN STG_COORDENACAO CO ON CO.ID = U.COORDENACAO_ID;

CREATE OR REPLACE TABLE DIM_STATUS AS
SELECT
    HASH('STATUS', S.ID)                                       AS SK_STATUS,
    S.ID                                                       AS ID_STATUS,
    S.NOME,
    S.ORDEM,
    S.MOSTRAR_QUADRO,
    HASH('UNIDADE', S.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    S.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_STATUS S
LEFT JOIN STG_UNIDADE_ADM U ON U.ID = S.UNIDADE_ADM_ID;

CREATE OR REPLACE TABLE DIM_ETIQUETA AS
SELECT
    HASH('ETIQUETA', E.ID)                                     AS SK_ETIQUETA,
    E.ID                                                       AS ID_ETIQUETA,
    E.NOME,
    E.COR,
    HASH('UNIDADE', E.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    E.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_ETIQUETA E
LEFT JOIN STG_UNIDADE_ADM U ON U.ID = E.UNIDADE_ADM_ID;

CREATE OR REPLACE TABLE DIM_TIPO AS
SELECT
    HASH('TIPO', T.ID)                                         AS SK_TIPO,
    T.ID                                                       AS ID_TIPO,
    T.NOME,
    HASH('UNIDADE', T.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    T.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_TIPO T
LEFT JOIN STG_UNIDADE_ADM U ON U.ID = T.UNIDADE_ADM_ID;

CREATE OR REPLACE TABLE DIM_USUARIO_REGISTRO AS
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
FROM STG_AB_REGISTER_USER;

CREATE OR REPLACE TABLE DIM_CONTRATO AS
SELECT
    HASH('CONTRATO', C.ID)                                     AS SK_CONTRATO,
    C.ID                                                       AS ID_CONTRATO,
    C.NOME,
    C.ATIVO                                                    AS FL_ATIVO,
    C.UST_VALOR,
    C.UST_CONTRATADAS,
    C.UST_ADITIVADAS,
    C.DEDUCOES_HORAS,
    C.DEDUCOES_UST,
    C.OUTROS_HORAS,
    C.OUTROS_UST,
    C.DATA_INICIO,
    C.DATA_FIM,
    C.DATA_VIGENCIA,
    C.FATURAR_HPA,
    HASH('UNIDADE', C.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    C.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_CONTRATO C
LEFT JOIN STG_UNIDADE_ADM U ON U.ID = C.UNIDADE_ADM_ID;

CREATE OR REPLACE TABLE DIM_PRODUTO AS
SELECT
    HASH('PRODUTO', P.ID)                                      AS SK_PRODUTO,
    P.ID                                                       AS ID_PRODUTO,
    P.NOME,
    P.DESCRICAO,
    P.DATA_SOLICITACAO,
    P.LINK_GIT,
    P.LINK_HOMOLOG,
    P.LINK_PROD,
    P.INF_ADICIONAL,
    HASH('UNIDADE', P.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    HASH('UNIDADE', P.UNIDADE_EXECUTANTE_ID)                   AS SK_UNIDADE_EXECUTANTE,
    UE.NOME_UNIDADE                                            AS UNIDADE_EXECUTANTE,
    HASH('UNIDADE_SUPERIOR', P.UNIDADE_SUPERIOR_ID)            AS SK_UNIDADE_SUPERIOR,
    US.NOME_UNIDADE                                            AS UNIDADE_SUPERIOR,
    P.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_PRODUTO P
LEFT JOIN STG_UNIDADE_ADM U ON U.ID = P.UNIDADE_ADM_ID
LEFT JOIN STG_UNIDADE_ADM UE ON UE.ID = P.UNIDADE_EXECUTANTE_ID
LEFT JOIN STG_UNIDADE_ADM_SUPERIOR US ON US.ID = P.UNIDADE_SUPERIOR_ID;

CREATE OR REPLACE TABLE DIM_PROJETO AS
SELECT
    HASH('PROJETO', P.ID)                                      AS SK_PROJETO,
    P.ID                                                       AS ID_PROJETO,
    P.NOME,
    P.DESCRICAO,
    P.ABRANGENCIA,
    P.ACESSO,
    P.NUMERO_SEI,
    P.JUSTIFICATIVA,
    P.INATIVO                                                  AS FL_INATIVO,
    HASH('PRODUTO', P.PRODUTO_ID)                              AS SK_PRODUTO,
    PR.NOME                                                    AS PRODUTO,
    HASH('STATUS', P.STATUS_ID)                                AS SK_STATUS,
    S.NOME                                                     AS STATUS,
    HASH('UNIDADE', P.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    HASH('UNIDADE_SUPERIOR', P.UNIDADE_SUPERIOR_ID)            AS SK_UNIDADE_SUPERIOR,
    US.NOME_UNIDADE                                            AS UNIDADE_SUPERIOR,
    P.DATA_SOLICITACAO,
    P.DATA_PROTOTIPO,
    P.LINK_PROTOTIPO,
    P.DATA_DESENV,
    P.LINK_DESENV,
    P.DATA_HOMOLOG,
    P.DATA_PROD,
    P.DATA_PREVISAO_INICIO,
    P.DATA_PREVISAO_TERMINO,
    P.PROGRESSO,
    P.OBS_PROGRESSO,
    P.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_PROJETO P
LEFT JOIN STG_PRODUTO PR ON PR.ID = P.PRODUTO_ID
LEFT JOIN STG_STATUS S ON S.ID = P.STATUS_ID
LEFT JOIN STG_UNIDADE_ADM U ON U.ID = P.UNIDADE_ADM_ID
LEFT JOIN STG_UNIDADE_ADM_SUPERIOR US ON US.ID = P.UNIDADE_SUPERIOR_ID;

CREATE OR REPLACE TABLE DIM_SPRINT AS
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
FROM STG_SPRINT S
LEFT JOIN STG_COORDENACAO C ON C.ID = S.COORDENACAO_ID;

CREATE OR REPLACE TABLE DIM_SERVICO AS
SELECT
    HASH('SERVICO', S.ID)                                      AS SK_SERVICO,
    S.ID                                                       AS ID_SERVICO,
    S.NOME,
    S.ESCOPO,
    S.ENTREGAVEIS,
    S.ATIVIDADES,
    S.FATURAVEL,
    HASH('CONTRATO', S.CONTRATO_ID)                            AS SK_CONTRATO,
    C.NOME                                                     AS CONTRATO,
    S.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_SERVICO S
LEFT JOIN STG_CONTRATO C ON C.ID = S.CONTRATO_ID;

CREATE OR REPLACE TABLE DIM_REGRA AS
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
FROM STG_REGRA R
LEFT JOIN STG_SERVICO S ON S.ID = R.SERVICO_ID
LEFT JOIN STG_COMPLEXIDADE C ON C.ID = R.COMPLEXIDADE_ID
LEFT JOIN STG_CARGO CA ON CA.ID = R.CARGO_ID
LEFT JOIN STG_NIVEL N ON N.ID = R.NIVEL_ID;


CREATE OR REPLACE TABLE DIM_FATOR_COMPLEXIDADE_UST AS
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
FROM STG_FATOR_COMPLEXIDADE_UST F
LEFT JOIN STG_CARGO C ON C.ID = F.CARGO_ID
LEFT JOIN STG_NIVEL N ON N.ID = F.NIVEL_ID
LEFT JOIN STG_CONTRATO CT ON CT.ID = F.CONTRATO_ID;

CREATE OR REPLACE TABLE DIM_REQUISITO AS
SELECT
    HASH('REQUISITO', R.ID)                                    AS SK_REQUISITO,
    R.ID                                                       AS ID_REQUISITO,
    R.NOME,
    HASH('UNIDADE', R.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    R.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_REQUISITO R
LEFT JOIN STG_UNIDADE_ADM U ON U.ID = R.UNIDADE_ADM_ID;

CREATE OR REPLACE TABLE DIM_CENARIO AS
SELECT
    HASH('CENARIO', C.ID)                                      AS SK_CENARIO,
    C.ID                                                       AS ID_CENARIO,
    C.NOME,
    C.PONTUACAO,
    C.CENARIO_PADRAO,
    HASH('REQUISITO', C.REQUISITO_ID)                          AS SK_REQUISITO,
    R.NOME                                                     AS REQUISITO,
    HASH('UNIDADE', C.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    C.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_CENARIO C
LEFT JOIN STG_REQUISITO R ON R.ID = C.REQUISITO_ID
LEFT JOIN STG_UNIDADE_ADM U ON U.ID = C.UNIDADE_ADM_ID;

CREATE OR REPLACE TABLE DIM_TECNOLOGIA AS
SELECT
    HASH('TECNOLOGIA', T.ID)                                   AS SK_TECNOLOGIA,
    T.ID                                                       AS ID_TECNOLOGIA,
    T.NOME,
    HASH('UNIDADE', T.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    T.ID_TECNOLOGIA_OLD,
    T.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_TECNOLOGIA T
LEFT JOIN STG_UNIDADE_ADM U ON U.ID = T.UNIDADE_ADM_ID;

CREATE OR REPLACE TABLE DIM_ORIGEM AS
SELECT
    HASH('ORIGEM', O.ID)                                       AS SK_ORIGEM,
    O.ID                                                       AS ID_ORIGEM,
    O.NOME,
    O.ENDERECO,
    O.DESCRICAO,
    HASH('UNIDADE', O.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    O.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_ORIGEM O
LEFT JOIN STG_UNIDADE_ADM U ON U.ID = O.UNIDADE_ADM_ID;

CREATE OR REPLACE TABLE DIM_OBJETIVO AS
SELECT
    HASH('OBJETIVO', O.ID)                                     AS SK_OBJETIVO,
    O.ID                                                       AS ID_OBJETIVO,
    O.NUMERO,
    O.TITULO,
    O.DESCRICAO,
    HASH('UNIDADE', O.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    O.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_OBJETIVO O
LEFT JOIN STG_UNIDADE_ADM U ON U.ID = O.UNIDADE_ADM_ID;

CREATE OR REPLACE TABLE DIM_RESULTADO_CHAVE AS
SELECT
    HASH('RESULTADO_CHAVE', R.ID)                              AS SK_RESULTADO_CHAVE,
    R.ID                                                       AS ID_RESULTADO_CHAVE,
    R.NUMERO,
    R.TITULO,
    R.DESCRICAO,
    HASH('OBJETIVO', R.OBJETIVO_ID)                            AS SK_OBJETIVO,
    O.TITULO                                                   AS OBJETIVO,
    HASH('UNIDADE', R.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    R.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_RESULTADO_CHAVE R
LEFT JOIN STG_OBJETIVO O ON O.ID = R.OBJETIVO_ID
LEFT JOIN STG_UNIDADE_ADM U ON U.ID = R.UNIDADE_ADM_ID;

CREATE OR REPLACE TABLE DIM_FICHA_INDICADOR AS
SELECT
    HASH('FICHA_INDICADOR', ID)                                AS SK_FICHA_INDICADOR,
    ID                                                         AS ID_FICHA_INDICADOR,
    TITULO,
    GUIA_ID,
    DW_INGESTED_AT                                             AS DT_CARGA
FROM STG_FICHA_INDICADOR;

CREATE OR REPLACE TABLE DIM_ROLE AS
SELECT HASH('ROLE', ID) AS SK_ROLE, ID AS ID_ROLE, NAME AS NOME, DW_INGESTED_AT AS DT_CARGA
FROM STG_AB_ROLE;

CREATE OR REPLACE TABLE DIM_PERMISSAO AS
SELECT HASH('PERMISSAO', ID) AS SK_PERMISSAO, ID AS ID_PERMISSAO, NAME AS NOME, DW_INGESTED_AT AS DT_CARGA
FROM STG_AB_PERMISSION;

CREATE OR REPLACE TABLE DIM_MENU AS
SELECT HASH('MENU', ID) AS SK_MENU, ID AS ID_MENU, NAME AS NOME, DW_INGESTED_AT AS DT_CARGA
FROM STG_AB_VIEW_MENU;
