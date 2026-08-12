"""
DAG: passo5_ml_hpo_e_retreinamento
Orquestra o pipeline completo de otimizacao de hiperparametros (HPO) +
retreinamento dos modelos MLP com os melhores parametros encontrados.

Fluxo paralelo:
  [hpo_sklearn] --> [retreinar_sklearn] --+
                                          +--> [registrar_mlflow]
  [hpo_numpy]   --> [retreinar_numpy]   --+

Saidas:
  - src/ml/sklearn_best_params.json   (melhores hiperparametros Sklearn)
  - src/ml/numpy_best_params.json     (melhores hiperparametros NumPy)
  - Experimento MLflow: Auditoria_MLP_Best_Params
"""
from __future__ import annotations

from datetime import timedelta
import pendulum

from airflow import DAG
from airflow.operators.bash import BashOperator

# ──────────────────────────────────────────────
# Configuracoes
# ──────────────────────────────────────────────
DAG_ID = "passo5_ml_hpo_e_retreinamento"

# Path absoluto do Python do venv do projeto
# Ajuste conforme o ambiente de execucao (local vs container)
PYTHON = "python"
PROJECT_DIR = "/opt/airflow/project"
ML_DIR = "/opt/airflow/project/src/ml"

DEFAULT_ARGS = {
    "owner": "engenharia_dados",
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "execution_timeout": timedelta(hours=4),
}

# ──────────────────────────────────────────────
# DAG
# ──────────────────────────────────────────────
with DAG(
    dag_id=DAG_ID,
    description=(
        "HPO com Optuna para Sklearn e NumPy MLP (sequencial), "
        "seguido de retreinamento com os melhores hiperparametros. "
        "Gera sklearn_best_params.json e numpy_best_params.json."
    ),
    default_args=DEFAULT_ARGS,
    start_date=pendulum.datetime(2026, 1, 1, tz="America/Sao_Paulo"),
    schedule=None,
    catchup=False,
    max_active_runs=1,
    tags=["ml", "hpo", "optuna", "mlflow", "munka"],
) as dag:

    # ── HPO Sklearn (15 trials | 300 epocas) ──────────────────────
    hpo_sklearn = BashOperator(
        task_id="hpo_sklearn",
        bash_command=(
            f"set -euo pipefail; "
            f"cd {PROJECT_DIR} && "
            f"{PYTHON} src/ml/hpo.py --model sklearn --output-dir {ML_DIR}"
        ),
        doc_md="""
        ## HPO Sklearn
        Roda o Optuna com 15 trials e 300 epocas para o MLPRegressor do Scikit-Learn.
        Busca: `learning_rate`, `hidden_sizes` (1-3 camadas), `alpha`.
        **Saida:** `sklearn_best_params.json`
        """,
    )

    # ── HPO NumPy (10 trials | 300 epocas) ────────────────────────
    hpo_numpy = BashOperator(
        task_id="hpo_numpy",
        bash_command=(
            f"set -euo pipefail; "
            f"cd {PROJECT_DIR} && "
            f"{PYTHON} src/ml/hpo.py --model numpy --output-dir {ML_DIR}"
        ),
        doc_md="""
        ## HPO NumPy
        Roda o Optuna com 10 trials e 300 epocas para o NumPyMLPRegressor.
        Busca: `learning_rate`, `n_units_l1`, `n_units_l2`.
        **Saida:** `numpy_best_params.json`
        """,
    )

    # ── Retreinamento Sklearn com melhores params ─────────────────
    retreinar_sklearn = BashOperator(
        task_id="retreinar_sklearn",
        bash_command=(
            f"set -euo pipefail; "
            f"cd {PROJECT_DIR} && "
            f"{PYTHON} src/ml/train_best.py --model sklearn --config-dir {ML_DIR}"
        ),
        doc_md="""
        ## Retreinamento Sklearn
        Le `sklearn_best_params.json` e retreina o modelo com 5-Fold CV.
        Loga metricas e artefatos no MLflow (experimento: Auditoria_MLP_Best_Params).
        **Artefatos:** `sklearn_best_loss_curve.png`, `sklearn_best_residuals.png`
        """,
    )

    # ── Retreinamento NumPy com melhores params ───────────────────
    retreinar_numpy = BashOperator(
        task_id="retreinar_numpy",
        bash_command=(
            f"set -euo pipefail; "
            f"cd {PROJECT_DIR} && "
            f"{PYTHON} src/ml/train_best.py --model numpy --config-dir {ML_DIR}"
        ),
        doc_md="""
        ## Retreinamento NumPy
        Le `numpy_best_params.json` e retreina o modelo com 5-Fold CV.
        Loga metricas e artefatos no MLflow (experimento: Auditoria_MLP_Best_Params).
        **Artefatos:** `numpy_best_loss_curve.png`, `numpy_best_residuals.png`
        """,
    )

    # ── Validacao final no MLflow ─────────────────────────────────
    registrar_mlflow = BashOperator(
        task_id="registrar_mlflow",
        bash_command=(
            f"set -euo pipefail; "
            f"cd {PROJECT_DIR} && "
            f"{PYTHON} -c \""
            f"import os, mlflow; "
            f"mlflow.set_tracking_uri(os.getenv('MLFLOW_TRACKING_URI', 'sqlite:////tmp/mlflow.db')); "
            f"client = mlflow.tracking.MlflowClient(); "
            f"exp = client.get_experiment_by_name('Auditoria_MLP_Best_Params'); "
            f"runs = client.search_runs(exp.experiment_id, order_by=['start_time DESC'], max_results=2); "
            f"print(f'Runs registradas: {{len(runs)}}'); "
            f"[print(f'  - {{r.info.run_name}}: MSE={{r.data.metrics.get(\\\"kfold_mse\\\", \\\"n/a\\\"):.4f}}') for r in runs]; "
            f"assert len(runs) >= 2, 'ERRO: menos de 2 runs registradas no MLflow!'; "
            f"print('MLflow OK — ambos os modelos registrados com sucesso.'); "
            f"\""
        ),
        doc_md="""
        ## Validacao MLflow
        Verifica que ambos os retreinamentos (Sklearn + NumPy) foram registrados
        corretamente no experimento `Auditoria_MLP_Best_Params` do MLflow.
        Falha a DAG se menos de 2 runs forem encontradas.
        """,
    )

    # ── Dependencias (fluxo serializado) ─────────────────────────────
    #
    # Para evitar locks no SQLite do MLflow ou gargalo de CPU, o fluxo
    # deve ser estritamente sequencial.
    #
    hpo_sklearn >> retreinar_sklearn >> hpo_numpy >> retreinar_numpy >> registrar_mlflow
