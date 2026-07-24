# Execução 07: Implementação de Otimização de Hiperparâmetros (HPO)

Este plano descreve como introduziremos o **Optuna**, a biblioteca estado-da-arte de HPO, para testar combinações de hiperparâmetros (learning rate, hidden sizes, épocas) em busca do modelo ótimo.

## Decisão de Arquitetura Aprovada
- O pacote `optuna` será instalado no ambiente virtual.
- Iremos criar um arquivo dedicado `src/ml/hpo.py` que otimizará **ambos os modelos (Scikit-Learn e NumPy)**.
- Para a Rede Neural feita à mão em NumPy, como a execução iterativa matemática pode ser demorada em CPU sequencial pura, a otimização rodará um número fixo de tentativas (*Trials*) para evidenciar cientificamente que a arquitetura também pode ser escalada.

## Proposta
### 1. Novo Arquivo de HPO (`src/ml/hpo.py`)
- O script vai conter duas *Objectives Functions* independentes.
- **Objective 1:** Treina o `NumPyMLPRegressor` iterando sobre a taxa de aprendizado (`learning_rate`) e tamanho/qtd de camadas (`hidden_sizes`).
- **Objective 2:** Treina o `MLPRegressor` do Scikit-Learn iterando os mesmos parâmetros e talvez `alpha` (regularização).
- **Registro no MLflow:** Ambos gerarão log automatizado das métricas nas suas respectivas *runs*, para que o painel mostre os gráficos de coordenadas paralelas identificando a melhor arquitetura de ambas as frentes.

## Critério de Verificação
O arquivo gerará um *Study* do Optuna e imprimirá no terminal qual foi a Topologia exata (ex: 64 neurônios na primeira camada, 16 na segunda, lr=0.005) que extraiu a menor taxa de Erro (MSE).
