from sklearn.neural_network import MLPRegressor
import numpy as np

def train_sklearn_mlp(X_train, y_train, hidden_sizes=(32, 16), learning_rate=0.01, epochs=1000, n_iter_no_change=15):
    """
    Treina e retorna um modelo MLP do Scikit-Learn parametrizado para 
    imitar a nossa versão Hardcoded do NumPy.
    """
    model = MLPRegressor(
        hidden_layer_sizes=hidden_sizes,
        activation='relu',
        solver='sgd',
        learning_rate_init=learning_rate,
        max_iter=epochs,
        random_state=42,
        batch_size=min(200, X_train.shape[0]), # Batch GD behavior similar to our implementation or SGD
        momentum=0.0, # Sem momentum para ficar idêntico ao nosso NumPy simples
        early_stopping=True, # Ativa a separação de Validação Interna
        validation_fraction=0.2, # 20% para validação do loss
        n_iter_no_change=n_iter_no_change # Early stopping quando o loss estagnar
    )
    
    # Scikit-learn espera vetor 1D para o y
    y_train_1d = y_train.ravel()
    
    model.fit(X_train, y_train_1d)
    return model
