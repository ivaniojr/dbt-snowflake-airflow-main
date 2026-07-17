SELECT
    HASH('ANEXO', A.ID)                                        AS SK_ANEXO,
    A.ID                                                       AS ID_ANEXO,
    HASH('PROJETO', A.PROJETO_ID)                              AS SK_PROJETO,
    IFF(A.HORARIO IS NULL, NULL, TO_NUMBER(TO_CHAR(A.HORARIO::DATE, 'YYYYMMDD'))) AS SK_DATA_ANEXO,
    A.DESCRICAO,
    A.ARQUIVO,
    REGEXP_SUBSTR(LOWER(A.ARQUIVO), '\\.(png|jpg|jpeg|gif|webp|bmp|svg|pdf|docx?|xlsx?|zip)(\\?|$)', 1, 1, 'e', 1) AS EXTENSAO_ARQUIVO,
    IFF(REGEXP_LIKE(LOWER(A.ARQUIVO), '\\.(png|jpg|jpeg|gif|webp|bmp|svg)(\\?|$)'), TRUE, FALSE) AS FL_IMAGEM,
    A.HORARIO,
    A.DW_INGESTED_AT                                           AS DT_CARGA
FROM {{ ref('stg_anexos') }} A
