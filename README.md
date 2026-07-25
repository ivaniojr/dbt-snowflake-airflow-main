# Engenharia de Dados com Apache Airflow, Snowflake e dbt (Projeto MUNKA)

Repositório do projeto "Engenharia de Dados com Apache Airflow, Snowflake e dbt", focado na construção de um Data Warehouse Moderno com Arquitetura Medallion (Bronze/Raw, Silver/Staging, Gold/Marts) para suportar Business Intelligence e Machine Learning.

## Arquitetura Solução
A arquitetura do projeto foi desenhada para extrair dados brutos, limpá-nos e transformá-los em estruturas analíticas (Star Schema e Wide Tables para ML):

- **RAW (`MUNKA_RAW`)**: Ingestão bruta dos dados. 
- **STAGING (`MUNKA_STG`)**: Limpeza, deduplicação (`QUALIFY`) e tratamento de strings.
- **INTERMEDIATE (`MUNKA_INT`)**: Parser avançado usando Expressões Regulares (RegEx) no Snowflake para extração de features textuais e HTML (contagem de links, imagens, commits, códigos).
- **GOLD/MARTS (`MUNKA_GOLD` e `MUNKA_ML`)**: Modelagem Dimensional Estrela (Fatos e Dimensões) e Tabelões Desnormalizados (Wide Tables) prontos para treinamento de modelos de Machine Learning (ex: previsão de horas de tarefas).

## Orquestração (DAGs no Airflow)
O pipeline de dados é automatizado no Apache Airflow, dividido em passos sequenciais:
1. `passo1_munka_dbt_create_raw_tables`: Criação do DDL inicial da RAW.
2. `passo2_s3_to_snowflake_munka_raw`: Ingestão de dados do S3 para o Snowflake.
3. `passo3_munka_dbt_create_stg`: Executa a camada Silver/Staging no dbt (`dbt run --select staging`).
4. `passo4_munka_dbt_run_marts`: Executa a modelagem dimensional Gold e ML no dbt (`dbt run --select intermediate marts`).

## Planejamentos Executados no Projeto
Durante a evolução deste repositório, executamos marcos arquiteturais importantes:
- **Migração do SQL Legado para dbt**: Criação de scripts automatizados em Python (`parse_stg.py` e `parse_marts.py`) para dissecar monólitos SQL de mais de 700 linhas, convertendo-os em quase 90 modelos dbt modulares, mantendo a linhagem de dados perfeita.
- **Feature Engineering Textual**: Desmembramento de um campo complexo de HTML (`evidencias`) em métricas quantitativas (quantidade de códigos, links, arquivos) utilizando `REGEXP` no Snowflake para alimentar modelos preditivos de Data Science.
- **Governança e Qualidade**: Implementação automática de testes `unique` e `not_null` via `schema.yml` para garantir que não existam duplicações nas chaves artificiais (Surrogate Keys) da camada Ouro.
- **Rastreamento de Experimentos ML (MLflow)**: Integração do MLflow para registrar automaticamente métricas, parâmetros e artefatos de cada treinamento dos modelos MLP (Scikit-Learn e NumPy), permitindo auditoria e comparação histórica dos experimentos.
- **Otimização de Hiperparâmetros (Optuna/HPO)**: Implementação de busca automática de hiperparâmetros (learning rate, arquitetura de camadas, regularização) para ambos os modelos MLP usando o framework Optuna, com rastreamento completo no MLflow.

---

## Introdução

### Snowflake
O Snowflake, uma plataforma de Data Cloud, fornece uma solução inovadora que simplifica pipelines de dados, permitindo que você foque mais em dados e análises do que na gestão de infraestrutura. Ele simplifica o armazenamento, processamento e computação quando comparado a soluções tradicionais.

### Airflow
O Apache Airflow é uma plataforma de gerenciamento de fluxo de trabalho de código aberto que permite criar e gerenciar pipelines de dados de forma eficiente usando grafos acíclicos direcionados (DAGs) de tarefas.

### Docker
O Docker é utilizado neste projeto para executar o Apache Airflow em um contêiner, tornando a configuração e a portabilidade mais fáceis.

