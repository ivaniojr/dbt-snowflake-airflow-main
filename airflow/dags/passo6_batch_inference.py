"""
DAG: passo6_batch_inference
Orquestra o processo de inferência em lote utilizando o modelo e scaler salvos no Passo 5.
Lê as novas tarefas do Snowflake (ou Mock) e prevê o tempo de execução esperado.
"""

from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

# Configurações do ambiente Docker mapeado
PYTHON = "python"
PROJECT_DIR = "/opt/airflow/project"
ML_DIR = "/opt/airflow/project/src/ml"

DEFAULT_ARGS = {
    "owner": "engenharia_dados",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="passo6_batch_inference",
    default_args=DEFAULT_ARGS,
    description="Inferência em Lote de Novas Tarefas do Munka usando modelo Sklearn Campeão",
    schedule=None,
    start_date=datetime(2023, 1, 1),
    catchup=False,
    tags=["munka", "mlops", "inference"],
) as dag:

    # 1. Checar se os artefatos do modelo existem antes de rodar
    check_model_artifacts = BashOperator(
        task_id="check_model_artifacts",
        bash_command=(
            f"set -euo pipefail; "
            f"cd {ML_DIR} && "
            f"if [ ! -f sklearn_best_model.joblib ]; then echo 'Erro: sklearn_best_model.joblib nao encontrado!'; exit 1; fi; "
            f"if [ ! -f sklearn_restricted_best_model.joblib ]; then echo 'Erro: sklearn_restricted_best_model.joblib nao encontrado!'; exit 1; fi; "
            f"if [ ! -f scaler.joblib ]; then echo 'Erro: scaler.joblib nao encontrado!'; exit 1; fi; "
            f"echo 'Artefatos encontrados com sucesso!';"
        ),
        doc_md="""
        ## Validação de Artefatos
        Verifica se a DAG do Passo 5 gerou os arquivos físicos `.joblib` necessários para a inferência:
        - O modelo treinado.
        - O Scaler (StandardScaler) usado para normalização.
        """,
    )

    # 2. Avaliação Comparativa de Modelos
    evaluate_models = BashOperator(
        task_id="evaluate_models",
        bash_command=(
            f"set -euo pipefail; "
            f"cd {PROJECT_DIR} && "
            f"{PYTHON} src/ml/evaluate_batch.py"
        ),
        doc_md="""
        ## Avaliação Comparativa
        Carrega tarefas com `HORAS_EXECUTADAS` conhecidas e avalia ambos os modelos (NumPy e Sklearn).
        Calcula MAE, MSE e a Taxa de Acertos (considerando tolerância de 10% de erro).
        Salva o resultado em `evaluation/comparativo_modelos.csv`.
        """,
    )

    # 3. Rodar o script de inferência
    run_inference = BashOperator(
        task_id="run_inference",
        bash_command=(
            f"set -euo pipefail; "
            f"cd {PROJECT_DIR} && "
            f"{PYTHON} src/ml/batch_inference.py"
        ),
        doc_md="""
        ## Inferência de Horas
        Conecta ao Snowflake, captura tarefas sem `HORAS_EXECUTADAS`, aplica o `scaler` nos dados brutos 
        e pede previsões para o modelo campeão. 
        Salva o output no `novas_previsoes.csv`.
        """,
    )

    # Dependências
    check_model_artifacts >> evaluate_models >> run_inference
