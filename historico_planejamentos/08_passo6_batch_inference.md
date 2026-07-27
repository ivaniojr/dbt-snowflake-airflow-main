# Plano de Implementação: Passo 6 (Inferência em Lote)

Este plano descreve a arquitetura e a estratégia para fechar o ciclo do MLOps: pegar o modelo treinado (Passo 5) e utilizá-lo no mundo real para prever as horas de tarefas novas (Passo 6).

## User Review Required

> [!WARNING]
> **Persistência do Scaler (Normalizador)**
> Atualmente, o script `train_best.py` salva o modelo final (`sklearn_best_model.joblib`), mas **esquece de salvar o `StandardScaler`** usado para normalizar os dados de treino. Sem esse *scaler*, é impossível normalizar os dados novos de forma idêntica e o modelo erraria brutalmente as previsões. Precisamos editar o Passo 5 para corrigir isso.

## Proposed Changes

---

### Machine Learning Scripts

#### [MODIFY] [train_best.py](file:///home/ivanio/IFG/Trabalho_Modulo2/dbt-snowflake-airflow-main/dbt-snowflake-airflow-main/src/ml/train_best.py)
- Importar e usar `joblib` para salvar também o objeto `scaler_f` após a transformação dos dados de treinamento final.
- O arquivo gerado será `scaler.joblib` e será logado no MLflow como artefato, para que a Inferência tenha acesso exato aos desvios-padrões e médias de treino.

#### [NEW] [batch_inference.py](file:///home/ivanio/IFG/Trabalho_Modulo2/dbt-snowflake-airflow-main/dbt-snowflake-airflow-main/src/ml/batch_inference.py)
- **Função:** Script responsável por conectar ao Snowflake e ler os dados de "Novas Tarefas" (ou gerar mock data de tarefas sem `HORAS_EXECUTADAS` preenchidas caso não haja conexão com o DB real).
- **Processamento:** 
  1. Carregar `scaler.joblib` e aplicar nas *features* das novas tarefas.
  2. Carregar o modelo campeão `sklearn_best_model.joblib` (ou extraí-lo do MLflow Model Registry).
  3. Fazer o `.predict()`.
- **Destino:** Salvar os resultados em um CSV local `novas_previsoes.csv` e, opcionalmente, rodar um `INSERT` / `COPY` no Snowflake para uma tabela `DRAGON_DB.MUNKA_ML.PREVISOES_TAREFAS`.

---

### Airflow Orquestração

#### [NEW] [passo6_batch_inference.py](file:///home/ivanio/IFG/Trabalho_Modulo2/dbt-snowflake-airflow-main/dbt-snowflake-airflow-main/airflow/dags/passo6_batch_inference.py)
- DAG responsável por rodar a inferência.
- **Tarefas (Tasks):**
  1. `check_model_exists`: Usa Bash/Python para verificar se os arquivos `.joblib` estão disponíveis na pasta.
  2. `run_batch_inference`: Roda o script `python src/ml/batch_inference.py` nativamente dentro do container Docker.
- **Agendamento:** Pode ser diário (`@daily`) para gerar um *report* toda madrugada com as tarefas pendentes da Sprint atual.

## Verification Plan

### Testes Manuais & Automatizados
1. **Regerar Artefatos:** Executar a DAG do Passo 5 no Airflow para que o novo `scaler.joblib` seja gerado e persistido corretamente.
2. **Executar Passo 6:** Ativar a nova DAG `passo6_batch_inference` no Airflow (localhost:8081).
3. **Validação do Output:** Checar na raiz do projeto se o arquivo de resultados `novas_previsoes.csv` foi gerado e se as previsões fazem sentido matemático (não contêm números bizarros negativos, garantindo que o `scaler` funcionou).
