# Análise Crítica e Melhorias do Projeto ML (MUNKA)

Com base nos resultados finais do *K-Fold Cross Validation* e nas arquiteturas utilizadas, aqui está uma análise técnica direta sobre os pontos fracos atuais e as melhorias sugeridas para elevar o projeto a um nível de produção corporativa real.

## ⚠️ 1. Críticas ao Estado Atual

### A. Limitações da Rede NumPy (R²: 0.67 vs 0.75)
A diferença de desempenho entre o modelo Scikit-Learn e a nossa rede manual em NumPy prova que uma MLP simples com *Gradient Descent* puro é ineficiente. A rede NumPy carece de otimizadores avançados (como **Adam** ou **RMSProp**), *Mini-batching* eficiente e *Momentum*, o que faz com que ela estacione em mínimos locais, resultando em um erro (MSE) maior.

### B. Distribuição de Erros e Outliers (MSE)
O uso exclusivo de MSE (Erro Quadrático Médio) pune severamente os *outliers*. Em Engenharia de Software, as horas de uma tarefa geralmente seguem uma **Cauda Longa** (muitas tarefas de 2-5h, algumas raras de 100h). Avaliar e treinar modelos em cima do MSE bruto enviesa a rede para tentar acertar as tarefas gigantes, prejudicando a precisão das pequenas.

### C. Hiperparâmetros Engessados (Hardcoded)
A rede foi treinada com valores fixos e arbitrários (`epochs=500`, `lr=0.01`, `camadas=(32,16)`). Não houve uma exploração de espaço de busca para garantir que essa seja a topologia matemática correta para o tipo de dado do Jira.

### D. Extração de Features (NLP Básico)
Embora a engenharia de dados em *dbt* tenha extraído *features* qualitativas via *RegEx* (qtd de bugs, integrações, imagens), essa abordagem descarta o contexto semântico puro dos textos (Descrição, Critérios de Aceite). 

---

## 🚀 2. Propostas de Melhoria (Roadmap Arquitetural)

### I. Transformação da Variável Alvo (Log-Transform)
- **Ação:** Aplicar `np.log1p(y)` (Logaritmo) nas `HORAS_EXECUTADAS` antes do treinamento e `np.expm1(y_pred)` na predição.
- **Por quê:** Isso "achata" a curva de distribuição, tratando as tarefas de 100 horas como desvios aceitáveis e permitindo que o modelo aprenda padrões reais sem ser distorcido por *outliers* absurdos. 

### II. Otimização Automatizada (Optuna + MLflow)
- **Ação:** Implementar a biblioteca **Optuna** acoplada ao MLflow. 
- **Por quê:** O script passaria a testar automaticamente dezenas de combinações de neurônios, taxas de aprendizado e funções de ativação, escolhendo o modelo "Campeão" de forma autônoma (Hyperparameter Optimization - HPO).

### III. Upgrade de Deep Learning (PyTorch)
- **Ação:** Substituir o experimento manual em *NumPy* por redes modernas em **PyTorch**.
- **Por quê:** Permite a aplicação de regularizações fortes (Dropout, Batch Normalization), Early Stopping robusto e uso de otimizadores AdamW.

### IV. NLP Avançado (Embeddings Vetoriais)
- **Ação:** Ao invés de usar *RegEx* no Snowflake, utilizar uma LLM leve (como *Sentence-BERT*) para transformar a "Descrição do Ticket" em um vetor denso (Embedding) de 384 dimensões.
- **Por quê:** A rede neural conseguiria literalmente "ler" a complexidade semântica da tarefa descrita em texto, aumentando o R² de `0.75` para algo próximo de `0.90+`.

### V. Deploy Contínuo (Model Registry & Airflow)
- **Ação:** Utilizar o MLflow Model Registry para salvar o modelo em formato `.pkl` ou `onnx`.
- **Por quê:** O Apache Airflow passaria não só a processar os dados (dbt), mas a servir como um pipeline de inferência contínua, extraindo os modelos do MLflow para predizer tarefas do Jira em tempo real, fechando o ciclo de MLOps.
