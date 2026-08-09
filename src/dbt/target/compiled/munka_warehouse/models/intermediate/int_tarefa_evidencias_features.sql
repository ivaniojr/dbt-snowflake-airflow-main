WITH source AS (
    SELECT
        ID AS TAREFA_ID,
        EVIDENCIAS,
        EVIDENCIA_COMMIT_SHA,
        EVIDENCIA_ANEXO
    FROM DRAGON_DB.munka_stg.stg_tarefa
),
parsed AS (
    SELECT
        TAREFA_ID,
        -- Contagens via expressões regulares (ignorando case)
        REGEXP_COUNT(EVIDENCIAS, '<img[^>]+>', 1, 'i') AS QTD_IMAGENS,
        REGEXP_COUNT(EVIDENCIAS, '<a[^>]+href=', 1, 'i') AS QTD_LINKS,
        
        -- Flags booleanas (1 ou 0)
        IFF(REGEXP_LIKE(EVIDENCIAS, '.*<(code|pre)[^>]*>.*', 'is'), 1, 0) AS TEM_CODIGO,
        IFF(REGEXP_LIKE(EVIDENCIAS, '.*\\b(SELECT|UPDATE|INSERT|DELETE|CREATE|DROP|ALTER)\\b.*', 'is'), 1, 0) AS TEM_SQL,
        
        -- Commit: se tiver SHA no campo específico ou encontrar um hash git
        IFF(
            EVIDENCIA_COMMIT_SHA IS NOT NULL OR 
            REGEXP_LIKE(EVIDENCIAS, '.*([a-f0-9]{7,40}|github\\.com|gitlab\\.com).*', 'is'), 
            1, 0
        ) AS TEM_COMMIT,
        
        -- Anexo:
        IFF(EVIDENCIA_ANEXO IS NOT NULL, 1, 0) AS TEM_ANEXO,
        
        -- Novas métricas: Detecção de Tecnologias (Tech Stack)
        IFF(REGEXP_LIKE(EVIDENCIAS, '.*\\b(react|vue|angular|html|css|javascript|typescript)\\b.*', 'is'), 1, 0) AS FL_ENVOLVE_FRONTEND,
        IFF(REGEXP_LIKE(EVIDENCIAS, '.*\\b(python|java|php|c#|node|golang)\\b.*', 'is'), 1, 0) AS FL_ENVOLVE_BACKEND,
        IFF(REGEXP_LIKE(EVIDENCIAS, '.*\\b(sql|pandas|snowflake|aws|airflow|dbt)\\b.*', 'is'), 1, 0) AS FL_ENVOLVE_DADOS,

        -- Novas métricas: Classificador de Erros/Bugs
        IFF(REGEXP_LIKE(EVIDENCIAS, '.*\\b(exception|traceback|nullpointer|erro|bug|falha|corrigido|fix)\\b.*', 'is'), 1, 0) AS FL_IS_BUGFIX,

        -- Novas métricas: Estruturais e Compliance de PR
        REGEXP_COUNT(EVIDENCIAS, '<(code|pre)[^>]*>', 1, 'i') AS QTD_BLOCOS_CODIGO,
        IFF(REGEXP_LIKE(EVIDENCIAS, '.*(github\\.com/.*/pull/|gitlab\\.com/.*/merge_requests/).*', 'is'), 1, 0) AS FL_TEM_PULL_REQUEST,

        -- Tamanho do texto puro
        LENGTH(NVL(EVIDENCIAS, '')) AS TAMANHO_TEXTO
    FROM source
),
scored AS (
    SELECT
        TAREFA_ID,
        QTD_IMAGENS,
        QTD_LINKS,
        TEM_CODIGO,
        TEM_SQL,
        TEM_COMMIT,
        TEM_ANEXO,
        FL_ENVOLVE_FRONTEND,
        FL_ENVOLVE_BACKEND,
        FL_ENVOLVE_DADOS,
        FL_IS_BUGFIX,
        QTD_BLOCOS_CODIGO,
        FL_TEM_PULL_REQUEST,
        TAMANHO_TEXTO,
        -- Score heurístico básico para ML (Feature Engineering)
        (
            (QTD_IMAGENS * 2) + 
            (QTD_LINKS * 1) + 
            (QTD_BLOCOS_CODIGO * 3) + 
            (TEM_SQL * 2) + 
            (TEM_COMMIT * 2) +
            (FL_TEM_PULL_REQUEST * 5) + 
            (TEM_ANEXO * 3) +
            (FL_IS_BUGFIX * 2) +
            IFF(TAMANHO_TEXTO > 100, 1, 0)
        ) AS SCORE_QUALIDADE_EVIDENCIA
    FROM parsed
)

SELECT * FROM scored