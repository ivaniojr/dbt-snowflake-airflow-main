import os
import json
import mlflow
import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from sklearn.model_selection import KFold, train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.inspection import permutation_importance
from sklearn.base import BaseEstimator, RegressorMixin
from mlp_numpy import NumPyMLPRegressor
from mlp_sklearn import train_sklearn_mlp

# ============================================================
# Contrato metodológico do modelo
# ============================================================

MODEL_SCOPE = "retrospective_analysis"
ANALYSIS_MOMENT = "post_execution"
USES_EXECUTION_EVIDENCE = True
FEATURE_SET_NAME = "retrospective_features_v1"
TARGET_NAME = "HORAS_EXECUTADAS"

def plot_residuals(y_true, numpy_preds, sklearn_preds, save_path="residuals_comparison.png"):
    plt.figure(figsize=(14, 6))
    
    # Resíduos NumPy
    plt.subplot(1, 2, 1)
    plt.scatter(y_true, numpy_preds - y_true, alpha=0.5, color='blue')
    plt.axhline(0, color='black', linestyle='--')
    plt.title('NumPy MLP: Resíduos')
    plt.xlabel('Valores Reais (Horas)')
    plt.ylabel('Erro Residual (Previsto - Real)')
    plt.grid(True)
    
    # Resíduos Sklearn
    plt.subplot(1, 2, 2)
    plt.scatter(y_true, sklearn_preds - y_true, alpha=0.5, color='green')
    plt.axhline(0, color='black', linestyle='--')
    plt.title('Scikit-Learn MLP: Resíduos')
    plt.xlabel('Valores Reais (Horas)')
    plt.ylabel('Erro Residual (Previsto - Real)')
    plt.grid(True)
    
    plt.tight_layout()
    plt.savefig(save_path)
    plt.close()

class SklearnWrapper(BaseEstimator, RegressorMixin):
    """Wrapper para satisfazer a validação do sklearn (precisa de fit e predict)."""
    def __init__(self, model):
        self.model = model
        self.is_fitted_ = True
        
    def fit(self, X, y=None):
        self.is_fitted_ = True
        return self
        
    def predict(self, X):
        return self.model.predict(X).ravel()

def plot_feature_importance(model, X_test, y_test, feature_names, title, save_path):
    # Envolve o modelo NumPy se não for um estimador do scikit-learn
    if not hasattr(model, 'fit'):
        model = SklearnWrapper(model)
        
    result = permutation_importance(model, X_test, y_test, n_repeats=10, random_state=42, scoring='neg_mean_squared_error')
    sorted_idx = result.importances_mean.argsort()

    plt.figure(figsize=(10, 6))
    plt.boxplot(
        result.importances[sorted_idx].T,
        vert=False
    )
    plt.yticks(range(1, len(feature_names) + 1), np.array(feature_names)[sorted_idx])
    plt.title(f"Permutation Feature Importance - {title}")
    plt.tight_layout()
    plt.savefig(save_path)
    plt.close()

def plot_loss_curves(numpy_train_loss, numpy_val_loss, sklearn_train_loss, sklearn_val_loss, save_path="loss_validation_curve.png"):
    plt.figure(figsize=(12, 6))
    
    plt.plot(numpy_train_loss, label='NumPy Treino', color='blue')
    plt.plot(numpy_val_loss, label='NumPy Validação', color='cyan', linestyle='--')
    
    plt.plot(sklearn_train_loss, label='Sklearn Treino', color='green')
    if sklearn_val_loss is not None:
        plt.plot(sklearn_val_loss, label='Sklearn Validação (Score invertido)', color='lime', linestyle='--')
        
    plt.title('Curvas de Aprendizado (Treino vs Validação)')
    plt.xlabel('Época (Epoch)')
    plt.ylabel('Erro Quadrático Médio (MSE)')
    plt.legend()
    plt.grid(True)
    plt.savefig(save_path)
    plt.close()

