# Conexão Metabase → Snowflake

Dados para preencher o formulário **Admin > Databases > Add a database** no Metabase (`http://localhost:3000`), usando as mesmas credenciais já configuradas para o dbt em [src/dbt/profiles.yml](src/dbt/profiles.yml) e [credentials_template.env](credentials_template.env).

| Campo no formulário | Valor |
|---|---|
| Database type | `Snowflake` |
| Connection string (optional) | *(deixar em branco — preencher os campos abaixo manualmente)* |
| Display name | `Snowflake - MUNKA` |
| Account name | `sfedu02-gfb24387` |
| Username | `GIRAFFE` |
| Authenticate with user and password | **Desligado** (usar chave RSA, não senha) |
| RSA private key (PKCS8/.p8) | `Local file path` |
| File path | `/metabase-data/rsa_key_giraffe.p8` |
| Warehouse | `GIRAFFE_WH` |
| Database name (case sensitive) | `GIRAFFE_DB` |
| Schemas | `Only these…` → `MUNKA_GOLD,MUNKA_ML` (ou `All` para explorar todas as camadas) |
| Role (optional) | `TRAINING_ROLE` |
| Use an SSH tunnel | **Desligado** |
| Additional JDBC connection string options (em "Show advanced options") | `disablePlatformDetection=true` |

## Observações

- **Não** usar senha: o toggle "Authenticate with user and password" deve permanecer desligado, pois o usuário `GIRAFFE` está configurado para autenticação por chave RSA (key-pair), igual ao dbt.
- O campo **File path** aponta para dentro do container do Metabase, não para o seu computador. O arquivo `src/dbt/rsa_key_giraffe.p8` já é montado automaticamente em `/metabase-data/rsa_key_giraffe.p8` (somente leitura) pelo serviço `metabase` definido em [airflow/docker-compose.yaml](airflow/docker-compose.yaml).
- **Erro "Timed out after 10.0 s"**: é um bug conhecido do driver JDBC do Snowflake (versões >= 3.27.1) que tenta detectar automaticamente em qual cloud (AWS/GCP/Azure) está rodando, fazendo chamadas a endpoints de metadata (`169.254.169.254`, `metadata.google.internal`) que não existem no Docker local. Essas chamadas consomem os 10s de timeout do teste de conexão do Metabase antes do login real no Snowflake terminar. **Fix:** em "Show advanced options" → "Additional JDBC connection string options", adicionar `disablePlatformDetection=true` para pular essa detecção. Referência: [snowflakedb/snowflake-jdbc#2410](https://github.com/snowflakedb/snowflake-jdbc/issues/2410).
- Schemas recomendados: `MUNKA_GOLD` (modelo dimensional — fatos e dimensões) e `MUNKA_ML` (features para Machine Learning), que são as camadas prontas para consumo analítico geradas pelo dbt.
- Depois de clicar em **Save**, o Metabase sincroniza automaticamente o schema e as tabelas ficam disponíveis para criar perguntas, gráficos e dashboards.
