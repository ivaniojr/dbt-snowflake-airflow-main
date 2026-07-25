import os
import json
import mlflow
import optuna
import numpy as np
from datetime import datetime
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_squared_error
from dataset import get_raw_dataset
from mlp_numpy import NumPyMLPRegressor
from mlp_sklearn import train_sklearn_mlp

# Desabilitar logs do sklearn convergence warning para limpar o terminal no HPO
import warnings
from sklearn.exceptions import ConvergenceWarning
warnings.filterwarnings("ignore", category=ConvergenceWarning)

def get_hpo_data():
    X, y, _ = get_raw_dataset()
    # Holdout de 80/20 para a otimização
    X_train, X_val, y_train, y_val = train_test_split(X, y, test_size=0.2, random_state=42)
    
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_val_scaled = scaler.transform(X_val)
    
    return X_train_scaled, X_val_scaled, y_train, y_val

def objective_sklearn(trial, X_train, X_val, y_train, y_val):
    
    # Espaço de busca (Search Space)
    lr = trial.suggest_float("learning_rate", 1e-4, 1e-1, log=True)
    n_layers = trial.suggest_int("n_layers", 1, 3)
    
    layers = []
    for i in range(n_layers):
        n_units = trial.suggest_categorical(f"n_units_l{i}", [8, 16, 32, 64, 128])
        layers.append(n_units)
    hidden_sizes = tuple(layers)
    
    # Parâmetro extra de regularização para o Sklearn
    alpha = trial.suggest_float("alpha", 1e-5, 1e-1, log=True)
    
    with mlflow.start_run(nested=True, run_name=f"Trial_{trial.number}"):
        mlflow.log_params(trial.params)
        
        # O HPO roda rápido com 200 épocas e early stopping no Sklearn
        model = train_sklearn_mlp(X_train, y_train, hidden_sizes=hidden_sizes, learning_rate=lr, epochs=300)
        
        preds = model.predict(X_val).reshape(-1, 1)
        mse = mean_squared_error(y_val, preds)
        
        mlflow.log_metric("val_mse", mse)
        
    return mse

def objective_numpy(trial, X_train, X_val, y_train, y_val):
    
    lr = trial.suggest_float("learning_rate", 1e-4, 1e-1, log=True)
    
    # A nossa rede NumPy tem arquitetura hardcoded para 2 ou 3 camadas no mlp_numpy.py
    # Para não quebrar a lógica matemática original (onde W1, W2, W3 estão cravados), 
    # vamos ajustar apenas o tamanho dessas camadas exatas.
    size_l1 = trial.suggest_categorical("n_units_l1", [16, 32, 64])
    size_l2 = trial.suggest_categorical("n_units_l2", [8, 16, 32])
    hidden_sizes = (size_l1, size_l2)
    
    with mlflow.start_run(nested=True, run_name=f"Trial_NumPy_{trial.number}"):
        mlflow.log_params(trial.params)
        
        model = NumPyMLPRegressor(input_size=X_train.shape[1], hidden_sizes=hidden_sizes, learning_rate=lr, epochs=200)
        # log_interval altíssimo para não poluir terminal
        model.train(X_train, y_train, log_interval=1000)
        
        preds = model.predict(X_val)
        mse = mean_squared_error(y_val, preds)
        
        mlflow.log_metric("val_mse", mse)
        
    return mse

def save_results(study_sklearn, study_numpy, output_path="hpo_results.json"):
    """Exporta um sumário auditável dos melhores hiperparâmetros para o repositório."""
    results = {
        "generated_at": datetime.now().isoformat(),
        "mlflow_experiment": "Auditoria_MLP_HPO",
        "baseline": {
            "description": "Resultados do treinamento baseline sem HPO (5-Fold CV com dados reais do Snowflake)",
            "sklearn_r2": 0.7528,
            "sklearn_mse": 4.5521,
            "numpy_r2": 0.6717,
            "numpy_mse": 6.0377,
        },
        "sklearn": {
            "n_trials": len(study_sklearn.trials),
            "best_val_mse": round(study_sklearn.best_value, 6),
            "best_params": study_sklearn.best_params,
            "improvement_vs_baseline_pct": round(
                (4.5521 - study_sklearn.best_value) / 4.5521 * 100, 2
            ),
        },
        "numpy": {
            "n_trials": len(study_numpy.trials),
            "best_val_mse": round(study_numpy.best_value, 6),
            "best_params": study_numpy.best_params,
            "improvement_vs_baseline_pct": round(
                (6.0377 - study_numpy.best_value) / 6.0377 * 100, 2
            ),
        },
    }

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    print(f"\n✅ Resultados exportados para: {output_path}")

    # Imprime sumário no terminal
    print("\n========== SUMÁRIO HPO ==========")
    print(f"Sklearn  | Melhor MSE: {results['sklearn']['best_val_mse']:.4f} | Melhoria vs baseline: {results['sklearn']['improvement_vs_baseline_pct']:+.1f}%")
    print(f"NumPy    | Melhor MSE: {results['numpy']['best_val_mse']:.4f} | Melhoria vs baseline: {results['numpy']['improvement_vs_baseline_pct']:+.1f}%")
    print(f"Params Sklearn: {results['sklearn']['best_params']}")
    print(f"Params NumPy  : {results['numpy']['best_params']}")
    print("=================================")

def main():
    mlflow.set_tracking_uri("sqlite:///mlflow.db")
    mlflow.set_experiment("Auditoria_MLP_HPO")
    
    print("Baixando dados do Snowflake uma única vez para o cache do HPO...")
    X_train, X_val, y_train, y_val = get_hpo_data()
    print("Iniciando Otimização de Hiperparâmetros (Optuna)...")
    
    # 1. HPO para Scikit-Learn
    print("\n--- Otimizando Modelo Scikit-Learn (15 trials) ---")
    with mlflow.start_run(run_name="Sklearn_HPO_Study"):
        study_sklearn = optuna.create_study(direction="minimize", study_name="Sklearn_MLP_Optimization")
        study_sklearn.optimize(lambda trial: objective_sklearn(trial, X_train, X_val, y_train, y_val), n_trials=15)
        
        print("\nMelhores Parâmetros Sklearn:")
        print(study_sklearn.best_params)
        print(f"Melhor MSE: {study_sklearn.best_value:.4f}")
        
    # 2. HPO para NumPy (Reduzido para não travar CPU)
    print("\n--- Otimizando Modelo NumPy Matemático (10 trials) ---")
    with mlflow.start_run(run_name="NumPy_HPO_Study"):
        study_numpy = optuna.create_study(direction="minimize", study_name="NumPy_MLP_Optimization")
        study_numpy.optimize(lambda trial: objective_numpy(trial, X_train, X_val, y_train, y_val), n_trials=10)
        
        print("\nMelhores Parâmetros NumPy:")
        print(study_numpy.best_params)
        print(f"Melhor MSE: {study_numpy.best_value:.4f}")

    # 3. Exporta resultados para o repositório (hpo_results.json)
    save_results(study_sklearn, study_numpy, output_path="hpo_results.json")

if __name__ == "__main__":
    main()
