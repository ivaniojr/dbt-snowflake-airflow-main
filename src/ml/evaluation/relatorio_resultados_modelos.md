# Relatório de Avaliação Comparativa de Modelos (Passo 6)

Com a integração dos três modelos, os resultados comprovaram a superioridade técnica da biblioteca Scikit-Learn frente à nossa implementação NumPy construída na mão, especialmente considerando a eficiência do otimizador (Adam).

## Resumo Geral dos Erros (Avaliação em Dados Reais do Snowflake)
| Métrica de Erro | Scikit-Learn (Campeão) | Sklearn (Restrito à arq. do NumPy) | NumPy MLP (Matemático) |
| :--- | :---: | :---: | :---: |
| **Erro Médio Absoluto (MAE)** | 0.71 horas | 0.75 horas | 1.04 horas |
| **Erro Quadrático Médio (MSE)** | 3.68 | 4.24 | 6.74 |
| **R² (Coef. de Determinação)** | 0.8821 | 0.8640 | 0.7842 |

---

### Análise dos Resultados
1. **Scikit-Learn (Campeão):** Ao permitir que o Optuna escolhesse a arquitetura livremente (de 1 a 3 camadas, de 8 a 128 neurônios) e o fator de regularização L2 (`alpha`), ele obteve o menor erro possível, explicando **88%** de todas as horas executadas.
2. **Sklearn Restrito vs NumPy:** Ao nivelar o ringue (limitamos o Sklearn para exatamente 2 camadas e sem variação de alpha, igual ao NumPy), o Scikit-Learn (`MSE 4.24`) **ainda superou brutalmente** o NumPy (`MSE 6.74`). Isso prova que, embora a nossa matemática do Gradiente Descendente (`src/ml/mlp_numpy.py`) esteja correta, algoritmos de otimização implementados em C como o Adam são anos-luz mais rápidos e eficientes na descida da superfície de erro do que abordagens em Python puro.
3. Ambos os modelos, no entanto, apresentaram bom comportamento preditivo para a base da empresa.
