# DRAGON_DB.MUNKA — Data Warehouse

Destino: Snowflake. Todas as camadas ficam no schema `DRAGON_DB.MUNKA` e são separadas por prefixo.

## Ordem de execução

1. `00_setup_controle.sql`
2. `01_raw.sql`
3. Carregar as tabelas `RAW_*` a partir do PostgreSQL
4. `02_staging.sql`
5. `03_dimensions.sql`
6. `04_facts.sql`
7. `05_bridges.sql`
8. `06_marts.sql`
9. `07_data_quality.sql`

## Camadas

- `CTL_*`: auditoria de cargas e versão da origem.
- `RAW_*`: réplica das 49 tabelas do DDL, com metadados de ingestão.
- `STG_*`: deduplicação e limpeza. Credenciais não são propagadas.
- `DIM_*`: dimensões de usuários, unidades, projetos, produtos, contratos, regras, status e demais cadastros.
- `FCT_*`: tarefas, evidências, comentários, faturas, projetos, contratos, movimentos contratuais, sprints e anexos.
- `BRIDGE_*`: relacionamentos muitos-para-muitos.
- `MART_*`: visões para tarefas, projetos, faturamento, produtividade, segurança e preparação de textos para LM/LLM.
- `DQ_*`: testes de integridade e qualidade.

## Evidências

`FCT_EVIDENCIA_TAREFA` transforma os campos `evidencias`, `evidencia_commit_sha` e `evidencia_anexo` em registros separados.

`MART_EVIDENCIA_LM` consolida tarefa, descrição, evidências, comentários, cenários, projeto, produto, status, responsável, serviço e complexidade em um texto pronto para feature engineering ou embedding.

## Observações

- O script usa `CREATE OR REPLACE TABLE` na camada dimensional para carga completa.
- Para produção incremental, converta as dimensões para `MERGE`/SCD2 ou modelos incrementais do dbt.
- A execução das transformações exige um warehouse Snowflake ativo.
- Restrinja acesso às tabelas RAW que contêm campos de autenticação.