def run_kfold_evaluation(X, y, params):
    kf = KFold(n_splits=5, shuffle=True, random_state=42)
    
    numpy_metrics = {'mse': [], 'mae': [], 'r2': []}
    sklearn_metrics = {'mse': [], 'mae': [], 'r2': []}
    
    fold = 1
    for train_index, test_index in kf.split(X):
        print(f"\n--- Treinando Fold {fold} ---")
        X_train, X_test = X[train_index], X[test_index]
        y_train, y_test = y[train_index], y[test_index]
        
        # Scaling isolado por Fold (prevenção de Data Leakage na etapa de padronização)
        scaler_X = StandardScaler()
        X_train_scaled = scaler_X.fit_transform(X_train)
        X_test_scaled = scaler_X.transform(X_test)
        
        # Treina NumPy
        numpy_model = NumPyMLPRegressor(X_train_scaled.shape[1], hidden_sizes=params["hidden_sizes"], learning_rate=params["learning_rate"], epochs=params["epochs"])
        numpy_model.train(X_train_scaled, y_train, log_interval=1000) # log reduzido para k-fold
        np_preds = numpy_model.predict(X_test_scaled)
        
        numpy_metrics['mse'].append(mean_squared_error(y_test, np_preds))
        numpy_metrics['mae'].append(mean_absolute_error(y_test, np_preds))
        numpy_metrics['r2'].append(r2_score(y_test, np_preds))
        
        # Treina Sklearn
        sklearn_model = train_sklearn_mlp(X_train_scaled, y_train, hidden_sizes=params["hidden_sizes"], learning_rate=params["learning_rate"], epochs=params["epochs"])
        sk_preds = sklearn_model.predict(X_test_scaled).reshape(-1, 1)
        
        sklearn_metrics['mse'].append(mean_squared_error(y_test, sk_preds))
        sklearn_metrics['mae'].append(mean_absolute_error(y_test, sk_preds))
        sklearn_metrics['r2'].append(r2_score(y_test, sk_preds))
        
        fold += 1
        
    return {
        'numpy_kfold_mse': np.mean(numpy_metrics['mse']),
        'numpy_kfold_mae': np.mean(numpy_metrics['mae']),
        'numpy_kfold_r2': np.mean(numpy_metrics['r2']),
        'sklearn_kfold_mse': np.mean(sklearn_metrics['mse']),
        'sklearn_kfold_mae': np.mean(sklearn_metrics['mae']),
        'sklearn_kfold_r2': np.mean(sklearn_metrics['r2'])
    }

