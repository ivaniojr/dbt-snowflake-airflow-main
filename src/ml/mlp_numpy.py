import numpy as np

class NumPyMLPRegressor:
    """
    Multilayer Perceptron Hardcoded em NumPy.
    Arquitetura: Input -> Oculta 1 (ReLU) -> Oculta 2 (ReLU) -> Saída (Linear)
    Loss: Mean Squared Error (MSE)
    """
    def __init__(self, input_size, hidden_sizes=(32, 16), learning_rate=0.01, epochs=1000):
        self.lr = learning_rate
        self.epochs = epochs
        
        # He Initialization para pesos (ideal para ReLU)
        self.W1 = np.random.randn(input_size, hidden_sizes[0]) * np.sqrt(2. / input_size)
        self.b1 = np.zeros((1, hidden_sizes[0]))
        
        self.W2 = np.random.randn(hidden_sizes[0], hidden_sizes[1]) * np.sqrt(2. / hidden_sizes[0])
        self.b2 = np.zeros((1, hidden_sizes[1]))
        
        self.W3 = np.random.randn(hidden_sizes[1], 1) * np.sqrt(2. / hidden_sizes[1])
        self.b3 = np.zeros((1, 1))
        
        self.loss_history = []
        self.val_loss_history = []
        
    def relu(self, Z):
        return np.maximum(0, Z)
    
    def relu_derivative(self, Z):
        return (Z > 0).astype(float)
    
    def forward(self, X):
        # Camada 1
        self.Z1 = np.dot(X, self.W1) + self.b1
        self.A1 = self.relu(self.Z1)
        
        # Camada 2
        self.Z2 = np.dot(self.A1, self.W2) + self.b2
        self.A2 = self.relu(self.Z2)
        
        # Camada Saída (Linear)
        self.Z3 = np.dot(self.A2, self.W3) + self.b3
        self.A3 = self.Z3 # Sem ativação, pois é regressão
        return self.A3
    
    def backward(self, X, y):
        m = X.shape[0]
        
        # Derivada da Loss (MSE)
        dZ3 = (self.A3 - y) # Erro na saída
        
        dW3 = (1/m) * np.dot(self.A2.T, dZ3)
        db3 = (1/m) * np.sum(dZ3, axis=0, keepdims=True)
        
        # Retropropagação para Camada 2
        dA2 = np.dot(dZ3, self.W3.T)
        dZ2 = dA2 * self.relu_derivative(self.Z2)
        dW2 = (1/m) * np.dot(self.A1.T, dZ2)
        db2 = (1/m) * np.sum(dZ2, axis=0, keepdims=True)
        
        # Retropropagação para Camada 1
        dA1 = np.dot(dZ2, self.W2.T)
        dZ1 = dA1 * self.relu_derivative(self.Z1)
        dW1 = (1/m) * np.dot(X.T, dZ1)
        db1 = (1/m) * np.sum(dZ1, axis=0, keepdims=True)
        
        # Atualização dos Pesos (Gradient Descent)
        self.W3 -= self.lr * dW3
        self.b3 -= self.lr * db3
        self.W2 -= self.lr * dW2
        self.b2 -= self.lr * db2
        self.W1 -= self.lr * dW1
        self.b1 -= self.lr * db1
        
    def train(self, X, y, X_val=None, y_val=None, log_interval=100, mlflow_logger=None):
        for epoch in range(self.epochs):
            predictions = self.forward(X)
            self.backward(X, y)
            
            mse = np.mean((predictions - y) ** 2)
            self.loss_history.append(mse)
            
            val_mse = None
            if X_val is not None and y_val is not None:
                val_preds = self.forward(X_val)
                val_mse = np.mean((val_preds - y_val) ** 2)
                self.val_loss_history.append(val_mse)
            
            if epoch % log_interval == 0:
                msg = f"NumPy MLP - Epoch {epoch}/{self.epochs} - Train MSE: {mse:.4f}"
                if val_mse is not None:
                    msg += f" - Val MSE: {val_mse:.4f}"
                print(msg)
                
                if mlflow_logger:
                    mlflow_logger("numpy_train_loss", mse, step=epoch)
                    if val_mse is not None:
                        mlflow_logger("numpy_val_loss", val_mse, step=epoch)
                    
    def predict(self, X):
        return self.forward(X)

    # ──────────────────────────────────────────────
    # Persistencia de Pesos
    # ──────────────────────────────────────────────
    def save_weights(self, path="numpy_model_weights.npz"):
        """
        Salva todos os pesos, biases e hiperparametros em um arquivo .npz.

        Uso:
            model.save_weights("numpy_model_weights.npz")
        """
        np.savez(
            path,
            W1=self.W1, b1=self.b1,
            W2=self.W2, b2=self.b2,
            W3=self.W3, b3=self.b3,
            lr=np.array([self.lr]),
            epochs=np.array([self.epochs]),
            hidden_sizes=np.array([self.W1.shape[1], self.W2.shape[1]]),
        )
        print(f"Pesos NumPy salvos em: {path}")

    def load_weights(self, path="numpy_model_weights.npz"):
        """
        Carrega pesos de um .npz salvo por save_weights().
        Nao e necessario retreinar - basta chamar predict() depois.

        Uso:
            model = NumPyMLPRegressor(input_size=10, hidden_sizes=(64, 32))
            model.load_weights("numpy_model_weights.npz")
            preds = model.predict(X_novo)
        """
        data = np.load(path)
        self.W1, self.b1 = data["W1"], data["b1"]
        self.W2, self.b2 = data["W2"], data["b2"]
        self.W3, self.b3 = data["W3"], data["b3"]
        self.lr     = float(data["lr"][0])
        self.epochs = int(data["epochs"][0])
        print(f"Pesos NumPy carregados de: {path}")

    @classmethod
    def from_weights(cls, path="numpy_model_weights.npz"):
        """
        Factory method: reconstroi o modelo completo a partir de um .npz.
        Nao e necessario informar input_size ou hidden_sizes manualmente.

        Uso:
            model = NumPyMLPRegressor.from_weights("numpy_model_weights.npz")
            preds = model.predict(X_novo)
        """
        data = np.load(path)
        input_size   = int(data["W1"].shape[0])
        hidden_sizes = tuple(int(x) for x in data["hidden_sizes"])
        lr           = float(data["lr"][0])
        epochs       = int(data["epochs"][0])

        instance = cls(input_size=input_size, hidden_sizes=hidden_sizes,
                       learning_rate=lr, epochs=epochs)
        instance.W1, instance.b1 = data["W1"], data["b1"]
        instance.W2, instance.b2 = data["W2"], data["b2"]
        instance.W3, instance.b3 = data["W3"], data["b3"]
        print(f"Modelo NumPy reconstituido de: {path}")
        print(f"  input_size={input_size}  hidden={hidden_sizes}  lr={lr}  epochs={epochs}")
        return instance
