"""
batch_inference.py
Análise retrospectiva em lote (Passo 6).

Este script carrega os modelos e o scaler salvos no Passo 5,
obtém tarefas já executadas (HORAS_EXECUTADAS IS NOT NULL),
gera uma estimativa retrospectiva de esforço e compara
HORAS_ESTIMADAS x HORAS_EXECUTADAS.

Observação metodológica:
o modelo atual possui escopo retrospectivo e utiliza evidências
produzidas durante ou após a execução da tarefa. Portanto, este
script NÃO deve ser interpretado como previsão antecipada de
tarefas ainda não executadas.

O nome da função run_batch_inference foi mantido para preservar
compatibilidade com a DAG já existente.
"""

import json
import os
import sys
import joblib
import mlflow
import pandas as pd
import numpy as np

from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

# Adicionar o diretório atual ao path para poder importar mlp_numpy e config
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from mlp_numpy import NumPyMLPRegressor

try:
    from config import (
        BATCH_INFERENCE_SAMPLE_SIZE,
        BATCH_INFERENCE_MOCK_SIZE,
        RANDOM_STATE
    )
except ImportError:
    from config import (
        BATCH_INFERENCE_SAMPLE_SIZE,
        BATCH_INFERENCE_MOCK_SIZE,
        RANDOM_STATE
    )


# ============================================================
# Contrato metodológico do modelo
# ============================================================

MODEL_SCOPE = "retrospective_analysis"
ANALYSIS_MOMENT = "post_execution"
USES_EXECUTION_EVIDENCE = True
FEATURE_SET_NAME = "retrospective_features_v1"
TARGET_NAME = "HORAS_EXECUTADAS"

# Fallback caso feature_contract.json não esteja disponível.
# A ordem deve ser exatamente a mesma utilizada no treinamento.
RETROSPECTIVE_FEATURES = [
    "FATOR_AJUSTE",
    "HET_MAX",
    "QTD_IMAGENS",
    "QTD_LINKS",
    "TEM_CODIGO",
    "TEM_SQL",
    "TEM_COMMIT",
    "TEM_ANEXO",
    "FL_ENVOLVE_FRONTEND",
    "FL_ENVOLVE_BACKEND",
    "FL_ENVOLVE_DADOS",
    "FL_IS_BUGFIX",
    "QTD_BLOCOS_CODIGO",
    "FL_TEM_PULL_REQUEST",
    "TAMANHO_TEXTO",
]


# ──────────────────────────────────────────────
# 1. Contrato de Features
# ──────────────────────────────────────────────

def load_feature_contract(output_dir):
    """
    Carrega feature_contract.json gerado no treinamento.

    Se o arquivo não existir, utiliza RETROSPECTIVE_FEATURES como fallback.
    """
    contract_path = os.path.join(output_dir, "feature_contract.json")

    if os.path.exists(contract_path):
        with open(contract_path, "r", encoding="utf-8") as f:
            contract = json.load(f)

        features = contract.get("features", [])
        if not features:
            raise ValueError(
                "feature_contract.json foi encontrado, mas não contém a lista 'features'."
            )

        print(f" Contrato de features carregado: {contract_path}")
        print(f" Escopo do modelo: {contract.get('model_scope', 'não informado')}")
        print(f" Conjunto de features: {contract.get('feature_set_name', 'não informado')}")
        return features

    print(" [Aviso] feature_contract.json não encontrado.")
    print(" [Aviso] Utilizando lista RETROSPECTIVE_FEATURES definida no código.")
    return RETROSPECTIVE_FEATURES


# ──────────────────────────────────────────────
# 2. Obtenção de Dados Retrospectivos
# ──────────────────────────────────────────────

