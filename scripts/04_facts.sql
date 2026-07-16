USE DATABASE DRAGON_DB;
USE SCHEMA MUNKA_RAW;

-- ============================================================================
-- 5. FATOS
-- ============================================================================

CREATE OR REPLACE TABLE FCT_TAREFA AS
SELECT
    HASH('TAREFA', T.ID)                                       AS SK_TAREFA,
    T.ID                                                       AS ID_TAREFA,
    HASH('PROJETO', T.PROJETO_ID)                              AS SK_PROJETO,
    HASH('PRODUTO', T.PRODUTO_ID)                              AS SK_PRODUTO,
    HASH('USUARIO', T.RESPONSAVEL_ID)                          AS SK_RESPONSAVEL,
    HASH('USUARIO', T.USER_ABERTURA_ID)                        AS SK_USUARIO_ABERTURA,
    HASH('USUARIO', T.USER_APROVADA_ID)                        AS SK_USUARIO_APROVACAO,
    HASH('USUARIO', T.USER_ULTIMA_ATUALIZACAO_ID)              AS SK_USUARIO_ULTIMA_ATUALIZACAO,
    HASH('CARGO', T.CARGO_ID)                                  AS SK_CARGO,
    HASH('NIVEL', T.NIVEL_ID)                                  AS SK_NIVEL,
    HASH('ETIQUETA', T.ETIQUETA_ID)                            AS SK_ETIQUETA,
    HASH('SPRINT', T.SPRINT_ID)                                AS SK_SPRINT,
    HASH('REGRA', T.REGRA_ID)                                  AS SK_REGRA,
    HASH('STATUS', T.STATUS_ID)                                AS SK_STATUS,
    HASH('TAREFA', T.TAREFA_PAI_ID)                            AS SK_TAREFA_PAI,
    T.FATURA_ID                                                AS ID_FATURA,
    IFF(T.DATA_ABERTURA IS NULL, NULL, TO_NUMBER(TO_CHAR(T.DATA_ABERTURA::DATE, 'YYYYMMDD'))) AS SK_DATA_ABERTURA,
    IFF(T.DATA_INICIO IS NULL, NULL, TO_NUMBER(TO_CHAR(T.DATA_INICIO::DATE, 'YYYYMMDD')))     AS SK_DATA_INICIO,
    IFF(T.DATA_FIM IS NULL, NULL, TO_NUMBER(TO_CHAR(T.DATA_FIM::DATE, 'YYYYMMDD')))           AS SK_DATA_FIM,
    IFF(T.DATA_ULTIMA_ATUALIZACAO IS NULL, NULL, TO_NUMBER(TO_CHAR(T.DATA_ULTIMA_ATUALIZACAO::DATE, 'YYYYMMDD'))) AS SK_DATA_ATUALIZACAO,
    T.NOME,
    T.DESCRICAO,
    T.TIPO,
    T.NUM_HELPDESK,
    T.DATA_ABERTURA,
    T.DATA_INICIO,
    T.DATA_FIM,
    T.DATA_ULTIMA_ATUALIZACAO,
    T.HORAS_EXECUTADAS,
    T.VALOR_FATURADO,
    T.TOTAL_UST,
    T.APROVADA                                                  AS FL_APROVADA,
    IFF(T.DATA_FIM IS NULL, TRUE, FALSE)                        AS FL_EM_ABERTO,
    IFF(NULLIF(TRIM(T.EVIDENCIAS), '') IS NOT NULL, TRUE, FALSE) AS FL_EVIDENCIA_TEXTO,
    IFF(NULLIF(TRIM(T.EVIDENCIA_COMMIT_SHA), '') IS NOT NULL, TRUE, FALSE) AS FL_EVIDENCIA_COMMIT,
    IFF(NULLIF(TRIM(T.EVIDENCIA_ANEXO), '') IS NOT NULL, TRUE, FALSE) AS FL_EVIDENCIA_ANEXO,
    IFF(NULLIF(TRIM(T.EVIDENCIAS), '') IS NOT NULL
        OR NULLIF(TRIM(T.EVIDENCIA_COMMIT_SHA), '') IS NOT NULL
        OR NULLIF(TRIM(T.EVIDENCIA_ANEXO), '') IS NOT NULL, TRUE, FALSE) AS FL_POSSUI_EVIDENCIA,
    IFF(T.DATA_INICIO IS NOT NULL AND T.DATA_FIM IS NOT NULL,
        DATEDIFF('MINUTE', T.DATA_INICIO, T.DATA_FIM) / 60.0, NULL) AS DURACAO_CALENDARIO_HORAS,
    LENGTH(T.DESCRICAO)                                        AS TAMANHO_DESCRICAO,
    LENGTH(T.EVIDENCIAS)                                       AS TAMANHO_EVIDENCIA_TEXTO,
    T.ID_TAREFA_OLD,
    T.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_TAREFA T;

