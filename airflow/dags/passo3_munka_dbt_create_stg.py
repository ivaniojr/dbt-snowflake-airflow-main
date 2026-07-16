from __future__ import annotations

from datetime import timedelta

import pendulum
from airflow import DAG

try:
    # Airflow com apache-airflow-providers-standard.
    from airflow.providers.standard.operators.bash import BashOperator
except ImportError:
    # Compatibilidade com instalações Airflow 2.x mais antigas.
    from airflow.operators.bash import BashOperator

DAG_ID = "munka_dbt_create_stg"
SNOWFLAKE_CONN_ID = "snowflake_munka"
DBT_PROJECT_DIR = "/opt/airflow/dbt/munka_warehouse"
DBT_PROFILES_DIR = DBT_PROJECT_DIR

DEFAULT_ARGS = {
    "owner": "engenharia_dados",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=2),
}

# A senha usa o prefixo DBT_ENV_SECRET_ para ser tratada como segredo pelo dbt.
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
        + ".extra_dejson.get('role', 'SYSADMIN') }}"
    ),
    "DBT_SNOWFLAKE_WAREHOUSE": (
        "{{ conn." + SNOWFLAKE_CONN_ID
        + ".extra_dejson.get('warehouse', 'COMPUTE_WH') }}"
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
    description=(
        "Executa dbt Core para rodar a camada de Staging (STG) no Snowflake."
    ),
    default_args=DEFAULT_ARGS,
    start_date=pendulum.datetime(2026, 1, 1, tz="America/Sao_Paulo"),
    schedule=None,
    catchup=False,
    max_active_runs=1,
    tags=["snowflake", "dbt", "munka", "stg", "run"],
) as dag:
    dbt_debug = BashOperator(
        task_id="dbt_debug_snowflake",
        bash_command=f"set -euo pipefail; dbt debug {DBT_OPTIONS}",
        env=DBT_ENV,
        append_env=True,
        cwd=DBT_PROJECT_DIR,
        execution_timeout=timedelta(minutes=5),
    )

    run_stg_models = BashOperator(
        task_id="dbt_run_stg",
        bash_command=(
            f"set -euo pipefail; dbt "
            f"run --select staging {DBT_OPTIONS}"
        ),
        env=DBT_ENV,
        append_env=True,
        cwd=DBT_PROJECT_DIR,
        execution_timeout=timedelta(minutes=30),
    )

    dbt_debug >> run_stg_models