def get_retrospective_tasks():
    """
    Tenta ler tarefas já executadas no Snowflake
    (HORAS_EXECUTADAS IS NOT NULL).

    Se não conseguir conectar, gera 100 tarefas mock apenas para
    demonstração técnica do fluxo. Dados mock NÃO devem ser usados
    como evidência de desempenho do modelo no relatório.
    """
    try:
        from cryptography.hazmat.backends import default_backend
        from cryptography.hazmat.primitives import serialization
        import snowflake.connector

        # Fonte Única de Verdade: carregar variáveis de ambiente (.env)
        try:
            from dotenv import load_dotenv
            dotenv_path = os.path.abspath(
                os.path.join(os.path.dirname(__file__), "..", "..", ".env")
            )
            if os.path.exists(dotenv_path):
                load_dotenv(dotenv_path)
        except ImportError:
            pass

        user = os.getenv("DBT_SNOWFLAKE_USER", "DRAGON")
        account = os.getenv("DBT_SNOWFLAKE_ACCOUNT", "sfedu02-gfb24387")
        role = os.getenv("DBT_SNOWFLAKE_ROLE", "TRAINING_ROLE")
        warehouse = os.getenv("DBT_SNOWFLAKE_WAREHOUSE", "DRAGON_WH")
        database = os.getenv("DBT_SNOWFLAKE_DATABASE", "DRAGON_DB")
        schema = os.getenv("DBT_SNOWFLAKE_ML_SCHEMA", "MUNKA_ML")

        key_path = os.getenv(
            "DBT_SNOWFLAKE_PRIVATE_KEY_PATH",
            os.path.abspath(
                os.path.join(
                    os.path.dirname(__file__),
                    "..",
                    "dbt",
                    "rsa_key.p8"
                )
            )
        )

        if not os.path.isabs(key_path) and not os.path.exists(key_path):
            key_path = os.path.abspath(
                os.path.join(
                    os.path.dirname(__file__),
                    "..",
                    "dbt",
                    os.path.basename(key_path)
                )
            )

        with open(key_path, "rb") as key:
            p_key = serialization.load_pem_private_key(
                key.read(),
                password=None,
                backend=default_backend()
            )

        pkb = p_key.private_bytes(
            encoding=serialization.Encoding.DER,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption()
        )

        ctx = snowflake.connector.connect(
            user=user,
            account=account,
            private_key=pkb,
            role=role,
            warehouse=warehouse,
            database=database,
            schema=schema
        )

        limit_clause = f"LIMIT {BATCH_INFERENCE_SAMPLE_SIZE}" if BATCH_INFERENCE_SAMPLE_SIZE is not None else ""
        query = f"""
            SELECT *
            FROM {database}.{schema}.ML_TAREFA_FEATURES
            WHERE HORAS_EXECUTADAS IS NOT NULL
            {limit_clause}
        """

        df = pd.read_sql(query, ctx)
        ctx.close()

        if df.empty:
            print(
                " [Aviso] Conexão com Snowflake realizada, "
                "mas nenhuma tarefa executada foi encontrada."
            )
            print(
                f" [Aviso] Para demonstração da DAG, "
                f"serão geradas {BATCH_INFERENCE_MOCK_SIZE} tarefas simuladas."
            )
            return _generate_mock_tasks()

        df["FONTE_DADOS"] = "SNOWFLAKE"
        print(f" Tarefas executadas carregadas do Snowflake ({len(df)} tarefas)!")
        return df

    except Exception as e:
        print(f" [Aviso] Falha ao conectar no Snowflake: {e}")
        print(
            f" [Aviso] Gerando {BATCH_INFERENCE_MOCK_SIZE} tarefas simuladas apenas "
            "para demonstração técnica do fluxo."
        )
        return _generate_mock_tasks()


def _generate_mock_tasks(n_samples=None):
    """
    Gera dados fictícios e reproduzíveis para teste técnico do pipeline.

    Esses dados não devem ser utilizados para reportar desempenho científico.
    """
    if n_samples is None:
        n_samples = BATCH_INFERENCE_MOCK_SIZE
    rng = np.random.default_rng(RANDOM_STATE)

    df = pd.DataFrame({
        "TAREFA_ID": [f"TASK-{i}" for i in range(1000, 1000 + n_samples)],
        "FATOR_AJUSTE": rng.uniform(0.5, 2.0, n_samples),
        "HET_MAX": rng.integers(10, 100, n_samples),
        "QTD_IMAGENS": rng.poisson(2, n_samples),
        "QTD_LINKS": rng.poisson(1, n_samples),
        "TEM_CODIGO": rng.integers(0, 2, n_samples),
        "TEM_SQL": rng.integers(0, 2, n_samples),
        "TEM_COMMIT": rng.integers(0, 2, n_samples),
        "TEM_ANEXO": rng.integers(0, 2, n_samples),
        "FL_ENVOLVE_FRONTEND": rng.integers(0, 2, n_samples),
        "FL_ENVOLVE_BACKEND": rng.integers(0, 2, n_samples),
        "FL_ENVOLVE_DADOS": rng.integers(0, 2, n_samples),
        "FL_IS_BUGFIX": rng.integers(0, 2, n_samples),
        "QTD_BLOCOS_CODIGO": rng.poisson(1, n_samples),
        "FL_TEM_PULL_REQUEST": rng.integers(0, 2, n_samples),
        "TAMANHO_TEXTO": rng.integers(10, 2000, n_samples),
        # Target retrospectivo fictício apenas para validação do fluxo
        "HORAS_EXECUTADAS": rng.uniform(1.0, 80.0, n_samples),
        "FONTE_DADOS": "MOCK"
    })

    return df


