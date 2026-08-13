"""
train_best.py
Retreina os modelos MLP com os melhores hiperparametros encontrados pelo HPO.
Cada modelo le seu proprio arquivo JSON de configuracao:
  - sklearn_best_params.json  ->  MLPRegressor (Scikit-Learn)
  - numpy_best_params.json    ->  NumPyMLPRegressor

Uso:
  python train_best.py --model sklearn
  python train_best.py --model numpy
  python train_best.py --model all    (padrao)
"""
import os
import json
import argparse
import mlflow
import numpy as np
import matplotlib.pyplot as plt
from datetime import datetime
from sklearn.model_selection import KFold, train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from dataset import get_raw_dataset
from mlp_numpy import NumPyMLPRegressor
from mlp_sklearn import train_sklearn_mlp

import joblib
import warnings
from sklearn.exceptions import ConvergenceWarning
warnings.filterwarnings("ignore", category=ConvergenceWarning)

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# ──────────────────────────────────────────────
# Utilidades de graficos
# ──────────────────────────────────────────────
def plot_loss_curve(train_loss, val_loss, model_name, save_path):
    plt.figure(figsize=(10, 5))
    plt.plot(train_loss, label="Treino", color="steelblue")
    if val_loss:
        plt.plot(val_loss, label="Validacao", color="coral", linestyle="--")
    plt.title(f"Curva de Aprendizado — {model_name} (Melhores Hiperparametros)")
    plt.xlabel("Epoca")
    plt.ylabel("MSE")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(save_path)
    plt.close()
    print(f"  Grafico salvo: {save_path}")

def plot_residuals(y_true, preds, model_name, save_path):
    plt.figure(figsize=(7, 5))
    plt.scatter(y_true, preds - y_true, alpha=0.5, color="mediumseagreen")
    plt.axhline(0, color="black", linestyle="--")
    plt.title(f"Residuais — {model_name} (Melhores Hiperparametros)")
    plt.xlabel("Valores Reais (Horas)")
    plt.ylabel("Erro (Previsto - Real)")
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(save_path)
    plt.close()
    print(f"  Grafico salvo: {save_path}")

# ──────────────────────────────────────────────
# Leitura dos JSONs de configuracao
# ──────────────────────────────────────────────
def load_config(path):
    if not os.path.exists(path):
        raise FileNotFoundError(
            f"Arquivo de configuracao nao encontrado: {path}\n"
            f"Execute primeiro: python hpo.py --model {os.path.basename(path).split('_')[0]}"
        )
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

