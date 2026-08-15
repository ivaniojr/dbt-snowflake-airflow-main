"""
DAG: passo7_ml_carga_analise_retrospectiva
DAG independente para criação de tabela e carga dos dados da Análise Retrospectiva (analise_retrospectiva.csv)
no Snowflake (schema MUNKA_ML).

Esta DAG é 100% autônoma e independente do pipeline principal.
Pode ser executada sob demanda via UI do Airflow ou CLI.
"""
from __future__ import annotations

import os
from datetime import timedelta
import pendulum
from airflow import DAG

try:
    from airflow.providers.standard.operators.bash import BashOperator
except ImportError:
    from airflow.operators.bash import BashOperator

DAG_ID = "passo7_ml_carga_analise_retrospectiva"
SNOWFLAKE_CONN_ID = "snowflake_munka"
PROJECT_DIR = "/opt/airflow/project"
DBT_PROJECT_DIR = "/opt/airflow/dbt/munka_warehouse"
DBT_PROFILES_DIR = DBT_PROJECT_DIR

DEFAULT_ARGS = {
    "owner": "engenharia_dados",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

DBT_ENV = {
    "DBT_SNOWFLAKE_ACCOUNT": (
        "{{ conn." + SNOWFLAKE_CONN_ID + ".extra_dejson.account }}"
    ),
    "DBT_SNOWFLAKE_USER": "{{ conn." + SNOWFLAKE_CONN_ID + ".login }}",
    "DBT_ENV_SECRET_SNOWFLAKE_PASSWORD": (
        "{{ conn." + SNOWFLAKE_CONN_ID + ".password }}"
    ),
    "DBT_SNOWFLAKE_ROLE": (
        "{{ conn." + SNOWFLAKE_CONN_ID
        + ".extra_dejson.get('role', 'TRAINING_ROLE') }}"
    ),
    "DBT_SNOWFLAKE_WAREHOUSE": (
        "{{ conn." + SNOWFLAKE_CONN_ID
        + ".extra_dejson.get('warehouse', 'DRAGON_WH') }}"
    ),
    "DBT_SNOWFLAKE_DATABASE": (
        "{{ conn." + SNOWFLAKE_CONN_ID
        + ".extra_dejson.get('database', 'DRAGON_DB') }}"
    ),
    "DBT_SNOWFLAKE_SCHEMA": (
        "{{ conn." + SNOWFLAKE_CONN_ID + ".schema or 'MUNKA_RAW' }}"
    ),
    "DBT_SEND_ANONYMOUS_USAGE_STATS": "false",
}

DBT_OPTIONS = (
    f"--project-dir {DBT_PROJECT_DIR} "
    f"--profiles-dir {DBT_PROFILES_DIR} --target prod"
)

with DAG(
    dag_id=DAG_ID,
    description="Carga Independente dos Dados de Análise Retrospectiva para a tabela MUNKA_ML.ML_ANALISE_RETROSPECTIVA no Snowflake via dbt",
    default_args=DEFAULT_ARGS,
    start_date=pendulum.datetime(2026, 1, 1, tz="America/Sao_Paulo"),
    schedule=None,
    catchup=False,
    max_active_runs=1,
    tags=["munka", "dbt", "ml", "retrospective", "snowflake", "independent"],
) as dag:

    # 1. Verificar se o CSV de análise retrospectiva existe
    check_csv = BashOperator(
        task_id="check_csv_analise",
        bash_command=(
            f"set -euo pipefail; "
            f"if [ ! -f {PROJECT_DIR}/src/ml/analise_retrospectiva.csv ] && [ ! -f {DBT_PROJECT_DIR}/seeds/analise_retrospectiva.csv ]; then "
            f"  echo 'Erro: analise_retrospectiva.csv nao encontrado!'; exit 1; "
            f"fi; "
            f"echo 'Arquivo CSV encontrado com sucesso!';"
        ),
    )

    # 2. Sincronizar CSV no diretório de seeds do dbt
    sync_seed = BashOperator(
        task_id="sync_seed_csv",
        bash_command=(
            f"set -euo pipefail; "
            f"if [ -f {PROJECT_DIR}/src/ml/analise_retrospectiva.csv ]; then "
            f"  cp -f {PROJECT_DIR}/src/ml/analise_retrospectiva.csv {DBT_PROJECT_DIR}/seeds/analise_retrospectiva.csv; "
            f"  echo 'Seed analise_retrospectiva.csv sincronizado.'; "
            f"fi;"
        ),
    )

    # 3. Executar dbt seed para criar/carregar a tabela de seed no Snowflake
    dbt_seed = BashOperator(
        task_id="dbt_seed_analise_retrospectiva",
        bash_command=f"set -euo pipefail; dbt seed --select analise_retrospectiva {DBT_OPTIONS}",
        env=DBT_ENV,
        append_env=True,
        cwd=DBT_PROJECT_DIR,
        execution_timeout=timedelta(minutes=5),
    )

    # 4. Executar dbt run para criar e atualizar a tabela mart final no Snowflake
    dbt_run_mart = BashOperator(
        task_id="dbt_run_ml_analise_retrospectiva",
        bash_command=f"set -euo pipefail; dbt run --select ml_analise_retrospectiva {DBT_OPTIONS}",
        env=DBT_ENV,
        append_env=True,
        cwd=DBT_PROJECT_DIR,
        execution_timeout=timedelta(minutes=5),
    )

    # Fluxo de execução
    check_csv >> sync_seed >> dbt_seed >> dbt_run_mart
