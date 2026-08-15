# Dashboard Metabase — Evidências de Anexo (RAW_TAREFA.EVIDENCIA_ANEXO)

Guia para criar, manualmente no Metabase (`http://localhost:3000`), um dashboard sobre os anexos de evidência registrados nas tarefas (coluna `EVIDENCIA_ANEXO` de `RAW_TAREFA`).

## Por que não consultar `RAW_TAREFA` diretamente?

O Metabase deste projeto está conectado ao Snowflake apenas com acesso aos schemas **`MUNKA_GOLD`** e **`MUNKA_ML`** (ver [CONEXAO_METABASE_SNOWFLAKE.md](CONEXAO_METABASE_SNOWFLAKE.md)). O schema `MUNKA_RAW` (onde vive `RAW_TAREFA`) não é exposto por design — os dados brutos passam pelo pipeline dbt (`RAW` → `STG` → `GOLD`) antes de chegar à camada analítica.

A coluna `EVIDENCIA_ANEXO` já está modelada na camada Ouro, então o dashboard é construído em cima dela:

- [`fct_evidencia_tarefa.sql`](src/dbt/models/marts/gold/fct_evidencia_tarefa.sql) — uma linha por item de evidência; filtrando `TIPO_EVIDENCIA = 'ANEXO'` obtemos exatamente o que vem de `RAW_TAREFA.EVIDENCIA_ANEXO`. Contém `EXTENSAO_ARQUIVO`, `FL_IMAGEM`, `QUANTIDADE_CARACTERES`, etc.
- [`fct_tarefa.sql`](src/dbt/models/marts/gold/fct_tarefa.sql) — contém a flag booleana `FL_EVIDENCIA_ANEXO` por tarefa, útil para taxas gerais.

## Pré-requisitos

1. Stack rodando: `metabase` e Snowflake acessível (verificar com `docker ps`).
2. Conexão `Snowflake - MUNKA` já configurada em **Admin > Databases** (ver [CONEXAO_METABASE_SNOWFLAKE.md](CONEXAO_METABASE_SNOWFLAKE.md)).
3. Login em `http://localhost:3000` com seu usuário/senha do Metabase.

## Passo 1 — Criar as perguntas (Questions) em SQL

Para cada card abaixo: **+ New → SQL query** → selecionar database `Snowflake - MUNKA` → colar o SQL → **Run** → **Save** (usar o nome sugerido) → escolher a visualização indicada.

### 1. KPI — Tarefas com anexo (visualização: Number)
```sql
SELECT COUNT(*) AS QTD_TAREFAS_COM_ANEXO
FROM MUNKA_GOLD.FCT_TAREFA
WHERE FL_EVIDENCIA_ANEXO = TRUE;
```

### 2. KPI — % de tarefas com anexo sobre o total (visualização: Number, formato %)
```sql
SELECT ROUND(100.0 * SUM(IFF(FL_EVIDENCIA_ANEXO, 1, 0)) / COUNT(*), 2) AS PCT_TAREFAS_COM_ANEXO
FROM MUNKA_GOLD.FCT_TAREFA;
```

### 3. Evolução mensal de anexos enviados (visualização: Line chart)
```sql
SELECT
    DATE_TRUNC('month', DATA_ULTIMA_ATUALIZACAO) AS MES,
    COUNT(*) AS QTD_ANEXOS
FROM MUNKA_GOLD.FCT_EVIDENCIA_TAREFA
WHERE TIPO_EVIDENCIA = 'ANEXO'
GROUP BY 1
ORDER BY 1;
```

### 4. Top 10 projetos por quantidade de anexos (visualização: Bar chart)
```sql
SELECT
    p.NOME AS PROJETO,
    COUNT(*) AS QTD_ANEXOS
FROM MUNKA_GOLD.FCT_EVIDENCIA_TAREFA e
JOIN MUNKA_GOLD.FCT_TAREFA t ON t.ID_TAREFA = e.ID_TAREFA
JOIN MUNKA_GOLD.DIM_PROJETO p ON p.SK_PROJETO = t.SK_PROJETO
WHERE e.TIPO_EVIDENCIA = 'ANEXO'
GROUP BY p.NOME
ORDER BY QTD_ANEXOS DESC
LIMIT 10;
```

### 5. Distribuição por extensão de arquivo (visualização: Pie ou Bar chart)
```sql
SELECT
    COALESCE(EXTENSAO_ARQUIVO, 'sem extensão') AS EXTENSAO,
    COUNT(*) AS QTD
FROM MUNKA_GOLD.FCT_EVIDENCIA_TAREFA
WHERE TIPO_EVIDENCIA = 'ANEXO'
GROUP BY 1
ORDER BY QTD DESC;
```

### 6. Top 10 responsáveis com mais anexos enviados (visualização: Bar chart ou Table)
```sql
SELECT
    u.NOME_COMPLETO AS RESPONSAVEL,
    COUNT(*) AS QTD_ANEXOS
FROM MUNKA_GOLD.FCT_EVIDENCIA_TAREFA e
JOIN MUNKA_GOLD.FCT_TAREFA t ON t.ID_TAREFA = e.ID_TAREFA
JOIN MUNKA_GOLD.DIM_USUARIO u ON u.SK_USUARIO = t.SK_RESPONSAVEL
WHERE e.TIPO_EVIDENCIA = 'ANEXO'
GROUP BY u.NOME_COMPLETO
ORDER BY QTD_ANEXOS DESC
LIMIT 10;
```

## Passo 2 — Montar o dashboard

1. **+ New → Dashboard**.
2. Nome sugerido: `Evidências de Anexo - Tarefas (RAW_TAREFA.EVIDENCIA_ANEXO)`.
3. Adicionar os 6 cards salvos no Passo 1, organizando na seguinte ordem sugerida:
   - Linha 1: cards 1 e 2 (KPIs) lado a lado.
   - Linha 2: card 3 (evolução mensal), ocupando a largura toda.
   - Linha 3: cards 4 e 5 lado a lado (top projetos / extensões).
   - Linha 4: card 6 (top responsáveis).
4. Clicar em **Save**.

## Passo 3 (opcional) — Filtro de dashboard

Para permitir análise por período, adicionar um filtro de dashboard do tipo **Time > Month and Year** (ou **Date range**) mapeado ao campo `DATA_ULTIMA_ATUALIZACAO`/`MES` dos cards 3, 4, 5 e 6.