# ──────────────────────────────────────────────
# Retreinamento Sklearn
# ──────────────────────────────────────────────
def retrain_sklearn(config_path="sklearn_best_params.json"):
    config = load_config(config_path)
    hp = config["hyperparameters"]
    hidden_sizes = tuple(hp["hidden_sizes"])
    lr = hp["learning_rate"]
    epochs = config["epochs"]

    print(f"\n{'='*55}")
    print(f" RETREINAMENTO SKLEARN — Melhores Hiperparametros")
    print(f"{'='*55}")
    print(f" hidden_sizes : {hidden_sizes}")
    print(f" learning_rate: {lr:.6f}")
    print(f" alpha        : {hp.get('alpha', 0.0001):.6f}")
    print(f" epochs       : {epochs}")
    print(f" HPO mse      : {config['best_val_mse']:.4f}")
    print(f"{'='*55}")

    from dataset import get_train_test_split
    X_train_full, X_test, y_train_full, y_test, feature_names = get_train_test_split(test_size=0.2, random_state=42)

    tracking_uri = os.getenv("MLFLOW_TRACKING_URI", "sqlite:////tmp/mlflow.db")
    mlflow.set_tracking_uri(tracking_uri)
    mlflow.set_experiment("Auditoria_MLP_Best_Params")

    with mlflow.start_run(run_name="Sklearn_Best_Retrain"):
        mlflow.log_param("config_source", config_path)
        mlflow.log_param("hpo_best_val_mse", config["best_val_mse"])
        mlflow.log_param("hpo_improvement_pct", config["improvement_vs_baseline_pct"])
        mlflow.log_params({
            "model": "sklearn",
            "epochs": epochs,
            "learning_rate": lr,
            "hidden_sizes": str(hidden_sizes),
            "retrained_at": datetime.now().isoformat(),
        })

        # 5-Fold no conjunto de treino de 4.000 amostras (3.200 treino / 800 val por fold)
        print("\n  Executando 5-Fold Cross Validation no treino (4.000 amostras)...")
        kf = KFold(n_splits=5, shuffle=True, random_state=42)
        mse_list, mae_list, r2_list = [], [], []

        for fold, (train_idx, val_idx) in enumerate(kf.split(X_train_full), 1):
            X_tr, X_val = X_train_full[train_idx], X_train_full[val_idx]
            y_tr, y_val = y_train_full[train_idx], y_train_full[val_idx]
            scaler = StandardScaler()
            X_tr_sc = scaler.fit_transform(X_tr)
            X_val_sc = scaler.transform(X_val)
            model = train_sklearn_mlp(X_tr_sc, y_tr,
                                      hidden_sizes=hidden_sizes,
                                      learning_rate=lr, epochs=epochs)
            preds = model.predict(X_val_sc).reshape(-1, 1)
            mse_list.append(mean_squared_error(y_val, preds))
            mae_list.append(mean_absolute_error(y_val, preds))
            r2_list.append(r2_score(y_val, preds))
            print(f"  Fold {fold}: MSE={mse_list[-1]:.4f}  R2={r2_list[-1]:.4f}")

        kfold_mse = float(np.mean(mse_list))
        kfold_r2  = float(np.mean(r2_list))
        mlflow.log_metrics({
            "kfold_mse": kfold_mse,
            "kfold_mae": float(np.mean(mae_list)),
            "kfold_r2":  kfold_r2,
        })

        # Treino final sobre todos os 4.000 de treino e teste sobre os 1.000 do Holdout
        scaler_f = StandardScaler()
        X_train_sc_f = scaler_f.fit_transform(X_train_full)
        X_test_sc_f  = scaler_f.transform(X_test)

        final_model = train_sklearn_mlp(X_train_sc_f, y_train_full,
                                        hidden_sizes=hidden_sizes,
                                        learning_rate=lr, epochs=epochs)
        final_preds = final_model.predict(X_test_sc_f).reshape(-1, 1)
        final_mse = mean_squared_error(y_test, final_preds)
        mlflow.log_metric("final_test_mse", final_mse)

        # Curva de loss
        plot_loss_curve(
            final_model.loss_curve_,
            None,
            "Scikit-Learn",
            os.path.join(OUTPUT_DIR, "sklearn_best_loss_curve.png")
        )
        mlflow.log_artifact(os.path.join(OUTPUT_DIR, "sklearn_best_loss_curve.png"))

        # Residuais
        plot_residuals(y_test, final_preds, "Scikit-Learn", os.path.join(OUTPUT_DIR, "sklearn_best_residuals.png"))
        mlflow.log_artifact(os.path.join(OUTPUT_DIR, "sklearn_best_residuals.png"))

        # Salva o modelo treinado com joblib para reutilizacao futura
        sklearn_model_path = os.path.join(OUTPUT_DIR, "sklearn_best_model.joblib")
        joblib.dump(final_model, sklearn_model_path)
        mlflow.log_artifact(sklearn_model_path)
        print(f"  Modelo Sklearn salvo em: {sklearn_model_path}")

        # Salva o Scaler
        scaler_path = os.path.join(OUTPUT_DIR, "scaler.joblib")
        joblib.dump(scaler_f, scaler_path)
        mlflow.log_artifact(scaler_path)
        print(f"  Scaler salvo em: {scaler_path}")

        # Loga o JSON de config como artefato
        if os.path.exists(config_path):
            mlflow.log_artifact(config_path)

        print(f"\n  Sklearn K-Fold MSE : {kfold_mse:.4f}")
        print(f"  Sklearn K-Fold R2  : {kfold_r2:.4f}")
        print(f"  Sklearn Final MSE  : {final_mse:.4f}")
        print(f"  (Baseline MSE era  : 4.5521)")

