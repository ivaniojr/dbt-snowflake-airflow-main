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

O projeto requer os seguintes elementos para funcionar end-to-end:

| Requisito | Versão / Detalhe | Obrigatório |
|-----------|-----------------|-------------|
| Docker Desktop | >= 20.x | ✅ Sim |
| Python | >= 3.9 | ✅ Sim |
| Conta Snowflake | Trial ou paga, região `us-east-1` recomendada | ✅ Sim |
| Usuário Snowflake | Com role `SYSADMIN` ou permissões equivalentes | ✅ Sim |
| Conta AWS | Com acesso ao Console IAM e S3 | ✅ Sim |
| Bucket AWS S3 | Bucket dedicado para os CSVs do sistema legado | ✅ Sim |
| Usuário IAM AWS | Com permissões de leitura no bucket S3 | ✅ Sim |
| Git | >= 2.x | ✅ Sim |

### Como criar uma conta no Snowflake?
https://www.snowflake.com/en/emea/

### Como criar o user com permissões no Snowflake?
Entre na pasta `scripts` e use o arquivo `00_setup_controle.sql` como base.

### Como configurar o AWS S3 como repositório de dados brutos

A DAG `passo2_s3_to_snowflake_munka_raw` usa o AWS S3 como **fonte primária dos arquivos CSV** exportados do sistema legado MUNKA. O fluxo é:

```
Sistema Legado (MUNKA) → Exporta CSVs → Upload no S3 → Airflow (COPY INTO) → Snowflake RAW
```

#### Passo 1 — Criar o bucket S3 no Console AWS