def main():
    print("Iniciando Pipeline de ML Retrospectivo...")
    from dataset import get_train_test_split
    X_train_full, X_test, y_train_full, y_test, feature_names = get_train_test_split(
        test_size=0.2, random_state=42
    )
    input_size = X_train_full.shape[1]
    
    params = {
        "learning_rate": 0.01,
        "epochs": 100,
        "hidden_sizes": (32, 16)
    }

    default_db = os.path.abspath(os.path.join(os.path.dirname(__file__), "mlflow.db")).replace("\\", "/")
    tracking_uri = os.getenv("MLFLOW_TRACKING_URI", f"sqlite:///{default_db}")
    mlflow.set_tracking_uri(tracking_uri)

    # Experimento explicitamente retrospectivo
    mlflow.set_experiment("MUNKA_MLP_Retrospective")

    with mlflow.start_run(run_name="NumPy_vs_Sklearn_Retrospective"):
        # Contexto metodológico
        mlflow.log_param("model_scope", MODEL_SCOPE)
        mlflow.log_param("analysis_moment", ANALYSIS_MOMENT)
        mlflow.log_param("uses_execution_evidence", USES_EXECUTION_EVIDENCE)
        mlflow.log_param("feature_set_name", FEATURE_SET_NAME)
        mlflow.log_param("target_variable", TARGET_NAME)

        # Parâmetros do treinamento
        mlflow.log_params(params)
        mlflow.log_param("input_features", input_size)
        mlflow.log_param("dataset_size", len(X_train_full) + len(X_test))
        mlflow.log_param("train_size", len(X_train_full))
        mlflow.log_param("test_size", len(X_test))

        # Contrato das features utilizadas
        feature_contract = {
            "model_scope": MODEL_SCOPE,
            "analysis_moment": ANALYSIS_MOMENT,
            "uses_execution_evidence": USES_EXECUTION_EVIDENCE,
            "feature_set_name": FEATURE_SET_NAME,
            "target": TARGET_NAME,
            "n_features": len(feature_names),
            "features": list(feature_names)
        }

        OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

        feature_contract_path = os.path.join(
            OUTPUT_DIR,
            "feature_contract.json"
        )

        with open(feature_contract_path,"w",encoding="utf-8") as f:
            json.dump(feature_contract, f, ensure_ascii=False, indent=4)

        mlflow.log_artifact(feature_contract_path)

        # 1. Avaliação K-Fold (Executada estritamente sobre a partição de Treinamento de 4.000 amostras: 3.200 treino / 800 val por fold)
        print("\n=== Executando 5-Fold Cross Validation no Conjunto de Treino (4.000 amostras) ===")
        kfold_results = run_kfold_evaluation(X_train_full, y_train_full, params)
        mlflow.log_metrics(kfold_results)
        
        print("\n=== Resultados Médios do K-Fold (Estabilidade) ===")
        print(f"NumPy   -> R2: {kfold_results['numpy_kfold_r2']:.4f} | MSE: {kfold_results['numpy_kfold_mse']:.4f}")
        print(f"Sklearn -> R2: {kfold_results['sklearn_kfold_r2']:.4f} | MSE: {kfold_results['sklearn_kfold_mse']:.4f}")
        
        # 2. Treinamento do Modelo Final (com validação interna de 3.200/800 e Teste Holdout isolado de 1.000)
        print("\n=== Treinando Modelo Final com Validação Interna e Teste Holdout Isolado ===")
        X_train, X_val, y_train, y_val = train_test_split(X_train_full, y_train_full, test_size=0.2, random_state=42)
        
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_val_scaled = scaler.transform(X_val)
        X_test_scaled = scaler.transform(X_test)
        
        # Treina NumPy Final
        numpy_model = NumPyMLPRegressor(input_size=input_size, hidden_sizes=params["hidden_sizes"], learning_rate=params["learning_rate"], epochs=params["epochs"])
        numpy_model.train(X_train_scaled, y_train, X_val=X_val_scaled, y_val=y_val, log_interval=50, mlflow_logger=mlflow.log_metric)
        
        # Treina Sklearn Final
        sklearn_model = train_sklearn_mlp(X_train_scaled, y_train, hidden_sizes=params["hidden_sizes"], learning_rate=params["learning_rate"], epochs=params["epochs"])
        
        # 3. Avaliação final no Holdout
        numpy_preds = numpy_model.predict(X_test_scaled)
        sklearn_preds = sklearn_model.predict(X_test_scaled).reshape(-1, 1)

        numpy_holdout_mse = mean_squared_error(y_test, numpy_preds)
        numpy_holdout_mae = mean_absolute_error(y_test, numpy_preds)
        numpy_holdout_rmse = np.sqrt(numpy_holdout_mse)
        numpy_holdout_r2 = r2_score(y_test, numpy_preds)

        sklearn_holdout_mse = mean_squared_error(y_test, sklearn_preds)
        sklearn_holdout_mae = mean_absolute_error(y_test, sklearn_preds)
        sklearn_holdout_rmse = np.sqrt(sklearn_holdout_mse)
        sklearn_holdout_r2 = r2_score(y_test, sklearn_preds)

        holdout_metrics = {
            "numpy_holdout_mse": numpy_holdout_mse,
            "numpy_holdout_mae": numpy_holdout_mae,
            "numpy_holdout_rmse": numpy_holdout_rmse,
            "numpy_holdout_r2": numpy_holdout_r2,
            "sklearn_holdout_mse": sklearn_holdout_mse,
            "sklearn_holdout_mae": sklearn_holdout_mae,
            "sklearn_holdout_rmse": sklearn_holdout_rmse,
            "sklearn_holdout_r2": sklearn_holdout_r2,
        }
        mlflow.log_metrics(holdout_metrics)

        print("\n=== Resultado Final no Holdout ===")
        print(
            f"NumPy   -> MAE: {numpy_holdout_mae:.4f} | "
            f"RMSE: {numpy_holdout_rmse:.4f} | "
            f"R2: {numpy_holdout_r2:.4f}"
        )
        print(
            f"Sklearn -> MAE: {sklearn_holdout_mae:.4f} | "
            f"RMSE: {sklearn_holdout_rmse:.4f} | "
            f"R2: {sklearn_holdout_r2:.4f}"
        )

        # 4. Gerando Gráficos
        
        # Resíduos
        residuals_path = os.path.join(OUTPUT_DIR, "residuals_comparison.png")
        plot_residuals(y_test, numpy_preds, sklearn_preds, save_path=residuals_path)
        mlflow.log_artifact(residuals_path)
        
        # Curvas de Aprendizado (Loss / Val Loss)
        # validation_scores_ do MLPRegressor corresponde ao score R²,
        # portanto não deve ser representado como MSE.
        sk_val_loss = None

        loss_curve_path = os.path.join(OUTPUT_DIR, "loss_validation_curve.png")
        plot_loss_curves(
            numpy_model.loss_history,
            numpy_model.val_loss_history,
            sklearn_model.loss_curve_,
            sk_val_loss,
            save_path=loss_curve_path
        )
        mlflow.log_artifact(loss_curve_path)
        
        # Permutation Importance
        print("\nCalculando Importância das Features (Isso pode demorar alguns segundos)...")
        feat_imp_np_path = os.path.join(OUTPUT_DIR, "feat_imp_numpy.png")
        plot_feature_importance(numpy_model, X_test_scaled, y_test.ravel(), feature_names, "NumPy MLP", feat_imp_np_path)
        mlflow.log_artifact(feat_imp_np_path)
        
        feat_imp_sk_path = os.path.join(OUTPUT_DIR, "feat_imp_sklearn.png")
        plot_feature_importance(sklearn_model, X_test_scaled, y_test.ravel(), feature_names, "Scikit-Learn MLP", feat_imp_sk_path)
        mlflow.log_artifact(feat_imp_sk_path)
        
        print("\nTreinamento retrospectivo finalizado! Artefatos gravados no MLflow.")

if __name__ == "__main__":
    main()

