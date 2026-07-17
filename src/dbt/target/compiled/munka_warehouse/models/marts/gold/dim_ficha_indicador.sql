SELECT
    HASH('FICHA_INDICADOR', ID)                                AS SK_FICHA_INDICADOR,
    ID                                                         AS ID_FICHA_INDICADOR,
    TITULO,
    GUIA_ID,
    DW_INGESTED_AT                                             AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_ficha_indicador