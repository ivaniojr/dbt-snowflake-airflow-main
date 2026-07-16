# Docker Compose — Airflow + dbt + Snowflake

## Estrutura esperada

```text
seu-airflow/
├── docker-compose.yaml
├── Dockerfile.dbt
├── requirements-dbt.txt
├── .env
├── dags/
│   └── munka_dbt_create_raw_tables.py
└── dbt/
    └── munka_warehouse/
        ├── dbt_project.yml
        ├── profiles.yml
        ├── macros/
        └── models/
```

## Instalação

1. Copie `.env.example` para `.env`.
2. Confirme que a rede externa existe:

```bash
docker network inspect network-bigdata >/dev/null 2>&1 || docker network create network-bigdata
```

3. Reconstrua a imagem:

```bash
docker compose down
docker compose build --no-cache
docker compose up airflow-init
docker compose up -d
```

4. Verifique dbt e o provider:

```bash
docker compose exec airflow-scheduler dbt --version
docker compose exec airflow-scheduler airflow providers list | grep snowflake
```

5. Abra o Airflow em `http://localhost:8081`.

## Conexão Snowflake

Crie a conexão `snowflake_munka` em **Admin > Connections**:

- Connection Type: `Snowflake`
- Login: usuário Snowflake
- Password: senha Snowflake
- Schema: `MUNKA_RAW`

Extra:

```json
{
  "account": "identificador_da_conta",
  "database": "DRAGON_DB",
  "warehouse": "COMPUTE_WH",
  "role": "SYSADMIN"
}
```

## DAG

Execute o DAG:

```text
munka_dbt_create_raw_tables
```

## Usuário/Senha Padrão
password: airflow

---------------------------------------------

## Conclusão
Parabéns! você já tem o Airflow rodando no Docker.

## 📚 Referências
https://airflow.apache.org/docs/apache-airflow/stable/installation/index.html

## Developer
| Desenvolvedor      | LinkedIn                                   | Email                        | Portfólio                              |
|--------------------|--------------------------------------------|------------------------------|----------------------------------------|
