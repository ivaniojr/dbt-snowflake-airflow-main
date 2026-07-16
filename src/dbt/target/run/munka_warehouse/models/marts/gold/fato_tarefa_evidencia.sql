
  
    

        create or replace transient table DRAGON_DB.munka_gold.fato_tarefa_evidencia
         as
        (WITH tarefa AS (
    SELECT
        ID AS TAREFA_ID,
        NOME,
        PROJETO_ID,
        SPRINT_ID,
        RESPONSAVEL_ID,
        STATUS_ID,
        REGRA_ID,
        DATA_INICIO,
        DATA_FIM,
        HORAS_EXECUTADAS,
        TOTAL_UST
    FROM DRAGON_DB.munka_stg.stg_tarefa
),
evidencias AS (
    SELECT
        TAREFA_ID,
        QTD_IMAGENS,
        QTD_LINKS,
        TEM_CODIGO,
        TEM_SQL,
        TEM_COMMIT,
        TEM_ANEXO,
        TAMANHO_TEXTO,
        SCORE_QUALIDADE_EVIDENCIA
    FROM DRAGON_DB.munka_int.int_tarefa_evidencias_features
)

SELECT
    t.TAREFA_ID,
    t.NOME,
    t.PROJETO_ID,
    t.SPRINT_ID,
    t.RESPONSAVEL_ID,
    t.STATUS_ID,
    t.REGRA_ID,
    t.DATA_INICIO,
    t.DATA_FIM,
    t.HORAS_EXECUTADAS,
    t.TOTAL_UST,
    e.QTD_IMAGENS,
    e.QTD_LINKS,
    e.TEM_CODIGO,
    e.TEM_SQL,
    e.TEM_COMMIT,
    e.TEM_ANEXO,
    e.TAMANHO_TEXTO,
    e.SCORE_QUALIDADE_EVIDENCIA
FROM tarefa t
LEFT JOIN evidencias e
    ON t.TAREFA_ID = e.TAREFA_ID
        );
      
  