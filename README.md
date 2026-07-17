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

---

## Introdução

### Snowflake
O Snowflake, uma plataforma de Data Cloud, fornece uma solução inovadora que simplifica pipelines de dados, permitindo que você foque mais em dados e análises do que na gestão de infraestrutura. Ele simplifica o armazenamento, processamento e computação quando comparado a soluções tradicionais.

### Airflow
O Apache Airflow é uma plataforma de gerenciamento de fluxo de trabalho de código aberto que permite criar e gerenciar pipelines de dados de forma eficiente usando grafos acíclicos direcionados (DAGs) de tarefas.

### Docker
O Docker é utilizado neste projeto para executar o Apache Airflow em um contêiner, tornando a configuração e a portabilidade mais fáceis.

### dbt (data build tool)
O dbt é uma ferramenta de linha de comando de código aberto que permite que analistas e engenheiros de dados transformem dados em seu data warehouse de forma mais eficiente. Ele segue uma abordagem modular e versionada para transformação de dados.

## Requisitos Prévios

O projeto requer os seguintes elementos:
* Docker
* Python >=3
* Uma conta Snowflake.
* Um usuário Snowflake com permissões necessárias, incluindo a capacidade de criar objetos no banco de dados DRAGON_DB.

### Como criar um conta no Snowflake?
https://www.snowflake.com/en/emea/

### Como criar o user com permissões?
Entre na pasta `scripts` e use o arquivo `00_setup_controle.sql` como base.

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

## Conclusão
Este Data Warehouse está totalmente funcional, seguindo os melhores padrões da Engenharia de Dados Moderna. Os dados fluem do S3 para a RAW, são limpos na Staging e modelados em uma robusta camada Ouro (Kimball / Wide Tables).

## Developer
| Desenvolvedor      | LinkedIn                                   | Email                        | Portfólio                              |
|--------------------|--------------------------------------------|------------------------------|----------------------------------------|
| Ivanio Junior      |                                            |                              |                                        |
| Robson             |                                            |                              |                                        |
