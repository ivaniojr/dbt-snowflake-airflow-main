
  
    

        create or replace transient table DRAGON_DB.munka_ml.ml_tarefa_features
         as
        (WITH fato AS (
    SELECT * FROM DRAGON_DB.munka_gold.fato_tarefa_evidencia
),
projeto AS (
    SELECT SK_PROJETO, NOME AS NOME_PROJETO FROM DRAGON_DB.munka_gold.dim_projeto
),
sprint AS (
    SELECT SK_SPRINT, OBJETIVOS AS SPRINT_OBJETIVOS FROM DRAGON_DB.munka_gold.dim_sprint
),
regra AS (
    SELECT SK_REGRA, FATOR_AJUSTE, COMPLEXIDADE AS NOME_COMPLEXIDADE, HET_MAX FROM DRAGON_DB.munka_gold.dim_regra
)

SELECT
    f.TAREFA_ID,
    -- Contexto da Tarefa
    f.NOME AS NOME_TAREFA,
    p.NOME_PROJETO,
    s.SPRINT_OBJETIVOS,
    
    -- Contexto da Estimativa/Complexidade
    r.FATOR_AJUSTE,
    r.NOME_COMPLEXIDADE,
    r.HET_MAX,
    
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
LEFT JOIN projeto p ON f.SK_PROJETO = p.SK_PROJETO
LEFT JOIN sprint s ON f.SK_SPRINT = s.SK_SPRINT
LEFT JOIN regra r ON f.SK_REGRA = r.SK_REGRA
        );
      
  