# ──────────────────────────────────────────────
# Retreinamento Sklearn Restrito
# ──────────────────────────────────────────────
def retrain_sklearn_restricted(config_path="sklearn_restricted_best_params.json"):
    config = load_config(config_path)
    hp = config["hyperparameters"]
    hidden_sizes = tuple(hp["hidden_sizes"])
    lr = hp["learning_rate"]
    epochs = config["epochs"]

    print(f"\n{'='*55}")
    print(f" RETREINAMENTO SKLEARN RESTRITO — Melhores Hiperparametros")
    print(f"{'='*55}")
    print(f" hidden_sizes : {hidden_sizes}")
    print(f" learning_rate: {lr:.6f}")
    print(f" alpha        : {hp.get('alpha', 0.0001):.6f}")
    print(f" epochs       : {epochs}")
    print(f" HPO mse      : {config['best_val_mse']:.4f}")
    print(f"{'='*55}")

    from dataset import get_train_test_split
    X_train_full, X_test, y_train_full, y_test, feature_names = get_train_test_split(test_size=0.2, random_state=42)

    tracking_uri = os.getenv("MLFLOW_TRACKING_URI", "sqlite:////tmp/mlflow.db")
    mlflow.set_tracking_uri(tracking_uri)
    mlflow.set_experiment("Auditoria_MLP_Best_Params")

    with mlflow.start_run(run_name="Sklearn_Restricted_Best_Retrain"):
        mlflow.log_param("config_source", config_path)
        mlflow.log_param("hpo_best_val_mse", config["best_val_mse"])
        mlflow.log_param("hpo_improvement_pct", config["improvement_vs_baseline_pct"])
        mlflow.log_params({
            "model": "sklearn_restricted",
            "epochs": epochs,
            "learning_rate": lr,
            "hidden_sizes": str(hidden_sizes),
            "retrained_at": datetime.now().isoformat(),
        })

        # 5-Fold no conjunto de treino de 4.000 amostras (3.200 treino / 800 val por fold)
        print("\n  Executando 5-Fold Cross Validation no treino (4.000 amostras)...")
        kf = KFold(n_splits=5, shuffle=True, random_state=42)
        mse_list, mae_list, r2_list = [], [], []

        for fold, (train_idx, val_idx) in enumerate(kf.split(X_train_full), 1):
            X_tr, X_val = X_train_full[train_idx], X_train_full[val_idx]
            y_tr, y_val = y_train_full[train_idx], y_train_full[val_idx]
            scaler = StandardScaler()
            X_tr_sc = scaler.fit_transform(X_tr)
            X_val_sc = scaler.transform(X_val)
            model = train_sklearn_mlp(X_tr_sc, y_tr,
                                      hidden_sizes=hidden_sizes,
                                      learning_rate=lr, epochs=epochs)
            preds = model.predict(X_val_sc).reshape(-1, 1)
            mse_list.append(mean_squared_error(y_val, preds))
            mae_list.append(mean_absolute_error(y_val, preds))
            r2_list.append(r2_score(y_val, preds))
            print(f"  Fold {fold}: MSE={mse_list[-1]:.4f}  R2={r2_list[-1]:.4f}")

        kfold_mse = float(np.mean(mse_list))
        kfold_r2  = float(np.mean(r2_list))
        mlflow.log_metrics({
            "kfold_mse": kfold_mse,
            "kfold_mae": float(np.mean(mae_list)),
            "kfold_r2":  kfold_r2,
        })

        # Treino final sobre todos os 4.000 de treino e teste sobre os 1.000 do Holdout
        scaler_f = StandardScaler()
        X_train_sc_f = scaler_f.fit_transform(X_train_full)
        X_test_sc_f  = scaler_f.transform(X_test)

        final_model = train_sklearn_mlp(X_train_sc_f, y_train_full,
                                        hidden_sizes=hidden_sizes,
                                        learning_rate=lr, epochs=epochs)
        final_preds = final_model.predict(X_test_sc_f).reshape(-1, 1)
        final_mse = mean_squared_error(y_test, final_preds)
        mlflow.log_metric("final_test_mse", final_mse)

        # Curva de loss
        plot_loss_curve(
            final_model.loss_curve_,
            None,
            "Scikit-Learn Restricted",
            os.path.join(OUTPUT_DIR, "sklearn_restricted_best_loss_curve.png")
        )
        mlflow.log_artifact(os.path.join(OUTPUT_DIR, "sklearn_restricted_best_loss_curve.png"))

        # Residuais
        plot_residuals(y_test, final_preds, "Scikit-Learn Restricted", os.path.join(OUTPUT_DIR, "sklearn_restricted_best_residuals.png"))
        mlflow.log_artifact(os.path.join(OUTPUT_DIR, "sklearn_restricted_best_residuals.png"))

        # Salva o modelo treinado com joblib para reutilizacao futura
        sklearn_model_path = os.path.join(OUTPUT_DIR, "sklearn_restricted_best_model.joblib")
        joblib.dump(final_model, sklearn_model_path)
        mlflow.log_artifact(sklearn_model_path)
        print(f"  Modelo Sklearn Restricted salvo em: {sklearn_model_path}")

        # Loga o JSON de config como artefato
        if os.path.exists(config_path):
            mlflow.log_artifact(config_path)

        print(f"\n  Sklearn Restricted K-Fold MSE : {kfold_mse:.4f}")
        print(f"  Sklearn Restricted K-Fold R2  : {kfold_r2:.4f}")
        print(f"  Sklearn Restricted Final MSE  : {final_mse:.4f}")
        print(f"  (Baseline MSE era  : 4.5521)")

