# 🚀 Roteiro de Implantação e Guia de Conexões — Projeto MUNKA

Guia técnico completo de implantação, provisionamento e configuração da infraestrutura moderna de dados e Machine Learning do **Projeto MUNKA (IFG)**.

Este documento consolida todos os parâmetros de conexão, configurações da nuvem **AWS**, credenciais do **Snowflake Data Cloud**, orquestração no **Apache Airflow**, transformações no **dbt Core**, experimentos no **MLflow** e visualizações no **Metabase**.

---

## 📑 Sumário

1. [Visão Geral da Arquitetura e Componentes](#1-visão-geral-da-arquitetura-e-componentes)
2. [Pré-Requisitos e Softwares Necessários](#2-pré-requisitos-e-softwares-necessários)
3. [Matriz Centralizada de Credenciais e Variáveis (`.env`)](#3-matriz-centralizada-de-credenciais-e-variáveis-env)
4. [Provisionamento e Configuração na Nuvem AWS](#4-provisionamento-e-configuração-na-nuvem-aws)
5. [Configuração e Segurança no Snowflake](#5-configuração-e-segurança-no-snowflake)
6. [Implantação da Stack Local com Docker e Airflow](#6-implantação-da-stack-local-com-docker-e-airflow)
7. [Execução e Validação do Pipeline de Dados (dbt Core)](#7-execução-e-validação-do-pipeline-de-dados-dbt-core)
8. [Ambiente de Machine Learning, HPO e MLflow](#8-ambiente-de-machine-learning-hpo-e-mlflow)
9. [Configuração do Metabase e Conexão com Snowflake](#9-configuração-do-metabase-e-conexão-com-snowflake)
10. [Checklist de Homologação e Troubleshooting](#10-checklist-de-homologação-e-troubleshooting)

---

## 1. Visão Geral da Arquitetura e Componentes

A solução adota a **Arquitetura Medallion** em nuvem com orquestração desacoplada e conteinerizada:

```mermaid
flowchart TD
    subgraph AWS ["☁️ Nuvem AWS"]
        S3["Amazon S3 (Bucket de Dados Brutos)"]
        IAM["AWS IAM (Controle de Acesso)"]
        CW["Amazon CloudWatch (Logs)"]
    end

    subgraph Snowflake ["❄️ Snowflake Data Cloud"]
        RAW["MUNKA_RAW (Dados Brutos)"]
        STG["MUNKA_STG (Silver / Limpeza)"]
        INT["MUNKA_INT (Intermediate / NLP)"]
        GOLD["MUNKA_GOLD (Gold / Star Schema)"]
        ML["MUNKA_ML (Wide Tables / Predições)"]
    end

    subgraph DockerHost ["🐳 Ambiente Docker / Orquestração Local"]
        Airflow["Apache Airflow 2.10.0 (CeleryExecutor)"]
        DBT["dbt Core (90 Modelos + 78 Testes)"]
        MLflow["MLflow + Optuna (HPO & Tracking)"]
        Metabase["Metabase BI (Dashboards Executivos)"]
    end

    S3 -->|COPY INTO via Airflow| RAW
    RAW -->|dbt run| STG
    STG -->|dbt run| INT
    INT -->|dbt run| GOLD
    INT -->|dbt run| ML
    ML -->|Features| MLflow
    MLflow -->|Predições & Retrospectiva| ML
    GOLD -->|Visualização| Metabase
    ML -->|Visualização| Metabase
```

---

## 2. Pré-Requisitos e Softwares Necessários

| Software / Recurso | Versão Recomendada | Finalidade |
|---|---|---|
| **Git** | `>= 2.40` | Clonagem e controle de versão do repositório |
| **Docker Desktop** | `>= 24.x` (com Docker Compose v2) | Execução conteinerizada do Airflow, Postgres, Redis e Metabase |
| **Python** | `3.10` ou `3.11` | Execução local de scripts, dbt e pipelines de ML |
| **AWS CLI** | `>= 2.15` (opcional) | Provisionamento via CloudFormation e upload para o S3 |
| **Conta Snowflake** | Standard ou superior | Data Warehouse em nuvem |
| **Conta AWS** | Acesso IAM e S3 | Armazenamento de dados no Data Lake |

---

## 3. Matriz Centralizada de Credenciais e Variáveis (`.env`)

O projeto adota o princípio de **Fonte Única da Verdade**. Todas as configurações são lidas do arquivo `.env` na raiz do projeto (gerado a partir de [credentials_template.env](credentials_template.env)):

```bash
cp credentials_template.env .env
```

### 3.1. Variáveis do Snowflake

| Variável | Valor Padrão / Exemplo | Descrição |
|---|---|---|
| `DBT_SNOWFLAKE_ACCOUNT` | `sfedu02-gfb24387` | Identificador da conta Snowflake (Organization-Account) |
| `DBT_SNOWFLAKE_USER` | `DRAGON` | Nome do usuário técnico no Snowflake |
| `DBT_SNOWFLAKE_DATABASE` | `DRAGON_DB` | Banco de dados central |
| `DBT_SNOWFLAKE_WAREHOUSE` | `DRAGON_WH` | Virtual Warehouse para processamento |
| `DBT_SNOWFLAKE_ROLE` | `TRAINING_ROLE` | Role de execução com privilégios adequados |
| `DBT_SNOWFLAKE_SCHEMA` | `MUNKA_RAW` | Schema padrão para conexões dbt e RAW |
| `DBT_SNOWFLAKE_PRIVATE_KEY_PATH` | `/opt/airflow/dags/rsa_key.p8` | Caminho da chave privada PKCS#8 para autenticação RSA |

### 3.2. Variáveis da AWS

| Variável | Valor Padrão / Exemplo | Descrição |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | `AKIARBBWFZ3TQEWUD2IC` | Chave de acesso do usuário IAM com permissão no S3 |
| `AWS_SECRET_ACCESS_KEY` | *(Secret Key do IAM)* | Chave secreta de autenticação na AWS |
| `AWS_DEFAULT_REGION` | `us-east-2` | Região AWS do Bucket S3 (ex: Ohio) |
| `S3_BUCKET_NAME` | `munka-dev-070980587239-us-east-2` | Nome globalmente único do bucket S3 |

### 3.3. Variáveis do Apache Airflow & Docker

| Variável | Valor Padrão | Descrição |
|---|---|---|
| `AIRFLOW_UID` | `50000` | UID do usuário no container Linux |
| `_AIRFLOW_WWW_USER_USERNAME` | `airflow` | Usuário administrador do Airflow Webserver |
| `_AIRFLOW_WWW_USER_PASSWORD` | `airflow` | Senha de acesso ao Airflow Webserver |
| `AIRFLOW_CUSTOM_IMAGE_NAME` | `airflow-dbt-snowflake:2.10.0` | Imagem Docker customizada com dbt e providers instalados |

---

## 4. Provisionamento e Configuração na Nuvem AWS

### 4.1. Opção Automatizada via CloudFormation (IaC)

O arquivo [infrastructure/cloudformation.yaml](infrastructure/cloudformation.yaml) provisiona automaticamente toda a infraestrutura necessária:

```bash
aws cloudformation create-stack \
  --stack-name munka-data-infrastructure-dev \
  --template-body file://infrastructure/cloudformation.yaml \
  --parameters ParameterKey=EnvironmentName,ParameterValue=dev \
               ParameterKey=S3BucketName,ParameterValue=munka-dev-070980587239-us-east-2 \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-2
```

### 4.2. Estrutura de Arquivos no Amazon S3

Os arquivos `.csv` extraídos do sistema legado MUNKA devem ser carregados na raiz do bucket **obrigatoriamente em letras minúsculas**:

```text
s3://munka-dev-070980587239-us-east-2/
├── ab_user.csv
├── ab_project.csv
├── ab_task.csv
├── ab_task_log.csv
├── ab_sprint.csv
├── ab_custom_field.csv
└── ... (demais 33 tabelas CSV exportadas)
```

> ⚠️ **Atenção:** O comando `COPY INTO` do Snowflake é estrito quanto ao *case-sensitive* dos arquivos CSV.

### 4.3. Política IAM de Menor Privilégio (Least Privilege)

Caso crie o usuário IAM manualmente pelo Console AWS, utilize a política abaixo:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "MunkaS3BucketAccess",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::munka-dev-070980587239-us-east-2",
        "arn:aws:s3:::munka-dev-070980587239-us-east-2/*"
      ]
    }
  ]
}
```

---

## 5. Configuração e Segurança no Snowflake

### 5.1. Setup de Banco, Schemas, Warehouse e Role

Execute os comandos SQL abaixo no Snowflake (como `ACCOUNTADMIN` ou `SYSADMIN`):

```sql
-- 1. Criar o Banco de Dados e Warehouse
CREATE DATABASE IF NOT EXISTS DRAGON_DB;
CREATE WAREHOUSE IF NOT EXISTS DRAGON_WH
  WITH WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 120
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- 2. Criar os Schemas da Arquitetura Medallion
USE DATABASE DRAGON_DB;
CREATE SCHEMA IF NOT EXISTS MUNKA_RAW;
CREATE SCHEMA IF NOT EXISTS MUNKA_STG;
CREATE SCHEMA IF NOT EXISTS MUNKA_INT;
CREATE SCHEMA IF NOT EXISTS MUNKA_GOLD;
CREATE SCHEMA IF NOT EXISTS MUNKA_ML;

-- 3. Criar a Role de Treinamento/Engenharia
CREATE ROLE IF NOT EXISTS TRAINING_ROLE;
GRANT USAGE ON WAREHOUSE DRAGON_WH TO ROLE TRAINING_ROLE;
GRANT ALL PRIVILEGES ON DATABASE DRAGON_DB TO ROLE TRAINING_ROLE;
GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE DRAGON_DB TO ROLE TRAINING_ROLE;
GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE DRAGON_DB TO ROLE TRAINING_ROLE;
GRANT ALL PRIVILEGES ON ALL TABLES IN DATABASE DRAGON_DB TO ROLE TRAINING_ROLE;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE DRAGON_DB TO ROLE TRAINING_ROLE;
GRANT ALL PRIVILEGES ON ALL VIEWS IN DATABASE DRAGON_DB TO ROLE TRAINING_ROLE;
GRANT ALL PRIVILEGES ON FUTURE VIEWS IN DATABASE DRAGON_DB TO ROLE TRAINING_ROLE;
```

### 5.2. Autenticação por Par de Chaves RSA (Key-Pair Authentication)

Para dispensar o uso de senhas e garantir segurança empresarial:

1. **Geração das Chaves (já provisionadas no projeto em `src/dbt/rsa_key.p8`):**
   ```bash
   # Gerar chave privada PKCS#8 sem senha
   openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt
   
   # Extrair a chave pública
   openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
   ```

2. **Associar a Chave Pública ao Usuário no Snowflake:**
   ```sql
   ALTER USER DRAGON SET RSA_PUBLIC_KEY = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...';
   GRANT ROLE TRAINING_ROLE TO USER DRAGON;
   ALTER USER DRAGON SET DEFAULT_ROLE = TRAINING_ROLE;
   ALTER USER DRAGON SET DEFAULT_WAREHOUSE = DRAGON_WH;
   ```

---

## 6. Implantação da Stack Local com Docker e Airflow

### 6.1. Inicialização dos Contêineres

Na pasta [airflow/](airflow/):

```bash
cd airflow

# 1. Construir e inicializar todos os servicos em background
docker compose up -d --build

# 2. Verificar o status de saude dos containers
docker ps
```

**Serviços Ativos e Portas:**
- **Airflow Webserver:** `http://localhost:8081` (Usuário: `airflow` / Senha: `airflow`)
- **Metabase BI:** `http://localhost:3000`
- **Postgres (Metadados):** Porta `5432`
- **Redis (Celery Broker):** Porta `6379`

### 6.2. Estrutura do Pipeline Orquestrado (7 Passos + DAG Master)

O Airflow gerencia a execução sequencial ponta a ponta:

```mermaid
graph LR
    Master[dag_munka_full_pipeline] --> P1[passo1_munka_dbt_create_raw_tables]
    P1 --> P2[passo2_s3_to_snowflake_munka_raw]
    P2 --> P3[passo3_munka_dbt_create_stg]
    P3 --> P4[passo4_munka_dbt_run_marts]
    P4 --> P5[passo5_ml_hpo_e_retreinamento]
    P5 --> P6[passo6_batch_inference]
    P6 --> P7[passo7_ml_carga_analise_retrospectiva]
```

1. **`dag_munka_full_pipeline`**: DAG Master orquestradora geral.
2. **`passo1_munka_dbt_create_raw_tables`**: DDL e estrutura na camada `MUNKA_RAW`.
3. **`passo2_s3_to_snowflake_munka_raw`**: Ingestão de 39 CSVs do S3 para o Snowflake via `COPY INTO`.
4. **`passo3_munka_dbt_create_stg`**: Execução do dbt Staging (limpeza e deduplicação via `QUALIFY`).
5. **`passo4_munka_dbt_run_marts`**: Execução do dbt Marts (Gold + ML) e 78 testes automáticos de qualidade.
6. **`passo5_ml_hpo_e_retreinamento`**: Otimização HPO (Optuna), retreinamento 5-Fold e tracking no MLflow.
7. **`passo6_batch_inference`**: Inferência em lote com o modelo vencedor gerando `novas_previsoes.csv`.
8. **`passo7_ml_carga_analise_retrospectiva`**: Carga de auditoria via `dbt seed` e criação da mart `MUNKA_ML.ML_ANALISE_RETROSPECTIVA`.

---

## 7. Execução e Validação do Pipeline de Dados (dbt Core)

Para executar o dbt diretamente no terminal:

```bash
# 1. Ativar o ambiente virtual
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # Linux/macOS

# 2. Instalar dependencias
pip install -r requirements.txt

# 3. Testar a conexao com o Snowflake
cd src/dbt
dbt debug --profiles-dir .

# 4. Compilar os 90 modelos
dbt compile --profiles-dir .

# 5. Executar o pipeline de transformacao completo
dbt run --profiles-dir .

# 6. Executar a suite de testes de integridade (unique e not_null)
dbt test --profiles-dir .
```

---

## 8. Ambiente de Machine Learning, HPO e MLflow

### 8.1. Iniciar o Servidor MLflow UI

```bash
cd src/ml
mlflow ui --backend-store-uri sqlite:///mlflow.db --port 5000
```
Acesse no navegador: `http://localhost:5000`

### 8.2. Execução dos Treinamentos e HPO

```bash
# Treinamento Baseline (5-Fold Cross Validation)
python src/ml/train.py

# Otimização Automática de Hiperparâmetros (Optuna - 10 Trials)
python src/ml/hpo.py

# Pipeline de Inferência em Lote
python src/ml/predict_pipeline.py
```

### 8.3. Resultados Oficiais do Benchmark de Modelos

| Modelo | Arquitetura / Topologia | $MSE$ Validação | $R^2$ Score | Status |
|---|---|---|---|---|
| **MLP Scikit-Learn (Campeão)** | 2 camadas `(64, 128)`, $lr=0.0033$, $\alpha=0.000025$ | **5.46** | **0.75 (75%)** | 🏆 **Produção** |
| **MLP Sklearn Restrito** | 2 camadas `(64, 32)`, $lr=0.0027$ | 5.49 | -- | 🧪 Controle |
| **MLP NumPy (Puro)** | 2 camadas `(16, 32)`, $lr=0.0375$ | 6.90 | -- | 🥈 Matemático |
| **Baseline Linear** | Regressão Linear Simples | 345.12 | 0.58 (58%) | Baseline |

---

## 9. Configuração do Metabase e Conexão com Snowflake

O Metabase consome diretamente as tabelas dimensionais Gold e as predições de ML.

1. Acesse `http://localhost:3000`.
2. Vá em **Admin > Databases > Add a database**.
3. Preencha o formulário exatamente com as credenciais abaixo:

| Campo no Formulário | Valor |
|---|---|
| **Database type** | `Snowflake` |
| **Connection string (optional)** | *(em branco)* |
| **Display name** | `Snowflake - MUNKA` |
| **Account name** | `sfedu02-gfb24387` |
| **Username** | `DRAGON` |
| **Authenticate with user and password** | **Desligado** (usar chave RSA) |
| **RSA private key (PKCS8/.p8)** | `Local file path` |
| **File path** | `/metabase-data/rsa_key.p8` *(caminho dentro do container)* |
| **Warehouse** | `DRAGON_WH` |
| **Database name** | `DRAGON_DB` |
| **Schemas** | `MUNKA_GOLD,MUNKA_ML` *(ou `All`)* |
| **Role (optional)** | `TRAINING_ROLE` |
| **Additional JDBC options (Advanced)** | `disablePlatformDetection=true` |

> 💡 **Dica de Troubleshooting JDBC:** A opção `disablePlatformDetection=true` é essencial para evitar o erro *Timed out after 10.0s* causado pela tentativa do driver JDBC de consultar metadados de nuvem dentro do Docker local.

---

## 10. Checklist de Homologação e Troubleshooting

Antes de liberar a aplicação para homologação final, valide os seguintes pontos:

- [ ] Arquivo `.env` configurado e preenchido na raiz do projeto.
- [ ] Bucket S3 criado na AWS com todos os 39 arquivos `.csv` em letras minúsculas.
- [ ] Chave RSA associada ao usuário `DRAGON` no Snowflake.
- [ ] Containers Docker ativos (`docker ps`) e saudáveis (`airflow-webserver`, `scheduler`, `worker`, `metabase`, `postgres`, `redis`).
- [ ] Zero erros de importação no Airflow (`docker exec airflow-airflow-scheduler-1 airflow dags list-import-errors`).
- [ ] DAG Master `dag_munka_full_pipeline` executada com sucesso de ponta a ponta (Passos 1 a 7 com status verde).
- [ ] 78 testes de integridade do dbt aprovados (`dbt test`).
- [ ] Experimentos e artefatos visualizáveis na interface do MLflow (`localhost:5000`).
- [ ] Metabase conectado ao Snowflake (`localhost:3000`) exibindo tabelas de `MUNKA_GOLD` e `MUNKA_ML`.
