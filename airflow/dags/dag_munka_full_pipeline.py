"""
DAG Master: dag_munka_full_pipeline
Orquestra o pipeline completo ponta a ponta do projeto MUNKA (IFG):
  1. Ingestao e Criacao de Tabelas RAW (dbt macro DDL)
  2. Carga S3 para Snowflake RAW (COPY INTO com Storage Integration)
  3. Transfomacao Staging (dbt run --select staging)
  4. Transformacao Marts (dbt run --select marts)
  5. Testes de Qualidade de Dados (dbt test)
  6. Treinamento de ML (HPO + Sklearn & NumPy MLP)
  7. Inferencia em Lote (Passo 6)
  8. Carga dos Resultados da Análise Retrospectiva no Snowflake (dbt seed + mart)
"""
from __future__ import annotations

from datetime import timedelta
import pendulum
from airflow import DAG
from airflow.operators.trigger_dagrun import TriggerDagRunOperator

DAG_ID = "dag_munka_full_pipeline"

DEFAULT_ARGS = {
    "owner": "engenharia_dados",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

with DAG(
    dag_id=DAG_ID,
    description="Pipeline Master Completo do Projeto MUNKA: RAW -> S3 -> Snowflake -> dbt -> dbt test -> ML -> Metabase",
    default_args=DEFAULT_ARGS,
    start_date=pendulum.datetime(2026, 1, 1, tz="America/Sao_Paulo"),
    schedule=None,
    catchup=False,
    max_active_runs=1,
    tags=["munka", "master", "pipeline", "full", "end-to-end"],
) as dag:

    trigger_passo1 = TriggerDagRunOperator(
        task_id="passo1_criar_tabelas_raw",
        trigger_dag_id="passo1_munka_dbt_create_raw_tables",
        reset_dag_run=True,
        wait_for_completion=True,
        poke_interval=10,
    )

    trigger_passo2 = TriggerDagRunOperator(
        task_id="passo2_carga_s3_snowflake",
        trigger_dag_id="passo2_s3_to_snowflake_munka_raw",
        reset_dag_run=True,
        wait_for_completion=True,
        poke_interval=10,
    )

    trigger_passo3 = TriggerDagRunOperator(
        task_id="passo3_dbt_staging",
        trigger_dag_id="passo3_munka_dbt_create_stg",
        reset_dag_run=True,
        wait_for_completion=True,
        poke_interval=10,
    )

    trigger_passo4 = TriggerDagRunOperator(
        task_id="passo4_dbt_marts_e_testes",
        trigger_dag_id="passo4_munka_dbt_run_marts",
        reset_dag_run=True,
        wait_for_completion=True,
        poke_interval=10,
    )

    trigger_passo5 = TriggerDagRunOperator(
        task_id="passo5_ml_hpo_e_treinamento",
        trigger_dag_id="passo5_ml_hpo_e_retreinamento",
        reset_dag_run=True,
        wait_for_completion=True,
        poke_interval=10,
    )

    trigger_passo6 = TriggerDagRunOperator(
        task_id="passo6_batch_inference",
        trigger_dag_id="passo6_batch_inference",
        reset_dag_run=True,
        wait_for_completion=True,
        poke_interval=10,
    )

    trigger_passo7 = TriggerDagRunOperator(
        task_id="passo7_carga_analise_retrospectiva",
        trigger_dag_id="dag_carga_analise_retrospectiva",
        reset_dag_run=True,
        wait_for_completion=True,
        poke_interval=10,
    )

    trigger_passo1 >> trigger_passo2 >> trigger_passo3 >> trigger_passo4 >> trigger_passo5 >> trigger_passo6 >> trigger_passo7
