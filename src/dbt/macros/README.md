# Airflow + dbt + Snowflake — RAW Munka

Este pacote cria e valida 49 tabelas RAW em `DRAGON_DB.MUNKA` usando:

- Airflow para orquestração;
- dbt Core para executar os macros de DDL;
- Snowflake como warehouse.

## Por que foi usado `dbt run-operation`

As tabelas RAW recebem dados de ingestão. Elas não devem ser modelos dbt materializados como `table`, pois um `dbt run` pode substituir a relação. O macro executa `CREATE TABLE IF NOT EXISTS`, portanto é idempotente e preserva os dados existentes.

## Estrutura

```text
dags/
└── munka_dbt_create_raw_tables.py

dbt/munka_warehouse/
├── dbt_project.yml
├── profiles.yml
├── macros/
│   ├── create_raw_tables.sql
│   └── validate_raw_tables.sql
├── models/raw/
│   └── sources.yml
└── analyses/
    └── raw_ddl_reference.sql
```

## 1. Copiar para o projeto Airflow

Considerando o diretório do Airflow como raiz:

```text
seu-airflow/
├── dags/
│   └── munka_dbt_create_raw_tables.py
└── dbt/
    └── munka_warehouse/
```

No `docker-compose.yaml`, monte também a pasta dbt em todos os serviços Airflow que executam tarefas, principalmente scheduler e worker:

```yaml
volumes:
  - ./dags:/opt/airflow/dags
  - ./dbt:/opt/airflow/dbt
```

## 2. Instalar dbt-snowflake na imagem do Airflow

Recomendado: use o `Dockerfile.dbt` e mantenha nele a mesma imagem/versão do seu Airflow.

Exemplo no `docker-compose.yaml`:

```yaml
x-airflow-common:
  &airflow-common
  build:
    context: .
    dockerfile: Dockerfile.dbt
  image: airflow-dbt-snowflake:local
```

Depois reconstrua:

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

Para teste rápido, também é possível acrescentar `dbt-snowflake==1.11.6` em `_PIP_ADDITIONAL_REQUIREMENTS`, mas isso reinstala o pacote a cada inicialização.

## 3. Conexão do Airflow

Use a conexão já prevista pelo DAG:

```text
Connection Id: snowflake_munka
Connection Type: Snowflake
Login: USUARIO_SNOWFLAKE
Password: SENHA
Schema: MUNKA
```

Extra:

```json
{
  "account": "identificador_da_conta",
  "database": "DRAGON_DB",
  "warehouse": "COMPUTE_WH",
  "role": "SYSADMIN"
}
```

A role precisa ter `USAGE` no database e warehouse e permissão para criar objetos no schema. Caso o schema ainda não exista, também precisa de permissão para criá-lo no database.

## 4. Testar dentro do container

```bash
docker compose exec airflow-scheduler dbt --version

docker compose exec airflow-scheduler dbt \
  --project-dir /opt/airflow/dbt/munka_warehouse \
  --profiles-dir /opt/airflow/dbt/munka_warehouse \
  debug
```

O segundo comando precisa das variáveis de ambiente; no DAG elas são obtidas automaticamente da conexão `snowflake_munka`.

## 5. Executar

Na interface do Airflow, habilite e execute:

```text
munka_dbt_create_raw_tables
```

Fluxo:

```text
dbt_debug_snowflake
        ↓
dbt_create_raw_tables
        ↓
dbt_validate_raw_tables
```

## Comandos dbt equivalentes

Com as variáveis de conexão definidas:

```bash
dbt --project-dir dbt/munka_warehouse \
    --profiles-dir dbt/munka_warehouse \
    run-operation create_raw_tables

dbt --project-dir dbt/munka_warehouse \
    --profiles-dir dbt/munka_warehouse \
    run-operation validate_raw_tables
```

## Uso posterior nas transformações

As 49 tabelas estão declaradas como sources. Exemplo de um futuro modelo staging:

```sql
select *
from {{ source('munka_raw', 'raw_tarefa') }}
```

Depois, as camadas STG, CORE e MART podem ser executadas pelo Airflow com `dbt build`.
