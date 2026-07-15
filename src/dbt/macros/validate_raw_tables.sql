{% macro validate_raw_tables() %}
    {% set validation_sql %}
        WITH EXPECTED_TABLES (TABLE_NAME) AS (
            SELECT COLUMN1
            FROM VALUES
            ('RAW_AB_PERMISSION'),
            ('RAW_AB_PERMISSION_VIEW'),
            ('RAW_AB_PERMISSION_VIEW_ROLE'),
            ('RAW_AB_REGISTER_USER'),
            ('RAW_AB_ROLE'),
            ('RAW_AB_USER'),
            ('RAW_AB_USER_ROLE'),
            ('RAW_AB_VIEW_MENU'),
            ('RAW_AJUSTE'),
            ('RAW_ALEMBIC_VERSION'),
            ('RAW_ANEXOS'),
            ('RAW_CARGO'),
            ('RAW_CENARIO'),
            ('RAW_COMENTARIO'),
            ('RAW_COMPLEXIDADE'),
            ('RAW_CONTRATO'),
            ('RAW_CONTRATOS_USUARIOS'),
            ('RAW_COORD_PROJETO'),
            ('RAW_COORDENACAO'),
            ('RAW_ETIQUETA'),
            ('RAW_FATOR_COMPLEXIDADE_UST'),
            ('RAW_FATURA'),
            ('RAW_FICHA_INDICADOR'),
            ('RAW_FICHAS_PROJETOS'),
            ('RAW_LIDER_PROJETOS'),
            ('RAW_NIVEL'),
            ('RAW_NIVEL_SUPERIOR'),
            ('RAW_OBJETIVO'),
            ('RAW_ORIGEM'),
            ('RAW_ORIGENS_PROJETO'),
            ('RAW_PRODUTO'),
            ('RAW_PROJETO'),
            ('RAW_PROJETO_RESULTADO_CHAVE'),
            ('RAW_REAJUSTE'),
            ('RAW_REGRA'),
            ('RAW_RENOVACAO'),
            ('RAW_REQUISITO'),
            ('RAW_RESULTADO_CHAVE'),
            ('RAW_SERVICO'),
            ('RAW_SPRINT'),
            ('RAW_STATUS'),
            ('RAW_TAREFA'),
            ('RAW_TAREFAS_CENARIOS'),
            ('RAW_TECNOLOGIA'),
            ('RAW_TECNOLOGIAS_PROJETO'),
            ('RAW_TIPO'),
            ('RAW_TIPO_STATUS'),
            ('RAW_UNIDADE_ADM'),
            ('RAW_UNIDADE_ADM_SUPERIOR')
        ),
        EXISTING_TABLES AS (
            SELECT TABLE_NAME
            FROM {{ target.database }}.INFORMATION_SCHEMA.TABLES
            WHERE TABLE_SCHEMA = UPPER('{{ target.schema }}')
              AND TABLE_TYPE = 'BASE TABLE'
        )
        SELECT
            COUNT(*) AS MISSING_COUNT,
            COALESCE(
                LISTAGG(E.TABLE_NAME, ', ') WITHIN GROUP (ORDER BY E.TABLE_NAME),
                ''
            ) AS MISSING_TABLES
        FROM EXPECTED_TABLES E
        LEFT JOIN EXISTING_TABLES T
            ON T.TABLE_NAME = E.TABLE_NAME
        WHERE T.TABLE_NAME IS NULL
    {% endset %}

    {% if execute %}
        {% set result = run_query(validation_sql) %}
        {% set missing_count = result.columns[0].values()[0] | int %}
        {% set missing_tables = result.columns[1].values()[0] %}

        {% if missing_count > 0 %}
            {{ exceptions.raise_compiler_error(
                'Falha na validação RAW. Tabelas ausentes: ' ~ missing_tables
            ) }}
        {% endif %}

        {{ log('Validação concluída: todas as 49 tabelas RAW existem.', info=True) }}
    {% endif %}
{% endmacro %}