### AWS S3 (Amazon Simple Storage Service)
O AWS S3 é o **repositório de origem dos dados brutos** do projeto. Os arquivos `.csv` exportados do sistema legado (MUNKA) são armazenados em um bucket S3 e servem como ponto de partida do pipeline. O Airflow, via DAG `passo2_s3_to_snowflake_munka_raw`, acessa o bucket usando credenciais AWS configuradas e executa um comando `COPY INTO` no Snowflake para ingerir os arquivos diretamente na camada RAW — sem necessidade de mover os arquivos manualmente ou manter um servidor de arquivos local.

### dbt (data build tool)
O dbt é uma ferramenta de linha de comando de código aberto que permite que analistas e engenheiros de dados transformem dados em seu data warehouse de forma mais eficiente. Ele segue uma abordagem modular e versionada para transformação de dados.


### MLflow
O MLflow é uma plataforma open-source de **rastreamento de experimentos de Machine Learning**. Neste projeto, ele é utilizado para registrar automaticamente, a cada execução de treinamento dos modelos MLP (Scikit-Learn e NumPy), as métricas de performance (MSE, R²), os hiperparâmetros utilizados e os artefatos gerados (gráficos de loss, feature importance). Isso garante auditabilidade completa e permite comparar visualmente qual configuração produziu o melhor modelo.

### Optuna (HPO — Hyperparameter Optimization)
O Optuna é uma biblioteca de **otimização automática de hiperparâmetros** (HPO) estado-da-arte. No projeto, ele é empregado para buscar sistematicamente a melhor combinação de learning rate, tamanho e número de camadas ocultas e fator de regularização (`alpha`) para ambos os modelos MLP, sem necessidade de busca manual por tentativa e erro. Cada tentativa (*trial*) do Optuna é automaticamente rastreada no MLflow, gerando evidências científicas reproduzíveis da escolha arquitetural final.

## Requisitos Prévios

O projeto requer os seguintes elementos:
* Docker
* Python >=3
* Uma conta Snowflake.
* Um usuário Snowflake com permissões necessárias, incluindo a capacidade de criar objetos no banco de dados GIRAFFE_DB.

### Como criar um conta no Snowflake?
https://www.snowflake.com/en/emea/

### Como criar o user com permissões no Snowflake?
Entre na pasta `scripts` e use o arquivo `00_setup_controle.sql` como base.

### Como configurar a conexão com AWS S3?
A ingestão de dados brutos (`passo2_s3_to_snowflake_munka_raw`) copia os arquivos `.csv` de um bucket S3 para o Snowflake. Para que funcione:
1. Suba os arquivos CSV gerados do sistema legado para o seu bucket S3 (ex: `munka-dev-070980587239-us-east-2`). O nome dos arquivos deve estar em minúsculo (ex: `ab_user.csv`).
2. Vá até a interface do Airflow: **Admin** -> **Connections**.
3. Edite ou crie a conexão com `Conn Id: aws_default`.
4. Defina o tipo de conexão (`Conn Type`) como **Amazon Web Services**.
5. Em **Login**, insira o seu `AWS Access Key ID`.
6. Em **Password**, insira o seu `AWS Secret Access Key`.
*O Airflow injetará essas credenciais automaticamente no comando `COPY INTO` disparado no Snowflake.*

## Como utilizar o projeto?
Faça clone com o comando:
```bash
git clone https://github.com/ivaniojr/dbt-snowflake-airflow-main.git
```
Entre na pasta do projeto
```bash
cd dbt-snowflake-airflow-main
```
Rode o container do Airflow com o comando:
```bash
cd airflow
docker compose up -d
```

## Como acessar o Airflow?
Digite no navegador:
```
localhost:8081
```

## Credenciais do Airlflow
**username:** airflow
**password:** airflow

---

## Como rodar localmente o dbt?
Caso queira testar o dbt fora do Airflow (para desenvolvimento local):

### Crie o ambiente virtual
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Como configurar o dbt para conectar no Snowflake?
Certifique-se de configurar seu `profiles.yml` (normalmente em `~/.dbt/profiles.yml`) apontando para o seu account, user e role do Snowflake, usando o target `dev` ou `prod`.

