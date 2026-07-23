import mlflow
import matplotlib.pyplot as plt
from sklearn.metrics import mean_squared_error, mean_absolute_error
from dataset import get_processed_dataset
from mlp_numpy import NumPyMLPRegressor
from mlp_sklearn import train_sklearn_mlp
import os

def main():
    print("Iniciando Pipeline de ML...")
    # Carrega e divide os dados normalizados
    X_train, X_test, y_train, y_test, scaler_y = get_processed_dataset()
    input_size = X_train.shape[1]
    
    # Hiperparâmetros
    params = {
        "learning_rate": 0.01,
        "epochs": 500,
        "hidden_sizes": (32, 16)
    }

    # Configurando o tracking do MLflow via banco de dados relacional (SQLite) para maior governança
    mlflow.set_tracking_uri("sqlite:///mlflow.db")
    mlflow.set_experiment("Auditoria_MLP_Tarefas")

    with mlflow.start_run(run_name="NumPy_vs_Sklearn"):
        # 1. Log dos Hiperparâmetros para Auditoria
        mlflow.log_params(params)
        mlflow.log_param("input_features", input_size)
        mlflow.log_param("dataset_size", len(X_train) + len(X_test))

        print(f"Treinando NumPy MLP (Entradas: {input_size})...")
        numpy_model = NumPyMLPRegressor(
            input_size=input_size, 
            hidden_sizes=params["hidden_sizes"], 
            learning_rate=params["learning_rate"], 
            epochs=params["epochs"]
        )
        
        # Treinamento do modelo numpy injetando o log do MLflow
        numpy_model.train(X_train, y_train, log_interval=50, mlflow_logger=mlflow.log_metric)

        print("\nTreinando Scikit-Learn MLP...")
        sklearn_model = train_sklearn_mlp(
            X_train, y_train, 
            hidden_sizes=params["hidden_sizes"], 
            learning_rate=params["learning_rate"], 
            epochs=params["epochs"]
        )
        
        # 2. Previsão e Avaliação (Test Set)
        numpy_preds = numpy_model.predict(X_test)
        sklearn_preds = sklearn_model.predict(X_test).reshape(-1, 1)
        
        numpy_mse = mean_squared_error(y_test, numpy_preds)
        numpy_mae = mean_absolute_error(y_test, numpy_preds)
        
        sklearn_mse = mean_squared_error(y_test, sklearn_preds)
        sklearn_mae = mean_absolute_error(y_test, sklearn_preds)

        print("\n--- Resultados Finais (Teste) ---")
        print(f"NumPy MLP   -> MSE: {numpy_mse:.4f}, MAE: {numpy_mae:.4f}")
        print(f"Sklearn MLP -> MSE: {sklearn_mse:.4f}, MAE: {sklearn_mae:.4f}")

        # 3. Log das Métricas Finais no MLflow
        mlflow.log_metrics({
            "numpy_test_mse": numpy_mse,
            "numpy_test_mae": numpy_mae,
            "sklearn_test_mse": sklearn_mse,
            "sklearn_test_mae": sklearn_mae
        })

        # 4. Gerando Gráfico de Perda (Loss) para Auditoria Visual
        plt.figure(figsize=(10, 5))
        plt.plot(numpy_model.loss_history, label='NumPy MLP Training Loss')
        plt.plot(sklearn_model.loss_curve_, label='Scikit-Learn Training Loss')
        plt.title('Curva de Aprendizado (MSE Loss)')
        plt.xlabel('Época (Epoch)')
        plt.ylabel('Erro Quadrático Médio (MSE)')
        plt.legend()
        plt.grid(True)
        
        plot_path = "loss_comparison.png"
        plt.savefig(plot_path)
        plt.close()
        
        # Salva o gráfico no MLflow como artefato
        mlflow.log_artifact(plot_path)
        
        print(f"\nTreinamento finalizado! Dados auditados salvos no MLflow.")
        print("Para visualizar a interface de auditoria, rode no terminal: mlflow ui")

if __name__ == "__main__":
    main()