CREATE OR REPLACE TABLE FCT_EVIDENCIA_TAREFA AS
WITH EVIDENCIAS AS (
    SELECT ID AS ID_TAREFA, 'TEXTO' AS TIPO_EVIDENCIA, EVIDENCIAS AS CONTEUDO, DATA_ULTIMA_ATUALIZACAO, DW_INGESTED_AT
    FROM STG_TAREFA WHERE NULLIF(TRIM(EVIDENCIAS), '') IS NOT NULL
    UNION ALL
    SELECT ID, 'COMMIT', EVIDENCIA_COMMIT_SHA, DATA_ULTIMA_ATUALIZACAO, DW_INGESTED_AT
    FROM STG_TAREFA WHERE NULLIF(TRIM(EVIDENCIA_COMMIT_SHA), '') IS NOT NULL
    UNION ALL
    SELECT ID, 'ANEXO', EVIDENCIA_ANEXO, DATA_ULTIMA_ATUALIZACAO, DW_INGESTED_AT
    FROM STG_TAREFA WHERE NULLIF(TRIM(EVIDENCIA_ANEXO), '') IS NOT NULL
)
SELECT
    HASH('EVIDENCIA', ID_TAREFA, TIPO_EVIDENCIA, CONTEUDO)      AS SK_EVIDENCIA,
    HASH('TAREFA', ID_TAREFA)                                  AS SK_TAREFA,
    ID_TAREFA,
    TIPO_EVIDENCIA,
    CONTEUDO                                                    AS CONTEUDO_ORIGINAL,
    REGEXP_REPLACE(CONTEUDO, '<[^>]+>', ' ')                   AS CONTEUDO_SEM_HTML,
    LENGTH(CONTEUDO)                                            AS QUANTIDADE_CARACTERES,
    REGEXP_COUNT(TRIM(CONTEUDO), '\\S+')                      AS QUANTIDADE_PALAVRAS,
    REGEXP_COUNT(LOWER(CONTEUDO), 'https?://')                  AS QUANTIDADE_URLS,
    IFF(REGEXP_LIKE(LOWER(CONTEUDO), '\\.(png|jpg|jpeg|gif|webp|bmp|svg)(\\?|$)'), TRUE, FALSE) AS FL_IMAGEM,
    IFF(TIPO_EVIDENCIA = 'COMMIT', TRUE, FALSE)                 AS FL_COMMIT,
    REGEXP_SUBSTR(LOWER(CONTEUDO), '\\.(png|jpg|jpeg|gif|webp|bmp|svg|pdf|docx?|xlsx?|zip)(\\?|$)', 1, 1, 'e', 1) AS EXTENSAO_ARQUIVO,
    DATA_ULTIMA_ATUALIZACAO,
    DW_INGESTED_AT                                              AS DT_CARGA
FROM EVIDENCIAS;

