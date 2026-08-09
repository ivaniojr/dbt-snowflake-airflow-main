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

-- Contexto de Banco de Dados e Schema (gerenciado via .env / conexão)
-- Opcionalmente pode ser ativado na sessão do Snowflake
-- USE DATABASE IDENTIFIER($DBT_SNOWFLAKE_DATABASE);
-- USE SCHEMA IDENTIFIER($DBT_SNOWFLAKE_SCHEMA);

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