1. Acesse o [Console AWS S3](https://s3.console.aws.amazon.com/)
2. Clique em **Create bucket**
3. Defina o nome do bucket (ex: `munka-dev-<seu-account-id>-us-east-2`)
4. Selecione a região (recomendado: `us-east-2` ou a mais próxima do seu Snowflake)
5. Mantenha o **Block Public Access** ativado — o acesso será feito via credenciais IAM
6. Clique em **Create bucket**

#### Passo 2 — Estrutura de arquivos esperada no bucket

Os arquivos `.csv` devem ser carregados na raiz do bucket **com nomes em minúsculo**, seguindo o padrão de tabelas do sistema legado:

```
s3://munka-dev-<account-id>-us-east-2/
├── ab_user.csv
├── ab_project.csv
├── ab_task.csv
├── ab_task_log.csv
├── ab_sprint.csv
└── ... (demais tabelas exportadas)
```

> ⚠️ **Atenção:** O nome dos arquivos deve estar **exatamente em minúsculo**. O comando `COPY INTO` do Snowflake é case-sensitive no mapeamento de arquivos.

#### Passo 3 — Criar usuário IAM com permissões mínimas

No [Console IAM da AWS](https://console.aws.amazon.com/iam/), crie um usuário dedicado para o Airflow com a seguinte política inline (substitua `<NOME-DO-SEU-BUCKET>`):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::<NOME-DO-SEU-BUCKET>",
        "arn:aws:s3:::<NOME-DO-SEU-BUCKET>/*"
      ]
    }
  ]
}
```

Após criar o usuário, gere um **Access Key** (tipo: *Application and AWS CLI*) e guarde o `Access Key ID` e o `Secret Access Key`.

#### Passo 4 — Configurar a conexão no Airflow

1. Acesse a interface do Airflow em `localhost:8081`
2. Vá em **Admin** → **Connections**
3. Clique em **+** para criar ou edite a existente com `Conn Id: aws_default`
4. Preencha os campos:

| Campo | Valor |
|-------|-------|
| **Connection Id** | `aws_default` |
| **Connection Type** | `Amazon Web Services` |
| **Login** | Seu `AWS Access Key ID` |
| **Password** | Seu `AWS Secret Access Key` |
| **Extra** | `{"region_name": "us-east-2"}` |

5. Clique em **Save**

*O Airflow injetará essas credenciais automaticamente no comando `COPY INTO` disparado no Snowflake.*

#### Passo 5 — Validação da configuração

Antes de executar a DAG, valide os seguintes pontos:

- [ ] Bucket S3 criado e acessível
- [ ] Arquivos CSV carregados no bucket com nomes em minúsculo
- [ ] Usuário IAM criado com política de leitura no bucket
- [ ] Access Key ID e Secret Access Key gerados e salvos
- [ ] Conexão `aws_default` configurada no Airflow
- [ ] Conexão Snowflake configurada no Airflow (`snowflake_default`)
- [ ] DAG `passo2_s3_to_snowflake_munka_raw` visível e ativa no Airflow

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

### A Estratégia de Avaliação dos Modelos (Benchmarking)

Para provar a eficácia da solução de forma científica, o pipeline de Machine Learning orquestrado no Airflow executa e avalia **três modelos distintos**, cada um com um papel específico:

#### 1. Modelo NumPy (A Prova de Fundamentos Matemáticos)
* **O que é:** Uma Rede Neural construída absolutamente do zero, utilizando apenas matemática pura e matrizes (`numpy`). Sem uso de frameworks de ML.
* **Restrições:** Possui limitações arquiteturais projetadas no código: opera exclusivamente com **2 camadas ocultas**, usa o Gradiente Descendente Estocástico (SGD) clássico e não possui otimização dinâmica de regularização.
* **Por que usamos:** Serve para atestar o domínio técnico sobre o algoritmo de *backpropagation* e os fundamentos matemáticos por trás do aprendizado profundo.

#### 2. Scikit-Learn MLP Completo (O Caçador de Performance)
* **O que é:** O modelo oficial da biblioteca de mercado `scikit-learn` (`MLPRegressor`), que roda otimizado em linguagem C (Cython) e utiliza o moderno otimizador de gradientes **Adam**. 
* **Restrições:** **Nenhuma.** Durante a Busca de Hiperparâmetros (HPO) com o Optuna, damos total liberdade para ele escolher entre 1 a 3 camadas, centenas de neurônios, e afinar sua regularização (`alpha`) livremente. 
* **Por que usamos:** O objetivo deste modelo é corporativo: encontrar a rede neural mais precisa possível para ser implantada em produção e entregar valor ao negócio.

#### 3. Scikit-Learn MLP Restrito (O Grupo de Controle Científico)
* **O que é:** É o mesmo modelo avançado do Scikit-Learn, porém com as "mãos amarradas" de propósito durante o HPO.
* **Restrições (A Regra do *Apples-to-Apples*):** Limitamos o espaço de busca deste modelo para ser **matematicamente idêntico** ao modelo NumPy. Ele é forçado a procurar arquiteturas de exatamente **2 camadas**, usando a mesma quantidade limitada de neurônios e com a regularização (`alpha`) travada no padrão.
* **Por que usamos:** Atua como um controle de laboratório. Ao colocar o NumPy e o Scikit-Learn para competirem na mesma "categoria de peso", isolamos a variável de sucesso. Se o Scikit-Learn Restrito vencer o NumPy, provamos estatisticamente que a vantagem vem da sua implementação do otimizador *Adam* em C. Se o NumPy empatar, provamos que nossa matemática feita do zero tem o mesmo poder de fogo de uma biblioteca global!

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
| Scikit-Learn MLP | 10 | 150 | `learning_rate`, `hidden_sizes` (1–3 camadas), `alpha` |
| NumPy MLP (matemático) | 10 | 150 | `learning_rate`, `n_units_l1`, `n_units_l2` |

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

### 🏆 Resultados Finais e Gráficos do Treinamento

Após a execução do HPO (com 10 trials e 150 épocas limitadas pelo solver Adam), obtemos os seguintes resultados comparativos oficiais no conjunto de testes de homologação (150 amostras isoladas na camada `MUNKA_ML`):

| Modelo | Estratégia / Topologia (Camadas Ocultas) | $MSE$ (Validação) | $MAE$ (Teste Cego) | $R^2$ Score (Teste Cego) | Status Final |
|--------|------------------------------------------|-------------------|--------------------|--------------------------|--------------|
| **MLP HPO Scikit-Learn** | 2 camadas `(64, 128)`, $lr=0.0033$, $\alpha=0.000025$ | **5.46** | **0.67h** | **0.75 (75%)** | 🏆 **Modelo Vencedor** |
| **MLP HPO Sklearn Restrito** | 2 camadas `(64, 32)`, $lr=0.0027$, $\alpha=0.0001$ | 5.49 | -- | -- | 🧪 Controle (Apples-to-Apples) |
| **MLP HPO NumPy** | 2 camadas `(16, 32)`, $lr=0.0375$ | 6.90 | -- | -- | 🥈 Vice-Campeão Matemático |
| **Baseline Linear** | Regressão Linear Simples | 345.12 | 15.20h | 0.58 (58%) | Benchmark Estatístico |

> *A implementação própria NumPy comprovou a eficácia da matemática construída do zero, atingindo pontuações coladas no Scikit-Learn, mas este último foi eleito para o pipeline de inferência oficial por sua implementação otimizada do solver Adam em linguagem C (Cython).*

#### Curvas de Aprendizado e Resíduos (Scikit-Learn - Campeão)
Abaixo estão os gráficos gerados automaticamente no artefato do MLflow para o modelo campeão:

![Curva de Loss - Scikit-Learn](src/ml/sklearn_best_loss_curve.png)
![Resíduos - Scikit-Learn](src/ml/sklearn_best_residuals.png)

#### Curvas de Aprendizado e Resíduos (NumPy - Vice-campeão matemático)
![Curva de Loss - NumPy](src/ml/numpy_best_loss_curve.png)
![Resíduos - NumPy](src/ml/numpy_best_residuals.png)

---

## Infraestrutura como Código (AWS CloudFormation)

O provisionamento da infraestrutura em nuvem AWS está automatizado via **CloudFormation (YAML)** localizado no diretório [infrastructure/cloudformation.yaml](infrastructure/cloudformation.yaml).

A stack provisiona:
- **Amazon S3**: Bucket `munka-dev-070980587239-us-east-2` estruturado nas camadas `raw/`, `processed/`, `features/`, `ml/`, com criptografia SSE-S3 AES-256 e bloqueio de acesso público.
- **IAM Role & Policies**: Role com princípio de menor privilégio para autorizar o Snowflake a acessar os dados via `STORAGE INTEGRATION`.
- **CloudWatch Log Group**: Retenção de 30 dias para auditoria de execuções do pipeline.

---

## Proposta de Arquitetura Equivalente 100% AWS Nativa

Para cenários onde se exige implementação 100% nativa na AWS (sem Snowflake), o pipeline equivale aos seguintes serviços gerenciados:

```
                    AWS NATIVA

                   Amazon S3 (RAW/Processed)
                        │
                        ▼
                 AWS Glue Crawler & Data Catalog
                        │
                        ▼
                 Amazon Redshift (Data Warehouse)
                        │
          ┌─────────────┴─────────────┐
          ▼                           ▼
    Amazon SageMaker           Amazon QuickSight
   (Treinamento & HPO)         (Dashboards & BI)
          │
          ▼
   Predições S3
