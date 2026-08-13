import os
import sys
import json
import argparse
class DummyMLFlowContext:
    def __enter__(self): return self
    def __exit__(self, exc_type, exc_val, exc_tb): pass

class DummyMLFlow:
    def set_tracking_uri(self, uri): pass
    def set_experiment(self, exp): pass
    def start_run(self, *args, **kwargs): return DummyMLFlowContext()
    def log_params(self, params): pass
    def log_metric(self, key, val): pass

try:
    import mlflow
except Exception:
    mlflow = DummyMLFlow()

try:
    import optuna
except Exception:
    optuna = None

import numpy as np
from datetime import datetime
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_squared_error
from dataset import get_raw_dataset
from mlp_numpy import NumPyMLPRegressor
from mlp_sklearn import train_sklearn_mlp

import warnings
from sklearn.exceptions import ConvergenceWarning
warnings.filterwarnings("ignore", category=ConvergenceWarning)

# ──────────────────────────────────────────────
# Configuracoes globais
# ──────────────────────────────────────────────
EPOCHS = 150
N_TRIALS_SKLEARN = 10
N_TRIALS_NUMPY = 10

BASELINE_SKLEARN_MSE = 4.5521
BASELINE_NUMPY_MSE = 6.0377

# ──────────────────────────────────────────────
# Dados
# ──────────────────────────────────────────────
def get_hpo_data():
    from dataset import get_train_test_split
    # Carrega X_train_full (4.000 amostras do conjunto de treino principal)
    X_train_full, X_test, y_train_full, y_test, _ = get_train_test_split(test_size=0.2, random_state=42)
    # Subdivide os 4.000 registros em 3.200 treino interno / 800 validação interna para o HPO
    X_train, X_val, y_train, y_val = train_test_split(X_train_full, y_train_full, test_size=0.2, random_state=42)
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_val_scaled = scaler.transform(X_val)
    return X_train_scaled, X_val_scaled, y_train, y_val

# ──────────────────────────────────────────────
# Objectives
# ──────────────────────────────────────────────
def objective_sklearn(trial, X_train, X_val, y_train, y_val):
    lr = trial.suggest_float("learning_rate", 1e-4, 1e-1, log=True)
    n_layers = trial.suggest_int("n_layers", 1, 3)
    layers = []
    for i in range(n_layers):
        n_units = trial.suggest_categorical(f"n_units_l{i}", [8, 16, 32, 64, 128])
        layers.append(n_units)
    hidden_sizes = tuple(layers)
    alpha = trial.suggest_float("alpha", 1e-5, 1e-1, log=True)

    with mlflow.start_run(nested=True, run_name=f"Trial_SK_{trial.number}"):
        mlflow.log_params(trial.params)
        model = train_sklearn_mlp(X_train, y_train, hidden_sizes=hidden_sizes,
                                  learning_rate=lr, epochs=EPOCHS)
        preds = model.predict(X_val).reshape(-1, 1)
        mse = mean_squared_error(y_val, preds)
        mlflow.log_metric("val_mse", mse)
    return mse

def objective_numpy(trial, X_train, X_val, y_train, y_val):
    lr = trial.suggest_float("learning_rate", 1e-4, 1e-1, log=True)
    size_l1 = trial.suggest_categorical("n_units_l1", [16, 32, 64])
    size_l2 = trial.suggest_categorical("n_units_l2", [8, 16, 32])
    hidden_sizes = (size_l1, size_l2)

    with mlflow.start_run(nested=True, run_name=f"Trial_NP_{trial.number}"):
        mlflow.log_params(trial.params)
        model = NumPyMLPRegressor(input_size=X_train.shape[1],
                                  hidden_sizes=hidden_sizes,
                                  learning_rate=lr, epochs=EPOCHS)
        model.train(X_train, y_train, log_interval=1000)
        preds = model.predict(X_val)
        mse = mean_squared_error(y_val, preds)
        mlflow.log_metric("val_mse", mse)
    return mse

# ──────────────────────────────────────────────
# Exportadores de JSON por modelo
# ──────────────────────────────────────────────
def save_sklearn_json(study, output_path="sklearn_best_params.json"):
    best = study.best_params
    # Reconstroi hidden_sizes a partir dos params do trial vencedor
    n_layers = best["n_layers"]
    hidden_sizes = [best[f"n_units_l{i}"] for i in range(n_layers)]
    improvement = round((BASELINE_SKLEARN_MSE - study.best_value) / BASELINE_SKLEARN_MSE * 100, 2)

    config = {
        "model": "sklearn",
        "generated_at": datetime.now().isoformat(),
        "mlflow_experiment": "Auditoria_MLP_HPO",
        "n_trials": len(study.trials),
        "epochs": EPOCHS,
        "best_val_mse": round(study.best_value, 6),
        "improvement_vs_baseline_pct": improvement,
        "hyperparameters": {
            "learning_rate": best["learning_rate"],
            "hidden_sizes": hidden_sizes,
            "alpha": best["alpha"]
        }
    }
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    print(f"\nSklearn config salva em: {output_path}")
    print(f"  best_val_mse={config['best_val_mse']:.4f}  melhoria={improvement:+.1f}%")
    print(f"  params={config['hyperparameters']}")
    return config