Para verificar se a conexão está ok, use o comando:
```bash
cd src/dbt
dbt debug
```

Para compilar os 90 modelos:
```bash
dbt compile
```

---

## Machine Learning — MLflow e HPO

### Objetivo
A camada de Machine Learning deste projeto vai além da Engenharia de Dados: ela utiliza os dados transformados pelo dbt na camada `MUNKA_ML` do Snowflake para treinar redes neurais (MLP) capazes de **prever o tempo de execução de tarefas** com base em features textuais e quantitativas extraídas dos projetos.

O **MLflow** garante rastreabilidade total de cada experimento. O **Optuna** automatiza a busca pelos melhores hiperparâmetros, eliminando o empirismo manual.

### Como ativar o servidor MLflow (UI de Experimentos)

O MLflow armazena todos os experimentos localmente em `src/ml/mlflow.db` (SQLite). Para visualizar os gráficos e comparar runs:

```bash
# 1. Ative o ambiente virtual
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # Linux/Mac

# 2. Instale as dependências
pip install -r requirements.txt

# 3. Inicie o servidor MLflow (dentro da pasta src/ml/)
cd src/ml
mlflow ui --backend-store-uri sqlite:///mlflow.db --port 5000
```

Acesse no navegador:
```
http://localhost:5000
```

Você verá os experimentos `Auditoria_MLP_Baseline` e `Auditoria_MLP_HPO` com todos os trials registrados, incluindo gráficos de coordenadas paralelas para identificar visualmente a melhor topologia.

### Como rodar o treinamento baseline (sem HPO)

O script `train.py` executa o treinamento completo com validação cruzada 5-Fold para os dois modelos e já loga tudo no MLflow:

```bash
cd src/ml
python train.py
```

**Saída esperada:** métricas de MSE e R² por fold, curva de loss, gráficos de feature importance e residuais.

### Como rodar a Otimização de Hiperparâmetros (HPO)

O script `hpo.py` usa o **Optuna** para buscar automaticamente a melhor combinação de hiperparâmetros para ambos os modelos MLP, rodando **300 épocas** por trial para uma comparação justa:

```bash
cd src/ml
python hpo.py
```

**O que o HPO faz:**
| Modelo | Trials | Épocas/Trial | Hiperparâmetros Otimizados |
|--------|--------|--------------|---------------------------|
| Scikit-Learn MLP | 15 | 300 | `learning_rate`, `hidden_sizes` (1–3 camadas), `alpha` |
| NumPy MLP (matemático) | 10 | 300 | `learning_rate`, `n_units_l1`, `n_units_l2` |

**Saída ao final:** arquivo `src/ml/hpo_results.json` com o sumário dos melhores hiperparâmetros encontrados e a melhoria percentual vs. baseline, e todos os trials registrados no MLflow.

```json
// Exemplo de saída em hpo_results.json
{
  "epochs_per_trial": 300,
  "sklearn": {
    "best_val_mse": 3.812,
    "best_params": { "learning_rate": 0.0023, "n_layers": 2, ... },
    "improvement_vs_baseline_pct": +16.3
  },
  "numpy": {
    "best_val_mse": 4.951,
    "best_params": { "learning_rate": 0.005, "n_units_l1": 64, ... },
    "improvement_vs_baseline_pct": +18.0
  }
}
```

> **Nota:** O MLflow deve estar ativo (passo anterior) para que os trials sejam registrados na UI durante o HPO.

---

## Conclusão
Este projeto entrega uma solução end-to-end de Engenharia de Dados e Machine Learning: os dados fluem do S3 para a camada RAW no Snowflake, são limpos e enriquecidos pelo dbt nas camadas Staging e Gold, e finalmente alimentam modelos preditivos MLP rastreados pelo MLflow e otimizados pelo Optuna — com auditabilidade completa de ponta a ponta.

## Developer
| Desenvolvedor      | LinkedIn                                   | Email                        | Portfólio                              |
|--------------------|--------------------------------------------|------------------------------|----------------------------------------|
| Ivanio Junior      |                                            |                              |                                        |
| Robson             |                                            |                              |                                        |
