import os
import mlflow
import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from sklearn.model_selection import KFold, train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.inspection import permutation_importance
from dataset import get_raw_dataset
from mlp_numpy import NumPyMLPRegressor
from mlp_sklearn import train_sklearn_mlp

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

def plot_feature_importance(model, X_test, y_test, feature_names, title, save_path):
    result = permutation_importance(model, X_test, y_test, n_repeats=10, random_state=42, scoring='neg_mean_squared_error')
    sorted_idx = result.importances_mean.argsort()

    plt.figure(figsize=(10, 6))
    plt.boxplot(
        result.importances[sorted_idx].T,
        vert=False,
        labels=np.array(feature_names)[sorted_idx],
    )
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
        
        # Scaling Isolado por Fold (Prevenção Absoluta de Data Leakage)
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
    print("Iniciando Pipeline de ML Avançado...")
    X, y, feature_names = get_raw_dataset()
    input_size = X.shape[1]
    
    params = {
        "learning_rate": 0.01,
        "epochs": 500,
        "hidden_sizes": (32, 16)
    }

    mlflow.set_tracking_uri("sqlite:///mlflow.db")
    mlflow.set_experiment("Auditoria_MLP_Tarefas")

    with mlflow.start_run(run_name="NumPy_vs_Sklearn_Advanced"):
        mlflow.log_params(params)
        mlflow.log_param("input_features", input_size)
        mlflow.log_param("dataset_size", len(X))

        # 1. Avaliação K-Fold
        print("\n=== Executando 5-Fold Cross Validation ===")
        kfold_results = run_kfold_evaluation(X, y, params)
        mlflow.log_metrics(kfold_results)
        
        print("\n=== Resultados Médios do K-Fold (Estabilidade) ===")
        print(f"NumPy   -> R2: {kfold_results['numpy_kfold_r2']:.4f} | MSE: {kfold_results['numpy_kfold_mse']:.4f}")
        print(f"Sklearn -> R2: {kfold_results['sklearn_kfold_r2']:.4f} | MSE: {kfold_results['sklearn_kfold_mse']:.4f}")
        
        # 2. Treinamento do Modelo Final (com gráfico de Validação e Permutation Importance)
        print("\n=== Treinando Modelo Final para Gráficos de Interpretabilidade ===")
        X_train_full, X_test, y_train_full, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
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
        
        # 3. Gerando Gráficos
        numpy_preds = numpy_model.predict(X_test_scaled)
        sklearn_preds = sklearn_model.predict(X_test_scaled).reshape(-1, 1)
        
        # Resíduos
        plot_residuals(y_test, numpy_preds, sklearn_preds, save_path="residuals_comparison.png")
        mlflow.log_artifact("residuals_comparison.png")
        
        # Curvas de Aprendizado (Loss / Val Loss)
        # sklearn_model.validation_scores_ não é diretamente a Loss (MSE), é o score invertido, mas serve para ver convergência.
        # Iremos omitir o sklearn validation na curva se não estiver em escala, mas adicionaremos se presente.
        sk_val_loss = getattr(sklearn_model, 'validation_scores_', None)
        if sk_val_loss is not None:
             # sklearn salva como R2 score no validation_scores_, inverta ou multiplique
             sk_val_loss = [-x for x in sk_val_loss]
             
        plot_loss_curves(numpy_model.loss_history, numpy_model.val_loss_history, sklearn_model.loss_curve_, sk_val_loss, save_path="loss_validation_curve.png")
        mlflow.log_artifact("loss_validation_curve.png")
        
        # Permutation Importance
        print("\nCalculando Importância das Features (Isso pode demorar alguns segundos)...")
        plot_feature_importance(numpy_model, X_test_scaled, y_test, feature_names, "NumPy MLP", "feat_imp_numpy.png")
        mlflow.log_artifact("feat_imp_numpy.png")
        
        plot_feature_importance(sklearn_model, X_test_scaled, y_test.ravel(), feature_names, "Scikit-Learn MLP", "feat_imp_sklearn.png")
        mlflow.log_artifact("feat_imp_sklearn.png")
        
        print("\nTreinamento Avançado finalizado! Artefatos gravados no MLflow.")

if __name__ == "__main__":
    main()
