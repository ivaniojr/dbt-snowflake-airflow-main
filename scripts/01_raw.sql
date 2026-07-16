USE DATABASE DRAGON_DB;
USE SCHEMA MUNKA_RAW;

-- ============================================================================
-- 2. CAMADA RAW
-- ============================================================================
-- A carga do PostgreSQL/Airflow/dbt deve gravar nestas tabelas.
-- PASSWORD e REGISTRATION_HASH existem somente na RAW e não seguem para STG/DW.

CREATE TABLE IF NOT EXISTS RAW_AB_PERMISSION (
    ID                               NUMBER(38,0),
    NAME                             VARCHAR(100),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_AB_PERMISSION_VIEW (
    ID                               NUMBER(38,0),
    PERMISSION_ID                    NUMBER(38,0),
    VIEW_MENU_ID                     NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_AB_PERMISSION_VIEW_ROLE (
    ID                               NUMBER(38,0),
    PERMISSION_VIEW_ID               NUMBER(38,0),
    ROLE_ID                          NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_AB_REGISTER_USER (
    ID                               NUMBER(38,0),
    FIRST_NAME                       VARCHAR(64),
    LAST_NAME                        VARCHAR(64),
    USERNAME                         VARCHAR(64),
    PASSWORD                         VARCHAR(256),
    EMAIL                            VARCHAR(64),
    REGISTRATION_DATE                TIMESTAMP_NTZ,
    REGISTRATION_HASH                VARCHAR(256),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_AB_ROLE (
    ID                               NUMBER(38,0),
    NAME                             VARCHAR(64),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_AB_USER (
    ID                               NUMBER(38,0),
    FIRST_NAME                       VARCHAR(64),
    LAST_NAME                        VARCHAR(64),
    USERNAME                         VARCHAR(64),
    PASSWORD                         VARCHAR(256),
    ACTIVE                           BOOLEAN,
    EMAIL                            VARCHAR(64),
    LAST_LOGIN                       TIMESTAMP_NTZ,
    LOGIN_COUNT                      NUMBER(38,0),
    FAIL_LOGIN_COUNT                 NUMBER(38,0),
    CREATED_ON                       TIMESTAMP_NTZ,
    CHANGED_ON                       TIMESTAMP_NTZ,
    CREATED_BY_FK                    NUMBER(38,0),
    CHANGED_BY_FK                    NUMBER(38,0),
    CARGO_ID                         NUMBER(38,0),
    NIVEL_ID                         NUMBER(38,0),
    COORDENACAO_ID                   NUMBER(38,0),
    JORNADA_SEMANAL                  NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_AB_USER_ROLE (
    ID                               NUMBER(38,0),
    USER_ID                          NUMBER(38,0),
    ROLE_ID                          NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_AB_VIEW_MENU (
    ID                               NUMBER(38,0),
    NAME                             VARCHAR(250),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_AJUSTE (
    ID                               NUMBER(38,0),
    DATA_INICIO                      DATE,
    DATA_FIM                         DATE,
    TIPO                             VARCHAR,
    UST_VALOR                        FLOAT,
    UST_CONTRATADAS                  FLOAT,
    CONTRATO_ID                      NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_ALEMBIC_VERSION (
    VERSION_NUM                      VARCHAR(32),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_ANEXOS (
    ID                               NUMBER(38,0),
    PROJETO_ID                       NUMBER(38,0),
    DESCRICAO                        VARCHAR,
    ARQUIVO                          VARCHAR,
    HORARIO                          TIMESTAMP_NTZ,
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_CARGO (
    ID                               NUMBER(38,0),
    NOME                             VARCHAR,
    FATURAVEL                        BOOLEAN,
    UNIDADE_ADM_ID                   NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_CENARIO (
    ID                               NUMBER(38,0),
    NOME                             VARCHAR,
    PONTUACAO                        NUMBER(38,0),
    REQUISITO_ID                     NUMBER(38,0),
    CENARIO_PADRAO                   BOOLEAN,
    UNIDADE_ADM_ID                   NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_COMENTARIO (
    ID                               NUMBER(38,0),
    AUTOR_ID                         NUMBER(38,0),
    TAREFA_ID                        NUMBER(38,0),
    CONTEUDO                         VARCHAR,
    HORARIO                          TIMESTAMP_NTZ,
    UNIDADE_ADM_ID                   NUMBER(38,0),
    ID_COMENTARIO_OLD                NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_COMPLEXIDADE (
    ID                               NUMBER(38,0),
    NOME                             VARCHAR,
    PONTUACAO_MAIOR_QUE              NUMBER(38,0),
    PONTUACAO_MENOR_QUE              NUMBER(38,0),
    UNIDADE_ADM_ID                   NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_CONTRATO (
    ID                               NUMBER(38,0),
    NOME                             VARCHAR,
    ATIVO                            BOOLEAN,
    UST_VALOR                        FLOAT,
    UST_CONTRATADAS                  FLOAT,
    UST_ADITIVADAS                   FLOAT,
    DEDUCOES_HORAS                   FLOAT,
    DEDUCOES_UST                     FLOAT,
    OUTROS_HORAS                     FLOAT,
    OUTROS_UST                       FLOAT,
    DATA_INICIO                      DATE,
    DATA_FIM                         DATE,
    DATA_VIGENCIA                    DATE,
    UNIDADE_ADM_ID                   NUMBER(38,0),
    FATURAR_HPA                      BOOLEAN,
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_CONTRATOS_USUARIOS (
    ID                               NUMBER(38,0),
    USUARIO_ID                       NUMBER(38,0),
    CONTRATO_ID                      NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_COORD_PROJETO (
    ID                               NUMBER(38,0),
    PROJETO_ID                       NUMBER(38,0),
    COORDENACAO_ID                   NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_COORDENACAO (
    ID                               NUMBER(38,0),
    NOME                             VARCHAR,
    COR                              VARCHAR,
    UNIDADE_ADM_ID                   NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_ETIQUETA (
    ID                               NUMBER(38,0),
    NOME                             VARCHAR,
    COR                              VARCHAR,
    UNIDADE_ADM_ID                   NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_FATOR_COMPLEXIDADE_UST (
    ID                               NUMBER(38,0),
    FATOR_COMPLEXIDADE               FLOAT,
    CARGO_ID                         NUMBER(38,0),
    NIVEL_ID                         NUMBER(38,0),
    CONTRATO_ID                      NUMBER(38,0),
    ATIVO                            BOOLEAN,
    ID_FATOR_OLD                     NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_FATURA (
    ID                               NUMBER(38,0),
    DATA_INICIO                      TIMESTAMP_NTZ,
    DATA_FIM                         TIMESTAMP_NTZ,
    DATA_CRIACAO                     TIMESTAMP_NTZ,
    CONTRATO_ID                      NUMBER(38,0),
    ID_FATURA_OLD                    NUMBER(38,0),
    REAJUSTE_ID                      NUMBER(38,0),
    RENOVACAO_ID                     NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_FICHA_INDICADOR (
    ID                               NUMBER(38,0),
    TITULO                           VARCHAR,
    GUIA_ID                          NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_FICHAS_PROJETOS (
    ID                               NUMBER(38,0),
    PROJETO_ID                       NUMBER(38,0),
    FICHA_ID                         NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_LIDER_PROJETOS (
    ID                               NUMBER(38,0),
    PROJETO_ID                       NUMBER(38,0),
    AB_USER_ID                       NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_NIVEL (
    ID                               NUMBER(38,0),
    NOME                             VARCHAR,
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_NIVEL_SUPERIOR (
    ID                               NUMBER(38,0),
    NIVEL_SUPERIOR_ID                NUMBER(38,0),
    NIVEL_INFERIOR_ID                NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_OBJETIVO (
    ID                               NUMBER(38,0),
    NUMERO                           VARCHAR,
    TITULO                           VARCHAR,
    DESCRICAO                        VARCHAR,
    UNIDADE_ADM_ID                   NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_ORIGEM (
    ID                               NUMBER(38,0),
    NOME                             VARCHAR,
    ENDERECO                         VARCHAR,
    DESCRICAO                        VARCHAR,
    UNIDADE_ADM_ID                   NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_ORIGENS_PROJETO (
    ID                               NUMBER(38,0),
    PROJETO_ID                       NUMBER(38,0),
    ORIGEM_ID                        NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_PRODUTO (
    ID                               NUMBER(38,0),
    NOME                             VARCHAR,
    UNIDADE_SUPERIOR_ID              NUMBER(38,0),
    UNIDADE_EXECUTANTE_ID            NUMBER(38,0),
    UNIDADE_ADM_ID                   NUMBER(38,0),
    DATA_SOLICITACAO                 TIMESTAMP_NTZ,
    LINK_GIT                         VARCHAR,
    DESCRICAO                        VARCHAR,
    LINK_HOMOLOG                     VARCHAR,
    LINK_PROD                        VARCHAR,
    INF_ADICIONAL                    VARCHAR,
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_PROJETO (
    ID                               NUMBER(38,0),
    UNIDADE_SUPERIOR_ID              NUMBER(38,0),
    UNIDADE_ADM_ID                   NUMBER(38,0),
    DATA_SOLICITACAO                 TIMESTAMP_NTZ,
    DESCRICAO                        VARCHAR,
    NOME                             VARCHAR,
    PRODUTO_ID                       NUMBER(38,0),
    ABRANGENCIA                      VARCHAR,
    ACESSO                           VARCHAR,
    NUMERO_SEI                       NUMBER(38,0),
    DATA_PROTOTIPO                   TIMESTAMP_NTZ,
    LINK_PROTOTIPO                   VARCHAR,
    DATA_DESENV                      TIMESTAMP_NTZ,
    LINK_DESENV                      VARCHAR,
    DATA_HOMOLOG                     TIMESTAMP_NTZ,
    DATA_PROD                        TIMESTAMP_NTZ,
    STATUS_ID                        NUMBER(38,0),
    PROGRESSO                        NUMBER(38,0),
    OBS_PROGRESSO                    VARCHAR,
    JUSTIFICATIVA                    VARCHAR,
    INATIVO                          BOOLEAN,
    DATA_PREVISAO_INICIO             TIMESTAMP_NTZ,
    DATA_PREVISAO_TERMINO            TIMESTAMP_NTZ,
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_PROJETO_RESULTADO_CHAVE (
    ID                               NUMBER(38,0),
    PROJETO_ID                       NUMBER(38,0),
    RESULTADO_CHAVE_ID               NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_REAJUSTE (
    ID                               NUMBER(38,0),
    DATA_INICIO                      DATE,
    DATA_FIM                         DATE,
    UST_VALOR                        FLOAT,
    CONTRATO_ID                      NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_REGRA (
    ID                               NUMBER(38,0),
    SERVICO_ID                       NUMBER(38,0),
    COMPLEXIDADE_ID                  NUMBER(38,0),
    CARGO_ID                         NUMBER(38,0),
    NIVEL_ID                         NUMBER(38,0),
    HET_MAX                          FLOAT,
    DESATIVADA                       BOOLEAN,
    ID_REGRA_OLD                     NUMBER(38,0),
    FATOR_AJUSTE                     FLOAT,
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_RENOVACAO (
    ID                               NUMBER(38,0),
    DATA_INICIO                      DATE,
    DATA_FIM                         DATE,
    UST_CONTRATADAS                  FLOAT,
    CONTRATO_ID                      NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_REQUISITO (
    ID                               NUMBER(38,0),
    NOME                             VARCHAR,
    UNIDADE_ADM_ID                   NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_RESULTADO_CHAVE (
    ID                               NUMBER(38,0),
    OBJETIVO_ID                      NUMBER(38,0),
    NUMERO                           VARCHAR,
    TITULO                           VARCHAR,
    DESCRICAO                        VARCHAR,
    UNIDADE_ADM_ID                   NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_SERVICO (
    ID                               NUMBER(38,0),
    NOME                             VARCHAR,
    ESCOPO                           VARCHAR,
    ENTREGAVEIS                      VARCHAR,
    ATIVIDADES                       VARCHAR,
    FATURAVEL                        BOOLEAN,
    CONTRATO_ID                      NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_SPRINT (
    ID                               NUMBER(38,0),
    DATA_INICIO                      TIMESTAMP_NTZ,
    DATA_FIM                         TIMESTAMP_NTZ,
    OBJETIVOS                        VARCHAR,
    COORDENACAO_ID                   NUMBER(38,0),
    DESCRICAO_CURTA                  VARCHAR,
    ID_SPRINT_OLD                    NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_STATUS (
    ID                               NUMBER(38,0),
    NOME                             VARCHAR,
    ORDEM                            NUMBER(38,0),
    MOSTRAR_QUADRO                   BOOLEAN,
    UNIDADE_ADM_ID                   NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_TAREFA (
    ID                               NUMBER(38,0),
    NOME                             VARCHAR,
    DESCRICAO                        VARCHAR,
    CARGO_ID                         NUMBER(38,0),
    NIVEL_ID                         NUMBER(38,0),
    RESPONSAVEL_ID                   NUMBER(38,0),
    DATA_INICIO                      TIMESTAMP_NTZ,
    DATA_FIM                         TIMESTAMP_NTZ,
    ETIQUETA_ID                      NUMBER(38,0),
    PROJETO_ID                       NUMBER(38,0),
    PRODUTO_ID                       NUMBER(38,0),
    TIPO                             VARCHAR,
    NUM_HELPDESK                     VARCHAR,
    SPRINT_ID                        NUMBER(38,0),
    REGRA_ID                         NUMBER(38,0),
    STATUS_ID                        NUMBER(38,0),
    HORAS_EXECUTADAS                 FLOAT,
    EVIDENCIAS                       VARCHAR,
    EVIDENCIA_COMMIT_SHA             VARCHAR,
    EVIDENCIA_ANEXO                  VARCHAR,
    FATURA_ID                        NUMBER(38,0),
    VALOR_FATURADO                   FLOAT,
    TOTAL_UST                        FLOAT,
    DATA_ULTIMA_ATUALIZACAO          TIMESTAMP_NTZ,
    USER_ABERTURA_ID                 NUMBER(38,0),
    DATA_ABERTURA                    TIMESTAMP_NTZ,
    APROVADA                         BOOLEAN,
    USER_APROVADA_ID                 NUMBER(38,0),
    ID_TAREFA_OLD                    NUMBER(38,0),
    USER_ULTIMA_ATUALIZACAO_ID       NUMBER(38,0),
    TAREFA_PAI_ID                    NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_TAREFAS_CENARIOS (
    ID                               NUMBER(38,0),
    TAREFA_ID                        NUMBER(38,0),
    CENARIO_ID                       NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_TECNOLOGIA (
    ID                               NUMBER(38,0),
    NOME                             VARCHAR,
    UNIDADE_ADM_ID                   NUMBER(38,0),
    ID_TECNOLOGIA_OLD                NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_TECNOLOGIAS_PROJETO (
    ID                               NUMBER(38,0),
    PROJETO_ID                       NUMBER(38,0),
    TECNOLOGIA_ID                    NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_TIPO (
    ID                               NUMBER(38,0),
    NOME                             VARCHAR,
    UNIDADE_ADM_ID                   NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_TIPO_STATUS (
    ID                               NUMBER(38,0),
    STATUS_ID                        NUMBER(38,0),
    TIPO_ID                          NUMBER(38,0),
    ID_TIPO_STATUS_OLD               NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_UNIDADE_ADM (
    ID                               NUMBER(38,0),
    NOME_UNIDADE                     VARCHAR,
    SIGLA                            VARCHAR,
    RESPONSAVEL                      VARCHAR,
    EMAIL                            VARCHAR,
    TELEFONE                         VARCHAR,
    CODIGO_SEI                       NUMBER(38,0),
    UNIDADE_SUPERIOR_ID              NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);

CREATE TABLE IF NOT EXISTS RAW_UNIDADE_ADM_SUPERIOR (
    ID                               NUMBER(38,0),
    NOME_UNIDADE                     VARCHAR,
    SIGLA                            VARCHAR,
    RESPONSAVEL                      VARCHAR,
    EMAIL                            VARCHAR,
    TELEFONE                         VARCHAR,
    CODIGO_SEI                       NUMBER(38,0),
    DW_BATCH_ID                      VARCHAR,
    DW_RECORD_SOURCE                 VARCHAR DEFAULT 'POSTGRES.MUNKA',
    DW_SOURCE_UPDATED_AT             TIMESTAMP_NTZ,
    DW_INGESTED_AT                   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DW_ROW_HASH                      VARCHAR
);
