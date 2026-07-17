SELECT
    HASH('COMENTARIO', C.ID)                                   AS SK_COMENTARIO,
    C.ID                                                       AS ID_COMENTARIO,
    HASH('TAREFA', C.TAREFA_ID)                                AS SK_TAREFA,
    HASH('USUARIO', C.AUTOR_ID)                                AS SK_AUTOR,
    HASH('UNIDADE', C.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    IFF(C.HORARIO IS NULL, NULL, TO_NUMBER(TO_CHAR(C.HORARIO::DATE, 'YYYYMMDD'))) AS SK_DATA_COMENTARIO,
    C.HORARIO,
    C.CONTEUDO,
    LENGTH(C.CONTEUDO)                                         AS QUANTIDADE_CARACTERES,
    REGEXP_COUNT(TRIM(C.CONTEUDO), '\\S+')                   AS QUANTIDADE_PALAVRAS,
    C.ID_COMENTARIO_OLD,
    C.DW_INGESTED_AT                                           AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_comentario C