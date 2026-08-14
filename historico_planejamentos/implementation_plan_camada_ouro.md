# Construção da Camada Gold e Features de ML

Seguindo a arquitetura Medallion (Ouro) e a discussão sobre a extração de features para Machine Learning (ML), proponho a seguinte estrutura para processar o campo `evidencias` e construir a tabela final que alimentará os modelos preditivos.

## Objetivos
1. **Desmembrar** a riqueza do campo `evidencias` em métricas numéricas e categóricas (features).
2. **Consolidar** a camada Ouro (`Gold` / `Marts`) com tabelas prontas para consumo de ferramentas de BI e bibliotecas de ML.
3. **Automatizar** tudo via Airflow e dbt.

## User Review Required
> [!IMPORTANT]
> Vou criar novas pastas no dbt (`intermediate` e `marts`) e novos esquemas no Snowflake (`MUNKA_INT`, `MUNKA_GOLD`, `MUNKA_ML`). 
> O algoritmo de "Quality Score" para as evidências será uma soma ponderada simples baseada em Expressões Regulares (RegEx). Confirme se a lógica abaixo atende às suas expectativas antes de eu codificar.

## Proposed Changes

### 1. Configurações no `dbt_project.yml`
Vamos configurar os novos schemas para manter o Data Warehouse perfeitamente organizado:
- `intermediate`: schema `MUNKA_INT`
- `marts/gold`: schema `MUNKA_GOLD`
- `marts/ml`: schema `MUNKA_ML`

### 2. Camada Intermediate: O Parser de Evidências
Esta camada fará o processamento pesado de HTML e texto usando `REGEXP_COUNT` e `REGEXP_LIKE` do Snowflake.

#### [NEW] src/dbt/models/intermediate/int_tarefa_evidencias_features.sql
Este modelo lerá a `stg_tarefa` e extrairá as seguintes features:
- `QTD_IMAGENS`: Contagem de tags `<img`
- `QTD_LINKS`: Contagem de tags `<a href`
- `TEM_CODIGO`: Verifica presença de `<pre>` ou `<code>`
- `TEM_SQL`: Verifica menções a comandos SQL (SELECT, UPDATE, etc.)
- `TEM_COMMIT`: Verifica hashes SHA ou referências a Git
- `TAMANHO_TEXTO`: Tamanho em caracteres da string
- `SCORE_QUALIDADE`: Uma métrica (ex: Imagens * 2 + Código * 3 + Commits * 5)

### 3. Camada Gold (Marts)
A camada oficial de negócio, unindo as features com o contexto da tarefa.

#### [NEW] src/dbt/models/marts/gold/fato_tarefa_evidencia.sql
Fato consolidada ligando a tarefa aos seus scores de evidência.

#### [NEW] src/dbt/models/marts/ml/ml_tarefa_features.sql
A tabela final **"Wide Table"** para os cientistas de dados. Faremos um grande `JOIN` desnormalizando:
- `stg_tarefa` (Target: horas_executadas, total_ust)
- `int_tarefa_evidencias_features` (Score de qualidade do desenvolvedor)
- `stg_projeto` (Contexto do projeto)
- `stg_sprint` (Prazo e correria)
- `stg_regra` & `stg_complexidade` (Estimativa oficial)

### 4. Orquestração (Airflow)
#### [NEW] airflow/dags/munka_dbt_run_marts.py
Nova DAG para rodar exclusivamente os modelos `intermediate` e `marts`.

## Verification Plan
1. Rodarei `dbt compile` para validar os SQLs gerados (especialmente os blocos de RegEx do Snowflake).
2. Verificarei se o Airflow consegue enxergar a nova DAG.