# ──────────────────────────────────────────────
# 3. Validação do Dataset
# ──────────────────────────────────────────────

def validate_dataset(df, feature_names):
    """
    Garante que o dataset possui target e exatamente as features
    necessárias ao modelo.
    """
    required_columns = set(feature_names + [TARGET_NAME])
    missing = sorted(required_columns - set(df.columns))

    if missing:
        raise ValueError(
            "O dataset não contém todas as colunas necessárias. "
            f"Ausentes: {missing}"
        )

    if df[TARGET_NAME].isna().any():
        raise ValueError(
            f"Foram encontradas linhas sem {TARGET_NAME}. "
            "A análise retrospectiva exige tarefas já executadas."
        )


# ──────────────────────────────────────────────
# 4. Métricas
# ──────────────────────────────────────────────

def calculate_metrics(y_true, y_pred, prefix):
    mse = mean_squared_error(y_true, y_pred)

    return {
        f"{prefix}_mae": mean_absolute_error(y_true, y_pred),
        f"{prefix}_mse": mse,
        f"{prefix}_rmse": np.sqrt(mse),
        f"{prefix}_r2": r2_score(y_true, y_pred)
    }


# ──────────────────────────────────────────────
# 5. Pipeline de Análise Retrospectiva
# ──────────────────────────────────────────────

