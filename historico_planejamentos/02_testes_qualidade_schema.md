# Execução 02: Governança de Dados e Testes Unitários de Qualidade

## 🎯 Implementation Plan (Planejamento)
Com quase 40 tabelas vivendo na camada **Gold** (Marts), precisávamos garantir que os dados não sofressem corrupção, como duplicidades nas Chaves Primárias Artificiais (Surrogate Keys) geradas durante o processamento do Snowflake.
- **Diagnóstico:** O teste de dados era feito via scripts manuais (como o arquivo legado `07_data_quality.sql`), sem integração com a pipeline. Se os dados estivessem sujos, as Fatos seriam processadas mesmo assim.
- **Proposta:**
  1. Usar a estrutura nativa de YAML do dbt para impor "Data Contracts".
  2. Construir o script `generate_schema.py` para varrer todas as tabelas e colunas da camada Gold e ML e documentar tudo.
  3. Adicionar automaticamente os testes `unique` (impossível duplicar chaves) e `not_null` (chave nunca pode ser nula) para a primeira coluna de cada tabela (`SK_...`).

---

## ✅ Walkthrough (O que foi entregue)
A governança de dados foi automatizada!

1. **Geração do `schema.yml`**: Criamos um arquivo yaml mestre contendo centenas de linhas de declarações automáticas de testes. 
2. **Qualidade Atômica**: Agora, antes que os dados cheguem aos Cientistas de Dados (na `ML_TAREFA_FEATURES`) ou nos Analistas de BI (na `FATO_TAREFA`), o comando `dbt test` roda dentro do cluster Snowflake, garantindo que o Hashes não colidiram e não há "lixo genético" nos joins.
3. **Morte aos scripts manuais**: Assim como as antigas tabelas, os antigos scripts SQL de "Quality Checks" foram abandonados, centralizando a governança da base de dados no ecossistema do dbt.

> [!TIP]
> A implementação destas regras de Qualidade resolve a fase "Verificação (T+1)" típica das grandes Big Techs, proibindo relatórios de Dashboard de rodarem caso a qualidade falhe durante a madrugada.
