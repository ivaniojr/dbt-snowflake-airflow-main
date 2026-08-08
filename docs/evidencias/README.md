# Pasta de Evidências de Execução do Projeto MUNKA (IFG)

Esta pasta organiza as capturas de tela e evidências que comprovam o funcionamento de cada módulo do pipeline end-to-end:

## Estrutura de Evidências
```text
docs/evidencias/
├── 01_aws_s3_buckets.png              # Bucket S3 com camadas raw/processed/features/ml
├── 02_cloudformation_deploy.png       # Deploy da stack CloudFormation concluído
├── 03_airflow_dag_master_success.png  # DAG dag_munka_full_pipeline executada com sucesso (verde)
├── 04_snowflake_raw_tables.png        # Tabelas RAW no Snowflake
├── 05_dbt_run_success.png             # Execução dbt run (staging, intermediate, marts)
├── 06_dbt_test_success.png            # Execução dbt test com PASS=... WARN=0 ERROR=0
├── 07_dbt_docs.png                    # Documentação dbt gerada (dbt docs serve)
├── 08_mlflow_experiments.png          # Experimentos e runs gravadas no MLflow
├── 09_ml_evaluation_metrics.png       # Métricas de avaliação e gráficos de resíduos
└── 10_metabase_dashboard.png          # Dashboard interativo no Metabase com filtros
```
