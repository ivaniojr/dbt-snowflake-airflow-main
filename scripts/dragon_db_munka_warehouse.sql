-- ============================================================================
-- DRAGON_DB.MUNKA - DATA WAREHOUSE COMPLETO
-- Origem: PostgreSQL / schema munka
-- Destino: Snowflake
-- Camadas no mesmo schema, separadas por prefixo:
--   CTL_     controle e auditoria
--   RAW_     réplica da origem, com metadados de carga
--   STG_     limpeza, padronização e deduplicação
--   DIM_     dimensões
--   FCT_     fatos
--   BRIDGE_  relacionamentos muitos-para-muitos
--   MART_    camada semântica/consumo
--   DQ_      controles de qualidade
-- ============================================================================

CREATE DATABASE IF NOT EXISTS DRAGON_DB;
CREATE SCHEMA IF NOT EXISTS DRAGON_DB.MUNKA;
USE DATABASE DRAGON_DB;
USE SCHEMA MUNKA;

-- ============================================================================
-- 1. CAMADA DE CONTROLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS CTL_CARGA_BATCH (
    BATCH_ID             VARCHAR NOT NULL,
    ORIGEM               VARCHAR NOT NULL,
    DATA_INICIO          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    DATA_FIM             TIMESTAMP_NTZ,
    STATUS               VARCHAR DEFAULT 'INICIADO',
    LINHAS_LIDAS         NUMBER(38,0) DEFAULT 0,
    LINHAS_CARREGADAS    NUMBER(38,0) DEFAULT 0,
    LINHAS_REJEITADAS    NUMBER(38,0) DEFAULT 0,
    MENSAGEM             VARCHAR,
    CONSTRAINT CTL_CARGA_BATCH_PK PRIMARY KEY (BATCH_ID)
);