CREATE OR REPLACE TABLE FCT_COMENTARIO AS
SELECT
    HASH('COMENTARIO', C.ID)                                   AS SK_COMENTARIO,
    C.ID                                                       AS ID_COMENTARIO,
    HASH('TAREFA', C.TAREFA_ID)                                AS SK_TAREFA,
    HASH('USUARIO', C.AUTOR_ID)                                AS SK_AUTOR,
    HASH('UNIDADE', C.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    IFF(C.HORARIO IS NULL, NULL, TO_NUMBER(TO_CHAR(C.HORARIO::DATE, 'YYYYMMDD'))) AS SK_DATA_COMENTARIO,
    C.HORARIO,
    C.CONTEUDO,
    LENGTH(C.CONTEUDO)                                         AS QUANTIDADE_CARACTERES,
    REGEXP_COUNT(TRIM(C.CONTEUDO), '\\S+')                   AS QUANTIDADE_PALAVRAS,
    C.ID_COMENTARIO_OLD,
    C.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_COMENTARIO C;

CREATE OR REPLACE TABLE FCT_FATURA AS
SELECT
    HASH('FATURA', F.ID)                                       AS SK_FATURA,
    F.ID                                                       AS ID_FATURA,
    HASH('CONTRATO', F.CONTRATO_ID)                            AS SK_CONTRATO,
    F.REAJUSTE_ID                                              AS ID_REAJUSTE,
    F.RENOVACAO_ID                                             AS ID_RENOVACAO,
    TO_NUMBER(TO_CHAR(F.DATA_INICIO::DATE, 'YYYYMMDD'))        AS SK_DATA_INICIO,
    TO_NUMBER(TO_CHAR(F.DATA_FIM::DATE, 'YYYYMMDD'))           AS SK_DATA_FIM,
    IFF(F.DATA_CRIACAO IS NULL, NULL, TO_NUMBER(TO_CHAR(F.DATA_CRIACAO::DATE, 'YYYYMMDD'))) AS SK_DATA_CRIACAO,
    F.DATA_INICIO,
    F.DATA_FIM,
    F.DATA_CRIACAO,
    DATEDIFF('DAY', F.DATA_INICIO, F.DATA_FIM) + 1             AS QUANTIDADE_DIAS_PERIODO,
    COALESCE(T.QTD_TAREFAS, 0)                                 AS QUANTIDADE_TAREFAS,
    COALESCE(T.QTD_TAREFAS_APROVADAS, 0)                       AS QUANTIDADE_TAREFAS_APROVADAS,
    COALESCE(T.HORAS_EXECUTADAS, 0)                            AS HORAS_EXECUTADAS,
    COALESCE(T.TOTAL_UST, 0)                                   AS TOTAL_UST,
    COALESCE(T.VALOR_FATURADO, 0)                              AS VALOR_FATURADO,
    F.ID_FATURA_OLD,
    F.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_FATURA F
LEFT JOIN (
    SELECT
        FATURA_ID,
        COUNT(*)                                                AS QTD_TAREFAS,
        COUNT_IF(APROVADA)                                      AS QTD_TAREFAS_APROVADAS,
        SUM(COALESCE(HORAS_EXECUTADAS, 0))                      AS HORAS_EXECUTADAS,
        SUM(COALESCE(TOTAL_UST, 0))                             AS TOTAL_UST,
        SUM(COALESCE(VALOR_FATURADO, 0))                        AS VALOR_FATURADO
    FROM STG_TAREFA
    WHERE FATURA_ID IS NOT NULL
    GROUP BY FATURA_ID
) T ON T.FATURA_ID = F.ID;

CREATE OR REPLACE TABLE FCT_PROJETO AS
SELECT
    HASH('PROJETO', P.ID)                                      AS SK_PROJETO,
    P.ID                                                       AS ID_PROJETO,
    HASH('PRODUTO', P.PRODUTO_ID)                              AS SK_PRODUTO,
    HASH('STATUS', P.STATUS_ID)                                AS SK_STATUS,
    HASH('UNIDADE', P.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    IFF(P.DATA_SOLICITACAO IS NULL, NULL, TO_NUMBER(TO_CHAR(P.DATA_SOLICITACAO::DATE, 'YYYYMMDD'))) AS SK_DATA_SOLICITACAO,
    IFF(P.DATA_PROTOTIPO IS NULL, NULL, TO_NUMBER(TO_CHAR(P.DATA_PROTOTIPO::DATE, 'YYYYMMDD'))) AS SK_DATA_PROTOTIPO,
    IFF(P.DATA_DESENV IS NULL, NULL, TO_NUMBER(TO_CHAR(P.DATA_DESENV::DATE, 'YYYYMMDD'))) AS SK_DATA_DESENV,
    IFF(P.DATA_HOMOLOG IS NULL, NULL, TO_NUMBER(TO_CHAR(P.DATA_HOMOLOG::DATE, 'YYYYMMDD'))) AS SK_DATA_HOMOLOG,
    IFF(P.DATA_PROD IS NULL, NULL, TO_NUMBER(TO_CHAR(P.DATA_PROD::DATE, 'YYYYMMDD'))) AS SK_DATA_PRODUCAO,
    P.PROGRESSO,
    IFF(P.INATIVO, FALSE, TRUE)                                AS FL_ATIVO,
    DATEDIFF('DAY', P.DATA_SOLICITACAO, P.DATA_PROD)           AS LEAD_TIME_DIAS,
    COALESCE(T.QTD_TAREFAS, 0)                                 AS QUANTIDADE_TAREFAS,
    COALESCE(T.QTD_TAREFAS_CONCLUIDAS, 0)                      AS QUANTIDADE_TAREFAS_CONCLUIDAS,
    COALESCE(T.QTD_TAREFAS_APROVADAS, 0)                       AS QUANTIDADE_TAREFAS_APROVADAS,
    COALESCE(T.HORAS_EXECUTADAS, 0)                            AS HORAS_EXECUTADAS,
    COALESCE(T.TOTAL_UST, 0)                                   AS TOTAL_UST,
    COALESCE(T.VALOR_FATURADO, 0)                              AS VALOR_FATURADO,
    COALESCE(T.PERCENTUAL_COM_EVIDENCIA, 0)                    AS PERCENTUAL_TAREFAS_COM_EVIDENCIA,
    P.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_PROJETO P
LEFT JOIN (
    SELECT
        PROJETO_ID,
        COUNT(*)                                                AS QTD_TAREFAS,
        COUNT_IF(DATA_FIM IS NOT NULL)                          AS QTD_TAREFAS_CONCLUIDAS,
        COUNT_IF(APROVADA)                                      AS QTD_TAREFAS_APROVADAS,
        SUM(COALESCE(HORAS_EXECUTADAS, 0))                      AS HORAS_EXECUTADAS,
        SUM(COALESCE(TOTAL_UST, 0))                             AS TOTAL_UST,
        SUM(COALESCE(VALOR_FATURADO, 0))                        AS VALOR_FATURADO,
        100.0 * COUNT_IF(NULLIF(TRIM(EVIDENCIAS), '') IS NOT NULL
                      OR NULLIF(TRIM(EVIDENCIA_COMMIT_SHA), '') IS NOT NULL
                      OR NULLIF(TRIM(EVIDENCIA_ANEXO), '') IS NOT NULL)
              / NULLIF(COUNT(*), 0)                             AS PERCENTUAL_COM_EVIDENCIA
    FROM STG_TAREFA
    WHERE PROJETO_ID IS NOT NULL
    GROUP BY PROJETO_ID
) T ON T.PROJETO_ID = P.ID;

CREATE OR REPLACE TABLE FCT_CONTRATO AS
SELECT
    HASH('CONTRATO', C.ID)                                     AS SK_CONTRATO,
    C.ID                                                       AS ID_CONTRATO,
    HASH('UNIDADE', C.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    IFF(C.DATA_INICIO IS NULL, NULL, TO_NUMBER(TO_CHAR(C.DATA_INICIO, 'YYYYMMDD'))) AS SK_DATA_INICIO,
    IFF(C.DATA_FIM IS NULL, NULL, TO_NUMBER(TO_CHAR(C.DATA_FIM, 'YYYYMMDD'))) AS SK_DATA_FIM,
    C.ATIVO                                                    AS FL_ATIVO,
    C.UST_VALOR,
    C.UST_CONTRATADAS,
    C.UST_ADITIVADAS,
    C.DEDUCOES_HORAS,
    C.DEDUCOES_UST,
    C.OUTROS_HORAS,
    C.OUTROS_UST,
    COALESCE(T.TOTAL_UST_EXECUTADA, 0)                         AS TOTAL_UST_EXECUTADA,
    COALESCE(T.TOTAL_VALOR_FATURADO, 0)                        AS TOTAL_VALOR_FATURADO,
    COALESCE(T.TOTAL_HORAS_EXECUTADAS, 0)                      AS TOTAL_HORAS_EXECUTADAS,
    COALESCE(T.QUANTIDADE_TAREFAS, 0)                          AS QUANTIDADE_TAREFAS,
    COALESCE(F.QUANTIDADE_FATURAS, 0)                          AS QUANTIDADE_FATURAS,
    IFF(COALESCE(C.UST_CONTRATADAS, 0) + COALESCE(C.UST_ADITIVADAS, 0) = 0, NULL,
        100.0 * COALESCE(T.TOTAL_UST_EXECUTADA, 0)
        / (COALESCE(C.UST_CONTRATADAS, 0) + COALESCE(C.UST_ADITIVADAS, 0))) AS PERCENTUAL_UST_CONSUMIDA,
    C.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_CONTRATO C
LEFT JOIN (
    SELECT
        S.CONTRATO_ID,
        COUNT(T.ID)                                             AS QUANTIDADE_TAREFAS,
        SUM(COALESCE(T.TOTAL_UST, 0))                           AS TOTAL_UST_EXECUTADA,
        SUM(COALESCE(T.VALOR_FATURADO, 0))                      AS TOTAL_VALOR_FATURADO,
        SUM(COALESCE(T.HORAS_EXECUTADAS, 0))                    AS TOTAL_HORAS_EXECUTADAS
    FROM STG_SERVICO S
    LEFT JOIN STG_REGRA R ON R.SERVICO_ID = S.ID
    LEFT JOIN STG_TAREFA T ON T.REGRA_ID = R.ID
    GROUP BY S.CONTRATO_ID
) T ON T.CONTRATO_ID = C.ID
LEFT JOIN (
    SELECT CONTRATO_ID, COUNT(*) AS QUANTIDADE_FATURAS
    FROM STG_FATURA
    GROUP BY CONTRATO_ID
) F ON F.CONTRATO_ID = C.ID;

CREATE OR REPLACE TABLE FCT_MOVIMENTO_CONTRATO AS
SELECT
    HASH('MOV_CONTRATO', 'AJUSTE', A.ID)                       AS SK_MOVIMENTO_CONTRATO,
    'AJUSTE'                                                   AS TIPO_MOVIMENTO,
    A.ID                                                       AS ID_MOVIMENTO,
    HASH('CONTRATO', A.CONTRATO_ID)                            AS SK_CONTRATO,
    A.DATA_INICIO,
    A.DATA_FIM,
    A.TIPO                                                     AS SUBTIPO,
    A.UST_VALOR,
    A.UST_CONTRATADAS,
    NULL::FLOAT                                                AS UST_RENOVADAS,
    A.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_AJUSTE A
UNION ALL
SELECT
    HASH('MOV_CONTRATO', 'REAJUSTE', R.ID),
    'REAJUSTE',
    R.ID,
    HASH('CONTRATO', R.CONTRATO_ID),
    R.DATA_INICIO,
    R.DATA_FIM,
    NULL,
    R.UST_VALOR,
    NULL,
    NULL,
    R.DW_INGESTED_AT
FROM STG_REAJUSTE R
UNION ALL
SELECT
    HASH('MOV_CONTRATO', 'RENOVACAO', R.ID),
    'RENOVACAO',
    R.ID,
    HASH('CONTRATO', R.CONTRATO_ID),
    R.DATA_INICIO,
    R.DATA_FIM,
    NULL,
    NULL,
    NULL,
    R.UST_CONTRATADAS,
    R.DW_INGESTED_AT
FROM STG_RENOVACAO R;

CREATE OR REPLACE TABLE FCT_SPRINT AS
SELECT
    HASH('SPRINT', S.ID)                                       AS SK_SPRINT,
    S.ID                                                       AS ID_SPRINT,
    HASH('COORDENACAO', S.COORDENACAO_ID)                      AS SK_COORDENACAO,
    TO_NUMBER(TO_CHAR(S.DATA_INICIO::DATE, 'YYYYMMDD'))        AS SK_DATA_INICIO,
    TO_NUMBER(TO_CHAR(S.DATA_FIM::DATE, 'YYYYMMDD'))           AS SK_DATA_FIM,
    DATEDIFF('DAY', S.DATA_INICIO, S.DATA_FIM) + 1             AS QUANTIDADE_DIAS,
    COALESCE(T.QTD_TAREFAS, 0)                                 AS QUANTIDADE_TAREFAS,
    COALESCE(T.QTD_CONCLUIDAS, 0)                              AS QUANTIDADE_CONCLUIDAS,
    COALESCE(T.QTD_APROVADAS, 0)                               AS QUANTIDADE_APROVADAS,
    COALESCE(T.HORAS_EXECUTADAS, 0)                            AS HORAS_EXECUTADAS,
    COALESCE(T.TOTAL_UST, 0)                                   AS TOTAL_UST,
    S.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_SPRINT S
LEFT JOIN (
    SELECT
        SPRINT_ID,
        COUNT(*)                                                AS QTD_TAREFAS,
        COUNT_IF(DATA_FIM IS NOT NULL)                          AS QTD_CONCLUIDAS,
        COUNT_IF(APROVADA)                                      AS QTD_APROVADAS,
        SUM(COALESCE(HORAS_EXECUTADAS, 0))                      AS HORAS_EXECUTADAS,
        SUM(COALESCE(TOTAL_UST, 0))                             AS TOTAL_UST
    FROM STG_TAREFA
    WHERE SPRINT_ID IS NOT NULL
    GROUP BY SPRINT_ID
) T ON T.SPRINT_ID = S.ID;

CREATE OR REPLACE TABLE FCT_ANEXO_PROJETO AS
SELECT
    HASH('ANEXO', A.ID)                                        AS SK_ANEXO,
    A.ID                                                       AS ID_ANEXO,
    HASH('PROJETO', A.PROJETO_ID)                              AS SK_PROJETO,
    IFF(A.HORARIO IS NULL, NULL, TO_NUMBER(TO_CHAR(A.HORARIO::DATE, 'YYYYMMDD'))) AS SK_DATA_ANEXO,
    A.DESCRICAO,
    A.ARQUIVO,
    REGEXP_SUBSTR(LOWER(A.ARQUIVO), '\\.(png|jpg|jpeg|gif|webp|bmp|svg|pdf|docx?|xlsx?|zip)(\\?|$)', 1, 1, 'e', 1) AS EXTENSAO_ARQUIVO,
    IFF(REGEXP_LIKE(LOWER(A.ARQUIVO), '\\.(png|jpg|jpeg|gif|webp|bmp|svg)(\\?|$)'), TRUE, FALSE) AS FL_IMAGEM,
    A.HORARIO,
    A.DW_INGESTED_AT                                           AS DT_CARGA
FROM STG_ANEXOS A;