```
- **Orquestração**: AWS Managed Workflows for Apache Airflow (MWAA).
- **Monitoramento & Governança**: Amazon CloudWatch + AWS IAM.

---

## Estimativa de Custos AWS & Snowflake

Abaixo está a estimativa de custos operacionais mensais projetada para o ambiente de desenvolvimento/homologação do projeto:

| Serviço / Componente | Uso Estimado / Parâmetros | Custo Estimado Mensal (USD) |
|----------------------|---------------------------|-----------------------------|
| **Amazon S3** | 10 GB (Raw, Processed, ML) | $0.23 |
| **AWS CloudWatch** | Logs de auditoria (< 2 GB) | $1.00 |
| **AWS IAM / CloudFormation** | Recursos de governança | $0.00 (Gratuito) |
| **Snowflake Data Cloud** | Standard Warehouse X-Small (~2h/dia) | $15.00 |
| **Apache Airflow & Metabase** | Containers Docker Locais | $0.00 |
| **TOTAL ESTIMADO** | | **~$16.23 / mês** |

---

## Metabase — Visualização e Dashboards

### Objetivo
Seguindo a arquitetura C4 do projeto, o **Metabase** é a ferramenta de BI/visualização que consome diretamente os dados já modelados no Snowflake (camadas `MUNKA_GOLD` e `MUNKA_ML`), permitindo montar dashboards e relatórios analíticos sem escrever código.

### Como subir o Metabase
O serviço já está definido no `docker-compose.yaml` da pasta `airflow/` e sobe junto com o restante da stack:
```bash
cd airflow
docker compose up -d metabase
```

Acesse no navegador:
```
http://localhost:3000
```
Na primeira execução, o próprio Metabase guia a criação do usuário administrador (nome, e-mail e senha).

### Como conectar o Metabase ao Snowflake
Em **Admin > Databases > Add a database**, use os mesmos dados de conexão do dbt (ver `src/dbt/profiles.yml` / `credentials_template.env` / `CONEXAO_METABASE_SNOWFLAKE.md`):

| Campo | Valor |
|-------|-------|
| Database type | Snowflake |
| Account or hostname | `sfedu02-gfb24387` |
| Username | `DRAGON` |
| RSA private key (PEM) | Local file path → `/metabase-data/rsa_key.p8` (já montado no container) |
| Role | `TRAINING_ROLE` |
| Warehouse | `DRAGON_WH` |
| Database name | `DRAGON_DB` |
| Schemas | `MUNKA_GOLD,MUNKA_ML` (ou `All`, se preferir explorar todas as camadas) |

---

## Guia de Reprodutibilidade Passo a Passo

Para clonar e executar o pipeline completo em uma máquina do zero:

1. **Clonar o Repositório:**
   ```bash
   git clone https://github.com/ivaniojr/dbt-snowflake-airflow-main.git
   cd dbt-snowflake-airflow-main
   ```

2. **Configurar Credenciais (`.env`):**
   ```bash
   cp credentials_template.env .env
   ```

3. **Subir a Stack Docker (Airflow & Metabase):**
   ```bash
   cd airflow
   docker compose up -d
   ```

4. **Executar Pipeline Master no Airflow:**
   - Acesse o Airflow em `http://localhost:8081` (Usuário: `airflow` / Senha: `airflow`).
   - Dispare a DAG master: `dag_munka_full_pipeline`.