def save_numpy_json(study, output_path="numpy_best_params.json"):
    best = study.best_params
    hidden_sizes = [best["n_units_l1"], best["n_units_l2"]]
    improvement = round((BASELINE_NUMPY_MSE - study.best_value) / BASELINE_NUMPY_MSE * 100, 2)

    config = {
        "model": "numpy",
        "generated_at": datetime.now().isoformat(),
        "mlflow_experiment": "Auditoria_MLP_HPO",
        "n_trials": len(study.trials),
        "epochs": EPOCHS,
        "best_val_mse": round(study.best_value, 6),
        "improvement_vs_baseline_pct": improvement,
        "hyperparameters": {
            "learning_rate": best["learning_rate"],
            "hidden_sizes": hidden_sizes
        }
    }
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(config, f, indent=2, ensure_ascii=False)
    print(f"\nNumPy config salva em: {output_path}")
    print(f"  best_val_mse={config['best_val_mse']:.4f}  melhoria={improvement:+.1f}%")
    print(f"  params={config['hyperparameters']}")
    return config

# ──────────────────────────────────────────────
# Runners por modelo
# ──────────────────────────────────────────────
def run_sklearn_hpo(X_train, X_val, y_train, y_val, output_path="sklearn_best_params.json"):
    print(f"\n--- Otimizando Sklearn ({N_TRIALS_SKLEARN} trials | {EPOCHS} epocas | max 30m) ---")
    with mlflow.start_run(run_name="Sklearn_HPO_Study"):
        study = optuna.create_study(direction="minimize", study_name="Sklearn_MLP_Optimization")
        study.optimize(
            lambda trial: objective_sklearn(trial, X_train, X_val, y_train, y_val),
            n_trials=N_TRIALS_SKLEARN,
            timeout=1800
        )
    return save_sklearn_json(study, output_path)

def run_numpy_hpo(X_train, X_val, y_train, y_val, output_path="numpy_best_params.json"):
    print(f"\n--- Otimizando NumPy ({N_TRIALS_NUMPY} trials | {EPOCHS} epocas | max 30m) ---")
    with mlflow.start_run(run_name="NumPy_HPO_Study"):
        study = optuna.create_study(direction="minimize", study_name="NumPy_MLP_Optimization")
        study.optimize(
            lambda trial: objective_numpy(trial, X_train, X_val, y_train, y_val),
            n_trials=N_TRIALS_NUMPY,
            timeout=1800
        )
    return save_numpy_json(study, output_path)

# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="HPO com Optuna para modelos MLP")
    parser.add_argument(
        "--model",
        choices=["sklearn", "numpy", "all"],
        default="all",
        help="Qual modelo otimizar: sklearn | numpy | all (padrao: all)"
    )
    parser.add_argument(
        "--output-dir",
        default=".",
        help="Diretorio onde salvar os JSONs de configuracao (padrao: diretorio atual)"
    )
    args = parser.parse_args()

    tracking_uri = os.getenv("MLFLOW_TRACKING_URI", "sqlite:////tmp/mlflow.db")
    mlflow.set_tracking_uri(tracking_uri)
    mlflow.set_experiment("Auditoria_MLP_HPO")

    print("Carregando dados do Snowflake...")
    X_train, X_val, y_train, y_val = get_hpo_data()
    print("Iniciando HPO (Optuna)...")

    sk_path = os.path.join(args.output_dir, "sklearn_best_params.json")
    np_path = os.path.join(args.output_dir, "numpy_best_params.json")

    if args.model in ("sklearn", "all"):
        run_sklearn_hpo(X_train, X_val, y_train, y_val, sk_path)

    if args.model in ("numpy", "all"):
        run_numpy_hpo(X_train, X_val, y_train, y_val, np_path)

    print("\n========== HPO CONCLUIDO ==========")
    if args.model in ("sklearn", "all"):
        print(f"Sklearn config: {sk_path}")
    if args.model in ("numpy", "all"):
        print(f"NumPy   config: {np_path}")
    print("====================================")

if __name__ == "__main__":
    main()
