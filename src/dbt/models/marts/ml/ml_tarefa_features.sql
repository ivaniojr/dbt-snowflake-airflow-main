WITH fato AS (
    SELECT * FROM {{ ref('fato_tarefa_evidencia') }}
),
projeto AS (
    SELECT ID, NOME AS NOME_PROJETO FROM {{ ref('stg_projeto') }}
),
sprint AS (
    SELECT ID, OBJETIVOS AS SPRINT_OBJETIVOS FROM {{ ref('stg_sprint') }}
),
regra AS (
    SELECT ID, FATOR_AJUSTE, COMPLEXIDADE_ID, SERVICO_ID FROM {{ ref('stg_regra') }}
),
complexidade AS (
    SELECT ID, NOME AS NOME_COMPLEXIDADE, PONTUACAO_MAIOR_QUE FROM {{ ref('stg_complexidade') }}
)

SELECT
    f.TAREFA_ID,
    -- Contexto da Tarefa
    f.NOME AS NOME_TAREFA,
    p.NOME_PROJETO,
    s.SPRINT_OBJETIVOS,
    
    -- Contexto da Estimativa/Complexidade
    r.FATOR_AJUSTE,
    c.NOME_COMPLEXIDADE,
    c.PONTUACAO_MAIOR_QUE AS PONTUACAO_BASE_COMPLEXIDADE,
    
    -- Features Extraídas das Evidências (Inputs para o Modelo)
    f.QTD_IMAGENS,
    f.QTD_LINKS,
    f.TEM_CODIGO,
    f.TEM_SQL,
    f.TEM_COMMIT,
    f.TEM_ANEXO,
    f.TAMANHO_TEXTO,
    f.SCORE_QUALIDADE_EVIDENCIA,
    
    -- Variáveis Alvo (Targets para Regressão/Previsão)
    f.HORAS_EXECUTADAS,
    f.TOTAL_UST
FROM fato f
LEFT JOIN projeto p ON f.PROJETO_ID = p.ID
LEFT JOIN sprint s ON f.SPRINT_ID = s.ID
LEFT JOIN regra r ON f.REGRA_ID = r.ID
LEFT JOIN complexidade c ON r.COMPLEXIDADE_ID = c.ID