5. **Executar dbt Run e dbt Test (Opcional via Terminal):**
   ```bash
   cd src/dbt
   dbt run --profiles-dir .
   dbt test --profiles-dir .
   ```

6. **Gerar Conjunto de Avaliação de ML:**
   ```bash
   python src/ml/export_evaluation_dataset.py
   ```

---

## Conclusão
Este projeto entrega uma solução end-to-end de Engenharia de Dados e Machine Learning: os dados fluem do S3 para a camada RAW no Snowflake, são limpos e enriquecidos pelo dbt nas camadas Staging e Gold, e finalmente alimentam modelos preditivos MLP rastreados pelo MLflow e otimizados pelo Optuna — com auditabilidade completa de ponta a ponta.

---

## Integrantes do Grupo (4 Alunos — Requisito IFG)

| Nome do Integrante | Papel no Projeto | E-mail / Contato |
|--------------------|------------------|------------------|
| **Ivanio Junior** | Engenharia de Dados & Pipeline Airflow | ivaniojr@users.noreply.github.com |
| **Robson Silva** | Arquitetura Snowflake & Metabase BI | robson.silva.cr@gmail.com |
| **Integrante 3** | Engenharia de Machine Learning & HPO | integrante3@ifg.edu.br |
| **Integrante 4** | Infraestrutura AWS CloudFormation & Governança | integrante4@ifg.edu.br |

