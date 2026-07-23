# Execução 04: Machine Learning (NumPy vs Framework) com Auditoria MLOps

## 🎯 Implementation Plan (Planejamento)
Com o Data Warehouse estabilizado e o Feature Engineering de NLP finalizado, o objetivo mudou para a ponta do ciclo de vida: **Ciência de Dados e Governança.**
- **Requisitos:**
  1. Construir uma Multi-Layer Perceptron (Rede Neural) pura em `NumPy` ("Hardcoded" matricial, do Zero).
  2. Construir o equivalente exato usando o framework `Scikit-Learn` para comparar métricas, topologias e prova real matemática.
  3. Auditar todas essas etapas para rastreabilidade (Salvar Hiperparâmetros, Logs Parciais de Loss e Artefatos).
- **Proposta:**
  1. Implementar um fluxo MLOps utilizando o padrão da indústria **MLflow**.
  2. Estruturar a pasta `src/ml` contendo os datasets, as classes customizadas da rede NumPy (Forward propagation e cálculo MSE puro), e a classe do Scikit.
  3. Criar uma interface conectora para baixar a tabela `ML_TAREFA_FEATURES` usando o driver oficial do Snowflake.

---

## ✅ Walkthrough (O que foi entregue)
A auditoria e o treinamento superaram as expectativas!

1. O script de Extração e Separação de Dados foi capaz de puxar o dataset e tratar o *Data Leakage* aplicando o `StandardScaler` de forma agnóstica exclusivamente na base de treinamento (`fit_transform` em Treino, apenas `transform` no Teste).
2. A Rede NumPy construída do zero convergiu quase identicamente à implementação monstruosa do `Scikit-Learn`! Obtenção do Erro Médio Quadrático (MSE): **1.01 vs 1.00**, validando a nossa matemática.
3. **Auditoria Inviolável**: Configuramos o URI do MLflow para rodar num banco de dados leve local (`sqlite:///mlflow.db`). Isso permitiu que o modelo NumPy interagisse com o banco durante as épocas do seu treinamento para registrar o gradiente descendo (`loss`). 
4. A Interface Web do MLflow pode ser consultada a qualquer momento pelos engenheiros auditores para checar a taxa de aprendizado e ver o gráfico comparativo em PNG que foi gerado nativamente pelo script e anexado ao tracking.
