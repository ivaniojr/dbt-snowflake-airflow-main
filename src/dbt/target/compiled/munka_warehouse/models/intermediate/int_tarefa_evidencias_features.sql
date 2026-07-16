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
        TAMANHO_TEXTO,
        -- Score heurístico básico para ML (Feature Engineering)
        (
            (QTD_IMAGENS * 2) + 
            (QTD_LINKS * 1) + 
            (TEM_CODIGO * 3) + 
            (TEM_SQL * 2) + 
            (TEM_COMMIT * 5) +
            (TEM_ANEXO * 3) +
            IFF(TAMANHO_TEXTO > 100, 1, 0)
        ) AS SCORE_QUALIDADE_EVIDENCIA
    FROM parsed
)

SELECT * FROM scored