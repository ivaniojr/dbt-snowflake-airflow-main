# Execução 01: Migração do SQL Legado para Arquitetura Medallion (dbt + Snowflake)

## 🎯 Implementation Plan (Planejamento)
O objetivo inicial do projeto foi migrar um Data Warehouse legado, construído em arquivos SQL monolíticos e pesados, para uma arquitetura moderna na nuvem governada pelo dbt.
- **Diagnóstico:** As transformações de limpeza (Staging) e a modelagem dimensional (Fatos/Dimensões) estavam manuais nos arquivos `02_staging.sql`, `03_dimensions.sql` e `04_facts.sql`.
- **Proposta:**
  1. Implementar a **Arquitetura Medallion**: Camadas `RAW` (Bruto), `STAGING` (Limpo), `GOLD` (Kimball) e `ML` (Tabelão para Data Science).
  2. Construir scripts Python robóticos (`parse_stg.py` e `parse_marts.py`) para dissecar automaticamente o código legado e convertê-los na estrutura oficial do dbt usando as dependências `{{ ref() }}`.
  3. Adotar Surrogate Keys (SKs) com algoritmos de hash (`HASH(CHAVE)`) no Snowflake, eliminando dependências de IDs instáveis e habilitando SCD (Slowly Changing Dimensions).

---

## ✅ Walkthrough (O que foi entregue)
A execução ocorreu com total sucesso!

1. **Automação da Migração**: O script de automação leu mais de 3.000 linhas de SQL legado e as separou em **quase 90 modelos `.sql` individuais**, estruturados nas subpastas do dbt (`src/dbt/models/`).
2. **Orquestração Criada**: Estabelecemos as DAGs primárias no Apache Airflow:
   - `passo1_munka_dbt_create_raw_tables`: (Inicialização)
   - `passo3_munka_dbt_create_stg`: (Roda o dbt na camada Silver)
   - `passo4_munka_dbt_run_marts`: (Roda o dbt nas camadas Gold e ML)
3. **Novo Paradigma de Chaves**: A tabela principal `fato_tarefa_evidencia` e todas as dimensões passaram a gerar hashes robustos, permitindo rastreabilidade perfeita. 

> [!NOTE]
> Os arquivos SQL monolíticos legados se tornaram "código morto" e foram arquivados para manter a coesão arquitetural da nova fase do projeto.