# ──────────────────────────────────────────────
# Retreinamento NumPy
# ──────────────────────────────────────────────
def retrain_numpy(config_path="numpy_best_params.json"):
    config = load_config(config_path)
    hp = config["hyperparameters"]
    hidden_sizes = tuple(hp["hidden_sizes"])
    lr = hp["learning_rate"]
    epochs = config["epochs"]

    print(f"\n{'='*55}")
    print(f" RETREINAMENTO NUMPY — Melhores Hiperparametros")
    print(f"{'='*55}")
    print(f" hidden_sizes : {hidden_sizes}")
    print(f" learning_rate: {lr:.6f}")
    print(f" epochs       : {epochs}")
    print(f" HPO mse      : {config['best_val_mse']:.4f}")
    print(f"{'='*55}")

    from dataset import get_train_test_split
    X_train_full, X_test, y_train_full, y_test, feature_names = get_train_test_split(test_size=0.2, random_state=42)

    tracking_uri = os.getenv("MLFLOW_TRACKING_URI", "sqlite:////tmp/mlflow.db")
    mlflow.set_tracking_uri(tracking_uri)
    mlflow.set_experiment("Auditoria_MLP_Best_Params")

    with mlflow.start_run(run_name="NumPy_Best_Retrain"):
        mlflow.log_param("config_source", config_path)
        mlflow.log_param("hpo_best_val_mse", config["best_val_mse"])
        mlflow.log_param("hpo_improvement_pct", config["improvement_vs_baseline_pct"])
        mlflow.log_params({
            "model": "numpy",
            "epochs": epochs,
            "learning_rate": lr,
            "hidden_sizes": str(hidden_sizes),
            "retrained_at": datetime.now().isoformat(),
        })

        # K-Fold 5 splits sobre os 4.000 de treino (3.200 treino / 800 val por fold)
        print("\n  Executando 5-Fold Cross Validation no treino (4.000 amostras)...")
        kf = KFold(n_splits=5, shuffle=True, random_state=42)
        mse_list, mae_list, r2_list = [], [], []

        for fold, (train_idx, val_idx) in enumerate(kf.split(X_train_full), 1):
            X_tr, X_val = X_train_full[train_idx], X_train_full[val_idx]
            y_tr, y_val = y_train_full[train_idx], y_train_full[val_idx]
            scaler = StandardScaler()
            X_tr_sc = scaler.fit_transform(X_tr)
            X_val_sc  = scaler.transform(X_val)
            model = NumPyMLPRegressor(
                input_size=X_tr_sc.shape[1],
                hidden_sizes=hidden_sizes,
                learning_rate=lr,
                epochs=epochs
            )
            model.train(X_tr_sc, y_tr, log_interval=1000)
            preds = model.predict(X_val_sc)
            mse_list.append(mean_squared_error(y_val, preds))
            mae_list.append(mean_absolute_error(y_val, preds))
            r2_list.append(r2_score(y_val, preds))
            print(f"  Fold {fold}: MSE={mse_list[-1]:.4f}  R2={r2_list[-1]:.4f}")

        kfold_mse = float(np.mean(mse_list))
        kfold_r2  = float(np.mean(r2_list))
        mlflow.log_metrics({
            "kfold_mse": kfold_mse,
            "kfold_mae": float(np.mean(mae_list)),
            "kfold_r2":  kfold_r2,
        })

        # Treino final sobre todos os 4.000 de treino e teste sobre os 1.000 do Holdout
        scaler_f = StandardScaler()
        X_train_sc_f = scaler_f.fit_transform(X_train_full)
        X_test_sc_f  = scaler_f.transform(X_test)

        final_model = NumPyMLPRegressor(
            input_size=X_train_sc_f.shape[1],
            hidden_sizes=hidden_sizes,
            learning_rate=lr,
            epochs=epochs
        )
        final_model.train(X_train_sc_f, y_train_full,
                          X_val=X_test_sc_f, y_val=y_test,
                          log_interval=1000)

        final_preds = final_model.predict(X_test_sc_f)
        final_mse = mean_squared_error(y_test, final_preds)
        final_mae = mean_absolute_error(y_test, final_preds)
        final_r2  = r2_score(y_test, final_preds)
        mlflow.log_metrics({
            "final_test_mse": final_mse,
            "final_test_mae": final_mae,
            "final_test_r2": final_r2
        })

        # Curva de loss
        plot_loss_curve(
            final_model.loss_history,
            final_model.val_loss_history,
            "NumPy MLP",
            os.path.join(OUTPUT_DIR, "numpy_best_loss_curve.png")
        )
        mlflow.log_artifact(os.path.join(OUTPUT_DIR, "numpy_best_loss_curve.png"))

        # Residuais
        plot_residuals(y_test, final_preds, "NumPy MLP", os.path.join(OUTPUT_DIR, "numpy_best_residuals.png"))
        mlflow.log_artifact(os.path.join(OUTPUT_DIR, "numpy_best_residuals.png"))

        # Salva os pesos do modelo NumPy para reutilizacao futura
        numpy_weights_path = os.path.join(OUTPUT_DIR, "numpy_best_model.npz")
        final_model.save_weights(numpy_weights_path)
        mlflow.log_artifact(numpy_weights_path)
        print(f"  Para reutilizar: model = NumPyMLPRegressor.from_weights('{numpy_weights_path}')")

        mlflow.log_artifact(config_path)

        print(f"\n  NumPy K-Fold MSE   : {kfold_mse:.4f}")
        print(f"  NumPy K-Fold R2    : {kfold_r2:.4f}")
        print(f"  NumPy Final MSE    : {final_mse:.4f}")
        print(f"  (Baseline MSE era  : 6.0377)")

# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(
        description="Retreina MLPs com melhores hiperparametros do HPO"
    )
    parser.add_argument(
        "--model",
        choices=["sklearn", "numpy", "sklearn_restricted", "all"],
        default="all",
        help="Qual modelo retreinar: sklearn | numpy | sklearn_restricted | all (padrao: all)"
    )
    parser.add_argument(
        "--config-dir",
        default=".",
        help="Diretorio onde estao os JSONs de configuracao (padrao: diretorio atual)"
    )
    args = parser.parse_args()

    sk_path = os.path.join(args.config_dir, "sklearn_best_params.json")
    np_path = os.path.join(args.config_dir, "numpy_best_params.json")
    sk_rest_path = os.path.join(args.config_dir, "sklearn_restricted_best_params.json")

    if args.model in ("sklearn", "all"):
        retrain_sklearn(sk_path)

    if args.model in ("numpy", "all"):
        retrain_numpy(np_path)
        
    if args.model in ("sklearn_restricted", "all"):
        retrain_sklearn_restricted(sk_rest_path)

    print("\n========== RETREINAMENTO CONCLUIDO ==========")
    print("Artefatos, metricas e configs registrados no MLflow.")
    print("Experimento: Auditoria_MLP_Best_Params")
    print("=============================================")

if __name__ == "__main__":
    main()