CREATE TABLE IF NOT EXISTS CTL_REJEICAO (
    BATCH_ID             VARCHAR,
    TABELA_ORIGEM        VARCHAR,
    CHAVE_REGISTRO       VARCHAR,
    MOTIVO               VARCHAR,
    REGISTRO             VARIANT,
    DATA_REJEICAO        TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

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

-- ============================================================================
-- 3. CAMADA STAGING
-- ============================================================================
-- Deduplica pela chave primária da origem e mantém o registro mais recente.
-- Campos textuais vazios são convertidos para NULL.

CREATE OR REPLACE VIEW STG_AB_PERMISSION AS
SELECT
    ID,
    NULLIF(TRIM(NAME), '') AS NAME,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_AB_PERMISSION
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_AB_PERMISSION_VIEW AS
SELECT
    ID,
    PERMISSION_ID,
    VIEW_MENU_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_AB_PERMISSION_VIEW
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_AB_PERMISSION_VIEW_ROLE AS
SELECT
    ID,
    PERMISSION_VIEW_ID,
    ROLE_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_AB_PERMISSION_VIEW_ROLE
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_AB_REGISTER_USER AS
SELECT
    ID,
    NULLIF(TRIM(FIRST_NAME), '') AS FIRST_NAME,
    NULLIF(TRIM(LAST_NAME), '') AS LAST_NAME,
    NULLIF(TRIM(USERNAME), '') AS USERNAME,
    NULLIF(TRIM(EMAIL), '') AS EMAIL,
    REGISTRATION_DATE,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_AB_REGISTER_USER
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_AB_ROLE AS
SELECT
    ID,
    NULLIF(TRIM(NAME), '') AS NAME,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_AB_ROLE
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_AB_USER AS
SELECT
    ID,
    NULLIF(TRIM(FIRST_NAME), '') AS FIRST_NAME,
    NULLIF(TRIM(LAST_NAME), '') AS LAST_NAME,
    NULLIF(TRIM(USERNAME), '') AS USERNAME,
    ACTIVE,
    NULLIF(TRIM(EMAIL), '') AS EMAIL,
    LAST_LOGIN,
    LOGIN_COUNT,
    FAIL_LOGIN_COUNT,
    CREATED_ON,
    CHANGED_ON,
    CREATED_BY_FK,
    CHANGED_BY_FK,
    CARGO_ID,
    NIVEL_ID,
    COORDENACAO_ID,
    JORNADA_SEMANAL,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_AB_USER
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_AB_USER_ROLE AS
SELECT
    ID,
    USER_ID,
    ROLE_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_AB_USER_ROLE
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_AB_VIEW_MENU AS
SELECT
    ID,
    NULLIF(TRIM(NAME), '') AS NAME,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_AB_VIEW_MENU
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_AJUSTE AS
SELECT
    ID,
    DATA_INICIO,
    DATA_FIM,
    NULLIF(TRIM(TIPO), '') AS TIPO,
    UST_VALOR,
    UST_CONTRATADAS,
    CONTRATO_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_AJUSTE
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_ALEMBIC_VERSION AS
SELECT
    NULLIF(TRIM(VERSION_NUM), '') AS VERSION_NUM,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_ALEMBIC_VERSION
QUALIFY ROW_NUMBER() OVER (PARTITION BY VERSION_NUM ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_ANEXOS AS
SELECT
    ID,
    PROJETO_ID,
    NULLIF(TRIM(DESCRICAO), '') AS DESCRICAO,
    NULLIF(TRIM(ARQUIVO), '') AS ARQUIVO,
    HORARIO,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_ANEXOS
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_CARGO AS
SELECT
    ID,
    NULLIF(TRIM(NOME), '') AS NOME,
    FATURAVEL,
    UNIDADE_ADM_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_CARGO
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_CENARIO AS
SELECT
    ID,
    NULLIF(TRIM(NOME), '') AS NOME,
    PONTUACAO,
    REQUISITO_ID,
    CENARIO_PADRAO,
    UNIDADE_ADM_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_CENARIO
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_COMENTARIO AS
SELECT
    ID,
    AUTOR_ID,
    TAREFA_ID,
    NULLIF(TRIM(CONTEUDO), '') AS CONTEUDO,
    HORARIO,
    UNIDADE_ADM_ID,
    ID_COMENTARIO_OLD,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_COMENTARIO
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_COMPLEXIDADE AS
SELECT
    ID,
    NULLIF(TRIM(NOME), '') AS NOME,
    PONTUACAO_MAIOR_QUE,
    PONTUACAO_MENOR_QUE,
    UNIDADE_ADM_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_COMPLEXIDADE
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_CONTRATO AS
SELECT
    ID,
    NULLIF(TRIM(NOME), '') AS NOME,
    ATIVO,
    UST_VALOR,
    UST_CONTRATADAS,
    UST_ADITIVADAS,
    DEDUCOES_HORAS,
    DEDUCOES_UST,
    OUTROS_HORAS,
    OUTROS_UST,
    DATA_INICIO,
    DATA_FIM,
    DATA_VIGENCIA,
    UNIDADE_ADM_ID,
    FATURAR_HPA,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_CONTRATO
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_CONTRATOS_USUARIOS AS
SELECT
    ID,
    USUARIO_ID,
    CONTRATO_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_CONTRATOS_USUARIOS
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_COORD_PROJETO AS
SELECT
    ID,
    PROJETO_ID,
    COORDENACAO_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_COORD_PROJETO
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_COORDENACAO AS
SELECT
    ID,
    NULLIF(TRIM(NOME), '') AS NOME,
    NULLIF(TRIM(COR), '') AS COR,
    UNIDADE_ADM_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_COORDENACAO
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_ETIQUETA AS
SELECT
    ID,
    NULLIF(TRIM(NOME), '') AS NOME,
    NULLIF(TRIM(COR), '') AS COR,
    UNIDADE_ADM_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_ETIQUETA
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_FATOR_COMPLEXIDADE_UST AS
SELECT
    ID,
    FATOR_COMPLEXIDADE,
    CARGO_ID,
    NIVEL_ID,
    CONTRATO_ID,
    ATIVO,
    ID_FATOR_OLD,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_FATOR_COMPLEXIDADE_UST
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_FATURA AS
SELECT
    ID,
    DATA_INICIO,
    DATA_FIM,
    DATA_CRIACAO,
    CONTRATO_ID,
    ID_FATURA_OLD,
    REAJUSTE_ID,
    RENOVACAO_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_FATURA
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_FICHA_INDICADOR AS
SELECT
    ID,
    NULLIF(TRIM(TITULO), '') AS TITULO,
    GUIA_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_FICHA_INDICADOR
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_FICHAS_PROJETOS AS
SELECT
    ID,
    PROJETO_ID,
    FICHA_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_FICHAS_PROJETOS
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_LIDER_PROJETOS AS
SELECT
    ID,
    PROJETO_ID,
    AB_USER_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_LIDER_PROJETOS
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_NIVEL AS
SELECT
    ID,
    NULLIF(TRIM(NOME), '') AS NOME,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_NIVEL
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_NIVEL_SUPERIOR AS
SELECT
    ID,
    NIVEL_SUPERIOR_ID,
    NIVEL_INFERIOR_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_NIVEL_SUPERIOR
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_OBJETIVO AS
SELECT
    ID,
    NULLIF(TRIM(NUMERO), '') AS NUMERO,
    NULLIF(TRIM(TITULO), '') AS TITULO,
    NULLIF(TRIM(DESCRICAO), '') AS DESCRICAO,
    UNIDADE_ADM_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_OBJETIVO
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_ORIGEM AS
SELECT
    ID,
    NULLIF(TRIM(NOME), '') AS NOME,
    NULLIF(TRIM(ENDERECO), '') AS ENDERECO,
    NULLIF(TRIM(DESCRICAO), '') AS DESCRICAO,
    UNIDADE_ADM_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_ORIGEM
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_ORIGENS_PROJETO AS
SELECT
    ID,
    PROJETO_ID,
    ORIGEM_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_ORIGENS_PROJETO
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_PRODUTO AS
SELECT
    ID,
    NULLIF(TRIM(NOME), '') AS NOME,
    UNIDADE_SUPERIOR_ID,
    UNIDADE_EXECUTANTE_ID,
    UNIDADE_ADM_ID,
    DATA_SOLICITACAO,
    NULLIF(TRIM(LINK_GIT), '') AS LINK_GIT,
    NULLIF(TRIM(DESCRICAO), '') AS DESCRICAO,
    NULLIF(TRIM(LINK_HOMOLOG), '') AS LINK_HOMOLOG,
    NULLIF(TRIM(LINK_PROD), '') AS LINK_PROD,
    NULLIF(TRIM(INF_ADICIONAL), '') AS INF_ADICIONAL,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_PRODUTO
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_PROJETO AS
SELECT
    ID,
    UNIDADE_SUPERIOR_ID,
    UNIDADE_ADM_ID,
    DATA_SOLICITACAO,
    NULLIF(TRIM(DESCRICAO), '') AS DESCRICAO,
    NULLIF(TRIM(NOME), '') AS NOME,
    PRODUTO_ID,
    NULLIF(TRIM(ABRANGENCIA), '') AS ABRANGENCIA,
    NULLIF(TRIM(ACESSO), '') AS ACESSO,
    NUMERO_SEI,
    DATA_PROTOTIPO,
    NULLIF(TRIM(LINK_PROTOTIPO), '') AS LINK_PROTOTIPO,
    DATA_DESENV,
    NULLIF(TRIM(LINK_DESENV), '') AS LINK_DESENV,
    DATA_HOMOLOG,
    DATA_PROD,
    STATUS_ID,
    PROGRESSO,
    NULLIF(TRIM(OBS_PROGRESSO), '') AS OBS_PROGRESSO,
    NULLIF(TRIM(JUSTIFICATIVA), '') AS JUSTIFICATIVA,
    INATIVO,
    DATA_PREVISAO_INICIO,
    DATA_PREVISAO_TERMINO,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_PROJETO
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_PROJETO_RESULTADO_CHAVE AS
SELECT
    ID,
    PROJETO_ID,
    RESULTADO_CHAVE_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_PROJETO_RESULTADO_CHAVE
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_REAJUSTE AS
SELECT
    ID,
    DATA_INICIO,
    DATA_FIM,
    UST_VALOR,
    CONTRATO_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_REAJUSTE
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_REGRA AS
SELECT
    ID,
    SERVICO_ID,
    COMPLEXIDADE_ID,
    CARGO_ID,
    NIVEL_ID,
    HET_MAX,
    DESATIVADA,
    ID_REGRA_OLD,
    FATOR_AJUSTE,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_REGRA
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_RENOVACAO AS
SELECT
    ID,
    DATA_INICIO,
    DATA_FIM,
    UST_CONTRATADAS,
    CONTRATO_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_RENOVACAO
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_REQUISITO AS
SELECT
    ID,
    NULLIF(TRIM(NOME), '') AS NOME,
    UNIDADE_ADM_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_REQUISITO
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_RESULTADO_CHAVE AS
SELECT
    ID,
    OBJETIVO_ID,
    NULLIF(TRIM(NUMERO), '') AS NUMERO,
    NULLIF(TRIM(TITULO), '') AS TITULO,
    NULLIF(TRIM(DESCRICAO), '') AS DESCRICAO,
    UNIDADE_ADM_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_RESULTADO_CHAVE
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_SERVICO AS
SELECT
    ID,
    NULLIF(TRIM(NOME), '') AS NOME,
    NULLIF(TRIM(ESCOPO), '') AS ESCOPO,
    NULLIF(TRIM(ENTREGAVEIS), '') AS ENTREGAVEIS,
    NULLIF(TRIM(ATIVIDADES), '') AS ATIVIDADES,
    FATURAVEL,
    CONTRATO_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_SERVICO
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_SPRINT AS
SELECT
    ID,
    DATA_INICIO,
    DATA_FIM,
    NULLIF(TRIM(OBJETIVOS), '') AS OBJETIVOS,
    COORDENACAO_ID,
    NULLIF(TRIM(DESCRICAO_CURTA), '') AS DESCRICAO_CURTA,
    ID_SPRINT_OLD,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_SPRINT
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_STATUS AS
SELECT
    ID,
    NULLIF(TRIM(NOME), '') AS NOME,
    ORDEM,
    MOSTRAR_QUADRO,
    UNIDADE_ADM_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_STATUS
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_TAREFA AS
SELECT
    ID,
    NULLIF(TRIM(NOME), '') AS NOME,
    NULLIF(TRIM(DESCRICAO), '') AS DESCRICAO,
    CARGO_ID,
    NIVEL_ID,
    RESPONSAVEL_ID,
    DATA_INICIO,
    DATA_FIM,
    ETIQUETA_ID,
    PROJETO_ID,
    PRODUTO_ID,
    NULLIF(TRIM(TIPO), '') AS TIPO,
    NULLIF(TRIM(NUM_HELPDESK), '') AS NUM_HELPDESK,
    SPRINT_ID,
    REGRA_ID,
    STATUS_ID,
    HORAS_EXECUTADAS,
    NULLIF(TRIM(EVIDENCIAS), '') AS EVIDENCIAS,
    NULLIF(TRIM(EVIDENCIA_COMMIT_SHA), '') AS EVIDENCIA_COMMIT_SHA,
    NULLIF(TRIM(EVIDENCIA_ANEXO), '') AS EVIDENCIA_ANEXO,
    FATURA_ID,
    VALOR_FATURADO,
    TOTAL_UST,
    DATA_ULTIMA_ATUALIZACAO,
    USER_ABERTURA_ID,
    DATA_ABERTURA,
    APROVADA,
    USER_APROVADA_ID,
    ID_TAREFA_OLD,
    USER_ULTIMA_ATUALIZACAO_ID,
    TAREFA_PAI_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_TAREFA
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_TAREFAS_CENARIOS AS
SELECT
    ID,
    TAREFA_ID,
    CENARIO_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_TAREFAS_CENARIOS
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_TECNOLOGIA AS
SELECT
    ID,
    NULLIF(TRIM(NOME), '') AS NOME,
    UNIDADE_ADM_ID,
    ID_TECNOLOGIA_OLD,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_TECNOLOGIA
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_TECNOLOGIAS_PROJETO AS
SELECT
    ID,
    PROJETO_ID,
    TECNOLOGIA_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_TECNOLOGIAS_PROJETO
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_TIPO AS
SELECT
    ID,
    NULLIF(TRIM(NOME), '') AS NOME,
    UNIDADE_ADM_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_TIPO
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_TIPO_STATUS AS
SELECT
    ID,
    STATUS_ID,
    TIPO_ID,
    ID_TIPO_STATUS_OLD,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_TIPO_STATUS
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_UNIDADE_ADM AS
SELECT
    ID,
    NULLIF(TRIM(NOME_UNIDADE), '') AS NOME_UNIDADE,
    NULLIF(TRIM(SIGLA), '') AS SIGLA,
    NULLIF(TRIM(RESPONSAVEL), '') AS RESPONSAVEL,
    NULLIF(TRIM(EMAIL), '') AS EMAIL,
    NULLIF(TRIM(TELEFONE), '') AS TELEFONE,
    CODIGO_SEI,
    UNIDADE_SUPERIOR_ID,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_UNIDADE_ADM
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

CREATE OR REPLACE VIEW STG_UNIDADE_ADM_SUPERIOR AS
SELECT
    ID,
    NULLIF(TRIM(NOME_UNIDADE), '') AS NOME_UNIDADE,
    NULLIF(TRIM(SIGLA), '') AS SIGLA,
    NULLIF(TRIM(RESPONSAVEL), '') AS RESPONSAVEL,
    NULLIF(TRIM(EMAIL), '') AS EMAIL,
    NULLIF(TRIM(TELEFONE), '') AS TELEFONE,
    CODIGO_SEI,
    DW_BATCH_ID,
    DW_RECORD_SOURCE,
    DW_SOURCE_UPDATED_AT,
    DW_INGESTED_AT,
    DW_ROW_HASH
FROM RAW_UNIDADE_ADM_SUPERIOR
QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY DW_INGESTED_AT DESC, DW_SOURCE_UPDATED_AT DESC NULLS LAST) = 1;

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

-- ============================================================================
-- 6. BRIDGES / TABELAS ASSOCIATIVAS
-- ============================================================================

CREATE OR REPLACE TABLE BRIDGE_USUARIO_ROLE AS
SELECT
    HASH('USUARIO', UR.USER_ID)                                AS SK_USUARIO,
    HASH('ROLE', UR.ROLE_ID)                                   AS SK_ROLE,
    UR.ID                                                      AS ID_ASSOCIACAO,
    UR.DW_INGESTED_AT                                          AS DT_CARGA
FROM STG_AB_USER_ROLE UR;

CREATE OR REPLACE TABLE BRIDGE_ROLE_PERMISSAO_MENU AS
SELECT
    HASH('ROLE', PVR.ROLE_ID)                                  AS SK_ROLE,
    HASH('PERMISSAO', PV.PERMISSION_ID)                        AS SK_PERMISSAO,
    HASH('MENU', PV.VIEW_MENU_ID)                              AS SK_MENU,
    PVR.ID                                                     AS ID_ASSOCIACAO,
    PVR.DW_INGESTED_AT                                         AS DT_CARGA
FROM STG_AB_PERMISSION_VIEW_ROLE PVR
JOIN STG_AB_PERMISSION_VIEW PV ON PV.ID = PVR.PERMISSION_VIEW_ID;

CREATE OR REPLACE TABLE BRIDGE_CONTRATO_USUARIO AS
SELECT HASH('CONTRATO', CONTRATO_ID) AS SK_CONTRATO,
       HASH('USUARIO', USUARIO_ID) AS SK_USUARIO,
       ID AS ID_ASSOCIACAO,
       DW_INGESTED_AT AS DT_CARGA
FROM STG_CONTRATOS_USUARIOS;

CREATE OR REPLACE TABLE BRIDGE_PROJETO_COORDENACAO AS
SELECT HASH('PROJETO', PROJETO_ID) AS SK_PROJETO,
       HASH('COORDENACAO', COORDENACAO_ID) AS SK_COORDENACAO,
       ID AS ID_ASSOCIACAO,
       DW_INGESTED_AT AS DT_CARGA
FROM STG_COORD_PROJETO;

CREATE OR REPLACE TABLE BRIDGE_PROJETO_LIDER AS
SELECT HASH('PROJETO', PROJETO_ID) AS SK_PROJETO,
       HASH('USUARIO', AB_USER_ID) AS SK_USUARIO,
       ID AS ID_ASSOCIACAO,
       DW_INGESTED_AT AS DT_CARGA
FROM STG_LIDER_PROJETOS;

CREATE OR REPLACE TABLE BRIDGE_PROJETO_ORIGEM AS
SELECT HASH('PROJETO', PROJETO_ID) AS SK_PROJETO,
       HASH('ORIGEM', ORIGEM_ID) AS SK_ORIGEM,
       ID AS ID_ASSOCIACAO,
       DW_INGESTED_AT AS DT_CARGA
FROM STG_ORIGENS_PROJETO;

CREATE OR REPLACE TABLE BRIDGE_PROJETO_TECNOLOGIA AS
SELECT HASH('PROJETO', PROJETO_ID) AS SK_PROJETO,
       HASH('TECNOLOGIA', TECNOLOGIA_ID) AS SK_TECNOLOGIA,
       ID AS ID_ASSOCIACAO,
       DW_INGESTED_AT AS DT_CARGA
FROM STG_TECNOLOGIAS_PROJETO;

CREATE OR REPLACE TABLE BRIDGE_PROJETO_RESULTADO_CHAVE AS
SELECT HASH('PROJETO', PROJETO_ID) AS SK_PROJETO,
       HASH('RESULTADO_CHAVE', RESULTADO_CHAVE_ID) AS SK_RESULTADO_CHAVE,
       ID AS ID_ASSOCIACAO,
       DW_INGESTED_AT AS DT_CARGA
FROM STG_PROJETO_RESULTADO_CHAVE;

CREATE OR REPLACE TABLE BRIDGE_PROJETO_FICHA AS
SELECT HASH('PROJETO', PROJETO_ID) AS SK_PROJETO,
       HASH('FICHA_INDICADOR', FICHA_ID) AS SK_FICHA_INDICADOR,
       ID AS ID_ASSOCIACAO,
       DW_INGESTED_AT AS DT_CARGA
FROM STG_FICHAS_PROJETOS;

CREATE OR REPLACE TABLE BRIDGE_TAREFA_CENARIO AS
SELECT HASH('TAREFA', TAREFA_ID) AS SK_TAREFA,
       HASH('CENARIO', CENARIO_ID) AS SK_CENARIO,
       ID AS ID_ASSOCIACAO,
       DW_INGESTED_AT AS DT_CARGA
FROM STG_TAREFAS_CENARIOS;

CREATE OR REPLACE TABLE BRIDGE_NIVEL_HIERARQUIA AS
SELECT HASH('NIVEL', NIVEL_SUPERIOR_ID) AS SK_NIVEL_SUPERIOR,
       HASH('NIVEL', NIVEL_INFERIOR_ID) AS SK_NIVEL_INFERIOR,
       ID AS ID_ASSOCIACAO,
       DW_INGESTED_AT AS DT_CARGA
FROM STG_NIVEL_SUPERIOR;

CREATE OR REPLACE TABLE BRIDGE_TIPO_STATUS AS
SELECT HASH('TIPO', TIPO_ID) AS SK_TIPO,
       HASH('STATUS', STATUS_ID) AS SK_STATUS,
       ID AS ID_ASSOCIACAO,
       ID_TIPO_STATUS_OLD,
       DW_INGESTED_AT AS DT_CARGA
FROM STG_TIPO_STATUS;

-- ============================================================================
-- 7. MARTS / CAMADA GOLD
-- ============================================================================

CREATE OR REPLACE VIEW MART_TAREFA_DETALHE AS
SELECT
    F.ID_TAREFA,
    F.NOME                                                     AS TAREFA,
    F.DESCRICAO,
    F.TIPO,
    F.NUM_HELPDESK,
    P.ID_PROJETO,
    P.NOME                                                     AS PROJETO,
    PR.ID_PRODUTO,
    PR.NOME                                                    AS PRODUTO,
    U.ID_USUARIO                                               AS ID_RESPONSAVEL,
    U.NOME_COMPLETO                                            AS RESPONSAVEL,
    C.NOME                                                     AS CARGO,
    N.NOME                                                     AS NIVEL,
    S.NOME                                                     AS STATUS,
    E.NOME                                                     AS ETIQUETA,
    SP.ID_SPRINT,
    SP.DESCRICAO_CURTA                                         AS SPRINT,
    F.DATA_ABERTURA,
    F.DATA_INICIO,
    F.DATA_FIM,
    F.DATA_ULTIMA_ATUALIZACAO,
    F.HORAS_EXECUTADAS,
    F.DURACAO_CALENDARIO_HORAS,
    F.TOTAL_UST,
    F.VALOR_FATURADO,
    F.FL_APROVADA,
    F.FL_EM_ABERTO,
    F.FL_POSSUI_EVIDENCIA,
    F.FL_EVIDENCIA_TEXTO,
    F.FL_EVIDENCIA_COMMIT,
    F.FL_EVIDENCIA_ANEXO,
    F.ID_FATURA
FROM FCT_TAREFA F
LEFT JOIN DIM_PROJETO P ON P.SK_PROJETO = F.SK_PROJETO
LEFT JOIN DIM_PRODUTO PR ON PR.SK_PRODUTO = F.SK_PRODUTO
LEFT JOIN DIM_USUARIO U ON U.SK_USUARIO = F.SK_RESPONSAVEL
LEFT JOIN DIM_CARGO C ON C.SK_CARGO = F.SK_CARGO
LEFT JOIN DIM_NIVEL N ON N.SK_NIVEL = F.SK_NIVEL
LEFT JOIN DIM_STATUS S ON S.SK_STATUS = F.SK_STATUS
LEFT JOIN DIM_ETIQUETA E ON E.SK_ETIQUETA = F.SK_ETIQUETA
LEFT JOIN DIM_SPRINT SP ON SP.SK_SPRINT = F.SK_SPRINT;

CREATE OR REPLACE VIEW MART_PROJETO_EXECUTIVO AS
SELECT
    D.ID_PROJETO,
    D.NOME                                                     AS PROJETO,
    D.PRODUTO,
    D.STATUS,
    D.NOME_UNIDADE,
    D.UNIDADE_SUPERIOR,
    D.DATA_SOLICITACAO,
    D.DATA_PREVISAO_INICIO,
    D.DATA_PREVISAO_TERMINO,
    D.DATA_PROD,
    D.PROGRESSO,
    F.FL_ATIVO,
    F.LEAD_TIME_DIAS,
    F.QUANTIDADE_TAREFAS,
    F.QUANTIDADE_TAREFAS_CONCLUIDAS,
    F.QUANTIDADE_TAREFAS_APROVADAS,
    IFF(F.QUANTIDADE_TAREFAS = 0, NULL,
        100.0 * F.QUANTIDADE_TAREFAS_CONCLUIDAS / F.QUANTIDADE_TAREFAS) AS PERCENTUAL_TAREFAS_CONCLUIDAS,
    F.PERCENTUAL_TAREFAS_COM_EVIDENCIA,
    F.HORAS_EXECUTADAS,
    F.TOTAL_UST,
    F.VALOR_FATURADO
FROM FCT_PROJETO F
JOIN DIM_PROJETO D ON D.SK_PROJETO = F.SK_PROJETO;

CREATE OR REPLACE VIEW MART_CONTRATO_FATURAMENTO AS
SELECT
    D.ID_CONTRATO,
    D.NOME                                                     AS CONTRATO,
    D.NOME_UNIDADE,
    D.DATA_INICIO,
    D.DATA_FIM,
    D.DATA_VIGENCIA,
    F.FL_ATIVO,
    F.UST_VALOR,
    F.UST_CONTRATADAS,
    F.UST_ADITIVADAS,
    F.TOTAL_UST_EXECUTADA,
    F.PERCENTUAL_UST_CONSUMIDA,
    F.TOTAL_HORAS_EXECUTADAS,
    F.TOTAL_VALOR_FATURADO,
    F.QUANTIDADE_TAREFAS,
    F.QUANTIDADE_FATURAS,
    (COALESCE(F.UST_CONTRATADAS, 0) + COALESCE(F.UST_ADITIVADAS, 0) - COALESCE(F.TOTAL_UST_EXECUTADA, 0)) AS SALDO_UST
FROM FCT_CONTRATO F
JOIN DIM_CONTRATO D ON D.SK_CONTRATO = F.SK_CONTRATO;

CREATE OR REPLACE VIEW MART_PRODUTIVIDADE_USUARIO AS
SELECT
    DATE_TRUNC('MONTH', F.DATA_FIM::DATE)                      AS MES_REFERENCIA,
    U.ID_USUARIO,
    U.NOME_COMPLETO                                            AS RESPONSAVEL,
    U.CARGO,
    U.NIVEL,
    U.COORDENACAO,
    COUNT(*)                                                   AS QUANTIDADE_TAREFAS,
    COUNT_IF(F.DATA_FIM IS NOT NULL)                           AS QUANTIDADE_CONCLUIDAS,
    COUNT_IF(F.FL_APROVADA)                                    AS QUANTIDADE_APROVADAS,
    COUNT_IF(F.FL_POSSUI_EVIDENCIA)                            AS QUANTIDADE_COM_EVIDENCIA,
    SUM(COALESCE(F.HORAS_EXECUTADAS, 0))                       AS HORAS_EXECUTADAS,
    SUM(COALESCE(F.TOTAL_UST, 0))                              AS TOTAL_UST,
    SUM(COALESCE(F.VALOR_FATURADO, 0))                         AS VALOR_FATURADO,
    IFF(SUM(COALESCE(F.HORAS_EXECUTADAS, 0)) = 0, NULL,
        SUM(COALESCE(F.TOTAL_UST, 0)) / SUM(COALESCE(F.HORAS_EXECUTADAS, 0))) AS UST_POR_HORA
FROM FCT_TAREFA F
LEFT JOIN DIM_USUARIO U ON U.SK_USUARIO = F.SK_RESPONSAVEL
GROUP BY 1, 2, 3, 4, 5, 6;

CREATE OR REPLACE VIEW MART_EVIDENCIA_LM AS
WITH COMENTARIOS AS (
    SELECT
        TAREFA_ID,
        LISTAGG(CONTEUDO, '\n') WITHIN GROUP (ORDER BY HORARIO) AS TEXTO_COMENTARIOS,
        COUNT(*)                                                AS QUANTIDADE_COMENTARIOS
    FROM STG_COMENTARIO
    GROUP BY TAREFA_ID
), CENARIOS AS (
    SELECT
        TC.TAREFA_ID,
        LISTAGG(C.NOME, ' | ') WITHIN GROUP (ORDER BY C.NOME)   AS CENARIOS,
        SUM(COALESCE(C.PONTUACAO, 0))                           AS PONTUACAO_CENARIOS
    FROM STG_TAREFAS_CENARIOS TC
    JOIN STG_CENARIO C ON C.ID = TC.CENARIO_ID
    GROUP BY TC.TAREFA_ID
)
SELECT
    T.ID                                                       AS ID_TAREFA,
    T.NOME                                                     AS TAREFA,
    T.DESCRICAO,
    T.EVIDENCIAS,
    T.EVIDENCIA_COMMIT_SHA,
    T.EVIDENCIA_ANEXO,
    COALESCE(CO.TEXTO_COMENTARIOS, '')                         AS COMENTARIOS,
    COALESCE(CO.QUANTIDADE_COMENTARIOS, 0)                     AS QUANTIDADE_COMENTARIOS,
    CE.CENARIOS,
    CE.PONTUACAO_CENARIOS,
    P.NOME                                                     AS PROJETO,
    PR.NOME                                                    AS PRODUTO,
    S.NOME                                                     AS STATUS,
    U.NOME_COMPLETO                                            AS RESPONSAVEL,
    R.SERVICO,
    R.COMPLEXIDADE,
    R.CARGO,
    R.NIVEL,
    T.HORAS_EXECUTADAS,
    T.TOTAL_UST,
    T.VALOR_FATURADO,
    T.APROVADA                                                 AS LABEL_APROVADA,
    IFF(T.DATA_FIM IS NOT NULL, TRUE, FALSE)                   AS LABEL_CONCLUIDA,
    REGEXP_REPLACE(CONCAT_WS('\n',
        'TAREFA: ' || COALESCE(T.NOME, ''),
        'DESCRICAO: ' || COALESCE(T.DESCRICAO, ''),
        'EVIDENCIA: ' || COALESCE(T.EVIDENCIAS, ''),
        'COMMIT: ' || COALESCE(T.EVIDENCIA_COMMIT_SHA, ''),
        'ANEXO: ' || COALESCE(T.EVIDENCIA_ANEXO, ''),
        'COMENTARIOS: ' || COALESCE(CO.TEXTO_COMENTARIOS, ''),
        'CENARIOS: ' || COALESCE(CE.CENARIOS, '')
    ), '<[^>]+>', ' ')                                        AS TEXTO_MODELO,
    REGEXP_COUNT(TRIM(CONCAT_WS(' ', T.DESCRICAO, T.EVIDENCIAS, CO.TEXTO_COMENTARIOS)), '\\S+') AS QUANTIDADE_PALAVRAS,
    REGEXP_COUNT(LOWER(CONCAT_WS(' ', T.EVIDENCIAS, T.EVIDENCIA_ANEXO)), 'https?://') AS QUANTIDADE_URLS,
    IFF(REGEXP_LIKE(LOWER(COALESCE(T.EVIDENCIA_ANEXO, '')), '\\.(png|jpg|jpeg|gif|webp|bmp|svg)(\\?|$)'), TRUE, FALSE) AS FL_POSSUI_IMAGEM,
    IFF(NULLIF(TRIM(T.EVIDENCIA_COMMIT_SHA), '') IS NOT NULL, TRUE, FALSE) AS FL_POSSUI_COMMIT,
    T.DATA_ULTIMA_ATUALIZACAO
FROM STG_TAREFA T
LEFT JOIN DIM_PROJETO P ON P.ID_PROJETO = T.PROJETO_ID
LEFT JOIN DIM_PRODUTO PR ON PR.ID_PRODUTO = T.PRODUTO_ID
LEFT JOIN DIM_STATUS S ON S.ID_STATUS = T.STATUS_ID
LEFT JOIN DIM_USUARIO U ON U.ID_USUARIO = T.RESPONSAVEL_ID
LEFT JOIN DIM_REGRA R ON R.ID_REGRA = T.REGRA_ID
LEFT JOIN COMENTARIOS CO ON CO.TAREFA_ID = T.ID
LEFT JOIN CENARIOS CE ON CE.TAREFA_ID = T.ID;

CREATE OR REPLACE VIEW MART_SEGURANCA_ACESSO AS
SELECT
    U.ID_USUARIO,
    U.NOME_COMPLETO,
    U.USERNAME,
    U.FL_ATIVO,
    R.ID_ROLE,
    R.NOME                                                     AS ROLE,
    P.ID_PERMISSAO,
    P.NOME                                                     AS PERMISSAO,
    M.ID_MENU,
    M.NOME                                                     AS MENU
FROM BRIDGE_USUARIO_ROLE UR
JOIN DIM_USUARIO U ON U.SK_USUARIO = UR.SK_USUARIO
JOIN DIM_ROLE R ON R.SK_ROLE = UR.SK_ROLE
LEFT JOIN BRIDGE_ROLE_PERMISSAO_MENU RPM ON RPM.SK_ROLE = R.SK_ROLE
LEFT JOIN DIM_PERMISSAO P ON P.SK_PERMISSAO = RPM.SK_PERMISSAO
LEFT JOIN DIM_MENU M ON M.SK_MENU = RPM.SK_MENU;

CREATE OR REPLACE VIEW CTL_VERSAO_ORIGEM AS
SELECT VERSION_NUM AS VERSAO_ALEMBIC, DW_INGESTED_AT AS DT_CARGA
FROM STG_ALEMBIC_VERSION;

-- ============================================================================
-- 8. QUALIDADE DE DADOS
-- ============================================================================

CREATE OR REPLACE VIEW DQ_TAREFA_CHAVES_INVALIDAS AS
SELECT *
FROM (
    SELECT
        T.ID                                                       AS ID_TAREFA,
        IFF(T.PROJETO_ID IS NOT NULL AND P.ID IS NULL, TRUE, FALSE) AS ERRO_PROJETO,
        IFF(T.PRODUTO_ID IS NOT NULL AND PR.ID IS NULL, TRUE, FALSE) AS ERRO_PRODUTO,
        IFF(T.RESPONSAVEL_ID IS NOT NULL AND U.ID IS NULL, TRUE, FALSE) AS ERRO_RESPONSAVEL,
        IFF(T.STATUS_ID IS NOT NULL AND S.ID IS NULL, TRUE, FALSE) AS ERRO_STATUS,
        IFF(T.REGRA_ID IS NOT NULL AND R.ID IS NULL, TRUE, FALSE)  AS ERRO_REGRA,
        IFF(T.FATURA_ID IS NOT NULL AND F.ID IS NULL, TRUE, FALSE) AS ERRO_FATURA
    FROM STG_TAREFA T
    LEFT JOIN STG_PROJETO P ON P.ID = T.PROJETO_ID
    LEFT JOIN STG_PRODUTO PR ON PR.ID = T.PRODUTO_ID
    LEFT JOIN STG_AB_USER U ON U.ID = T.RESPONSAVEL_ID
    LEFT JOIN STG_STATUS S ON S.ID = T.STATUS_ID
    LEFT JOIN STG_REGRA R ON R.ID = T.REGRA_ID
    LEFT JOIN STG_FATURA F ON F.ID = T.FATURA_ID
) Q
WHERE ERRO_PROJETO OR ERRO_PRODUTO OR ERRO_RESPONSAVEL
   OR ERRO_STATUS OR ERRO_REGRA OR ERRO_FATURA;

CREATE OR REPLACE VIEW DQ_TAREFA_SEM_EVIDENCIA AS
SELECT
    ID,
    NOME,
    PROJETO_ID,
    RESPONSAVEL_ID,
    STATUS_ID,
    DATA_FIM,
    APROVADA
FROM STG_TAREFA
WHERE DATA_FIM IS NOT NULL
  AND NULLIF(TRIM(EVIDENCIAS), '') IS NULL
  AND NULLIF(TRIM(EVIDENCIA_COMMIT_SHA), '') IS NULL
  AND NULLIF(TRIM(EVIDENCIA_ANEXO), '') IS NULL;

CREATE OR REPLACE VIEW DQ_RESUMO AS
SELECT 'TAREFA_CHAVES_INVALIDAS' AS REGRA, COUNT(*) AS QUANTIDADE FROM DQ_TAREFA_CHAVES_INVALIDAS
UNION ALL
SELECT 'TAREFA_CONCLUIDA_SEM_EVIDENCIA', COUNT(*) FROM DQ_TAREFA_SEM_EVIDENCIA
UNION ALL
SELECT 'TAREFA_SEM_RESPONSAVEL', COUNT(*) FROM STG_TAREFA WHERE RESPONSAVEL_ID IS NULL
UNION ALL
SELECT 'TAREFA_HORAS_NEGATIVAS', COUNT(*) FROM STG_TAREFA WHERE HORAS_EXECUTADAS < 0
UNION ALL
SELECT 'PROJETO_PROGRESSO_INVALIDO', COUNT(*) FROM STG_PROJETO WHERE PROGRESSO < 0 OR PROGRESSO > 100;

-- ============================================================================
-- 9. CONSULTAS DE VALIDAÇÃO
-- ============================================================================
-- SELECT * FROM DQ_RESUMO;
-- SELECT * FROM MART_PROJETO_EXECUTIVO ORDER BY PROGRESSO DESC;
-- SELECT * FROM MART_CONTRATO_FATURAMENTO ORDER BY PERCENTUAL_UST_CONSUMIDA DESC;
-- SELECT * FROM MART_EVIDENCIA_LM LIMIT 100;
-- SELECT COUNT(*) FROM FCT_TAREFA;

-- ============================================================================
-- 10. ORDEM DE EXECUÇÃO NO PIPELINE
-- ============================================================================
-- 1) Executar a criação de CTL_ e RAW_ uma única vez.
-- 2) Carregar RAW_ via Airflow, Fivetran, DMS, COPY ou conector PostgreSQL.
-- 3) Recriar STG_, DIM_, FCT_, BRIDGE_, MART_ e DQ_ após cada carga.
-- 4) Para produção com histórico, substituir CREATE OR REPLACE TABLE das dimensões
--    por MERGE/SCD2 ou modelos incrementais do dbt.