def run_batch_inference():
    """
    Executa análise retrospectiva em lote.

    O nome foi mantido por compatibilidade com a DAG existente.
    """
    print(f"\n{'=' * 68}")
    print(" ANÁLISE RETROSPECTIVA EM LOTE - PASSO 6")
    print(f"{'=' * 68}")
    print(f" Escopo: {MODEL_SCOPE}")
    print(f" Momento de análise: {ANALYSIS_MOMENT}")
    print(f" Usa evidências de execução: {USES_EXECUTION_EVIDENCE}")

    output_dir = os.path.dirname(os.path.abspath(__file__))

    # Artefatos salvos no Passo 5
    sklearn_model_path = os.path.join(output_dir, "sklearn_best_model.joblib")
    numpy_model_path = os.path.join(output_dir, "numpy_best_model.npz")
    scaler_path = os.path.join(output_dir, "scaler.joblib")

    required_artifacts = [
        sklearn_model_path,
        numpy_model_path,
        scaler_path
    ]

    missing_artifacts = [
        path for path in required_artifacts if not os.path.exists(path)
    ]

    if missing_artifacts:
        formatted = "\n".join(f"- {path}" for path in missing_artifacts)
        raise FileNotFoundError(
            "Artefatos não encontrados!\n"
            "Certifique-se de que o Passo 5 rodou com sucesso.\n"
            f"Ausentes:\n{formatted}"
        )

    feature_names = load_feature_contract(output_dir)

    print(f" Carregando scaler: {scaler_path}")
    scaler = joblib.load(scaler_path)

    print(f" Carregando modelo Scikit-Learn: {sklearn_model_path}")
    sklearn_model = joblib.load(sklearn_model_path)

    print(f" Carregando modelo NumPy: {numpy_model_path}")
    numpy_model = NumPyMLPRegressor.from_weights(numpy_model_path)

    df = get_retrospective_tasks()

    if df.empty:
        print(" Nenhuma tarefa disponível para análise retrospectiva. Encerrando.")
        return

    validate_dataset(df, feature_names)

    print(f" Total de tarefas para análise retrospectiva: {len(df)}")

    # IDs
    if "TAREFA_ID" in df.columns:
        task_ids = df["TAREFA_ID"].astype(str).values
    else:
        task_ids = [f"UNKNOWN-{i}" for i in range(len(df))]

    # Fonte dos dados
    if "FONTE_DADOS" in df.columns:
        data_source = df["FONTE_DADOS"].astype(str).values
    else:
        data_source = np.repeat("DESCONHECIDA", len(df))

    # Target real
    y_true = pd.to_numeric(df[TARGET_NAME], errors="coerce").to_numpy()

    if np.isnan(y_true).any():
        raise ValueError(
            f"A coluna {TARGET_NAME} contém valores não numéricos ou nulos."
        )

    # Selecionar EXATAMENTE as mesmas features e na mesma ordem do treinamento.
    X_raw = df[feature_names].copy()

    # Mantém a mesma regra de imputação utilizada no treinamento.
    X_raw = X_raw.apply(pd.to_numeric, errors="coerce").fillna(0)

    # 1. Normalizar usando o MESMO scaler do treinamento
    X_scaled = scaler.transform(X_raw.values)

    # 2. Estimativa retrospectiva - Scikit-Learn
    print(" Processando estimativa retrospectiva com Scikit-Learn...")
    preds_sklearn = np.asarray(
        sklearn_model.predict(X_scaled)
    ).reshape(-1)

    # 3. Estimativa retrospectiva - NumPy
    print(" Processando estimativa retrospectiva com NumPy...")
    preds_numpy = np.asarray(
        numpy_model.predict(X_scaled)
    ).reshape(-1)

    # Evita valores negativos, preservando a mesma regra do pipeline anterior.
    preds_sklearn = np.maximum(0.5, preds_sklearn)
    preds_numpy = np.maximum(0.5, preds_numpy)

    # Métricas agregadas
    sklearn_metrics = calculate_metrics(
        y_true,
        preds_sklearn,
        "sklearn"
    )
    numpy_metrics = calculate_metrics(
        y_true,
        preds_numpy,
        "numpy"
    )

    # Resultado por tarefa
    df_results = pd.DataFrame({
        "TAREFA_ID": task_ids,
        "FONTE_DADOS": data_source,
        "HORAS_EXECUTADAS": np.round(y_true, 2),
        "HORAS_ESTIMADAS_SKLEARN": np.round(preds_sklearn, 2),
        "HORAS_ESTIMADAS_NUMPY": np.round(preds_numpy, 2)
    })

    # Erros - Scikit-Learn
    df_results["ERRO_SKLEARN"] = (
        df_results["HORAS_ESTIMADAS_SKLEARN"]
        - df_results["HORAS_EXECUTADAS"]
    ).round(2)

    df_results["ERRO_ABSOLUTO_SKLEARN"] = (
        df_results["ERRO_SKLEARN"].abs()
    ).round(2)

    df_results["ERRO_QUADRATICO_SKLEARN"] = (
        df_results["ERRO_SKLEARN"] ** 2
    ).round(4)

    # Erro percentual: evita divisão por zero.
    denominador = df_results["HORAS_EXECUTADAS"].replace(0, np.nan)

    df_results["ERRO_PERCENTUAL_SKLEARN"] = (
        (
            df_results["ERRO_ABSOLUTO_SKLEARN"]
            / denominador
        ) * 100
    ).round(2)

    # Erros - NumPy
    df_results["ERRO_NUMPY"] = (
        df_results["HORAS_ESTIMADAS_NUMPY"]
        - df_results["HORAS_EXECUTADAS"]
    ).round(2)

    df_results["ERRO_ABSOLUTO_NUMPY"] = (
        df_results["ERRO_NUMPY"].abs()
    ).round(2)

    df_results["ERRO_QUADRATICO_NUMPY"] = (
        df_results["ERRO_NUMPY"] ** 2
    ).round(4)

    df_results["ERRO_PERCENTUAL_NUMPY"] = (
        (
            df_results["ERRO_ABSOLUTO_NUMPY"]
            / denominador
        ) * 100
    ).round(2)

    # Comparação entre os dois modelos
    df_results["DIFERENCA_MODELOS"] = np.abs(
        df_results["HORAS_ESTIMADAS_SKLEARN"]
        - df_results["HORAS_ESTIMADAS_NUMPY"]
    ).round(2)

    # Identificação simples de maior aderência à hora realizada
    df_results["MODELO_MAIS_PROXIMO"] = np.where(
        df_results["ERRO_ABSOLUTO_SKLEARN"]
        <= df_results["ERRO_ABSOLUTO_NUMPY"],
        "SKLEARN",
        "NUMPY"
    )

    # Metadados metodológicos
    df_results["MODEL_SCOPE"] = MODEL_SCOPE
    df_results["FEATURE_SET_NAME"] = FEATURE_SET_NAME
    df_results["DATA_ANALISE"] = pd.Timestamp.now()

    # Salvar CSV de análise retrospectiva
    output_csv = os.path.join(
        output_dir,
        "analise_retrospectiva.csv"
    )
    df_results.to_csv(output_csv, index=False)

    # Salvar resumo agregado em JSON
    metrics_summary = {
        "model_scope": MODEL_SCOPE,
        "analysis_moment": ANALYSIS_MOMENT,
        "uses_execution_evidence": USES_EXECUTION_EVIDENCE,
        "feature_set_name": FEATURE_SET_NAME,
        "target": TARGET_NAME,
        "n_samples": int(len(df_results)),
        "data_source": sorted(set(map(str, data_source))),
        **{k: float(v) for k, v in sklearn_metrics.items()},
        **{k: float(v) for k, v in numpy_metrics.items()}
    }

    metrics_json = os.path.join(
        output_dir,
        "analise_retrospectiva_metrics.json"
    )
    with open(metrics_json, "w", encoding="utf-8") as f:
        json.dump(
            metrics_summary,
            f,
            ensure_ascii=False,
            indent=4
        )

    # Registrar experimento e artefatos no MLflow
    try:
        default_db = os.path.abspath(os.path.join(output_dir, "mlflow.db")).replace("\\", "/")
        tracking_uri = os.getenv("MLFLOW_TRACKING_URI", f"sqlite:///{default_db}")
        mlflow.set_tracking_uri(tracking_uri)
        mlflow.set_experiment("MUNKA_ML_Analise_Retrospectiva")

        with mlflow.start_run(run_name="Inferencia_Lote_Retrospectiva"):
            mlflow.log_param("model_scope", MODEL_SCOPE)
            mlflow.log_param("analysis_moment", ANALYSIS_MOMENT)
            mlflow.log_param("uses_execution_evidence", USES_EXECUTION_EVIDENCE)
            mlflow.log_param("feature_set_name", FEATURE_SET_NAME)
            mlflow.log_param("target", TARGET_NAME)
            mlflow.log_param("n_samples", int(len(df_results)))
            mlflow.log_param("n_features", len(feature_names))

            # Métricas de performance agregadas
            mlflow.log_metrics({k: float(v) for k, v in sklearn_metrics.items()})
            mlflow.log_metrics({k: float(v) for k, v in numpy_metrics.items()})

            # Artefatos gerados
            if os.path.exists(output_csv):
                mlflow.log_artifact(output_csv)
            if os.path.exists(metrics_json):
                mlflow.log_artifact(metrics_json)
        print(" Experimento e artefatos registrados com sucesso no MLflow (MUNKA_ML_Analise_Retrospectiva).")
    except Exception as e:
        print(f" [Aviso] Não foi possível registrar no MLflow: {e}")

    print(f"\n{'=' * 68}")
    print(f" SUCESSO! {len(df_results)} tarefas analisadas retrospectivamente.")
    print(f" CSV salvo em: {output_csv}")
    print(f" Métricas salvas em: {metrics_json}")
    print(f"{'=' * 68}")

    print("\n=== Métricas Agregadas - Scikit-Learn ===")
    print(
        f"MAE: {sklearn_metrics['sklearn_mae']:.4f} | "
        f"RMSE: {sklearn_metrics['sklearn_rmse']:.4f} | "
        f"R2: {sklearn_metrics['sklearn_r2']:.4f}"
    )

    print("\n=== Métricas Agregadas - NumPy ===")
    print(
        f"MAE: {numpy_metrics['numpy_mae']:.4f} | "
        f"RMSE: {numpy_metrics['numpy_rmse']:.4f} | "
        f"R2: {numpy_metrics['numpy_r2']:.4f}"
    )

    print("\n=== Amostra da Análise Retrospectiva ===")
    print(
        df_results[
            [
                "TAREFA_ID",
                "HORAS_EXECUTADAS",
                "HORAS_ESTIMADAS_SKLEARN",
                "ERRO_ABSOLUTO_SKLEARN",
                "HORAS_ESTIMADAS_NUMPY",
                "ERRO_ABSOLUTO_NUMPY",
                "MODELO_MAIS_PROXIMO"
            ]
        ].head(10)
    )


if __name__ == "__main__":
    run_batch_inference()
