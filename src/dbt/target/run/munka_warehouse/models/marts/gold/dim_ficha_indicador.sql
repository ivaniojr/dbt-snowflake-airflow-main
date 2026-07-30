
  
    

        create or replace transient table GIRAFFE_DB.munka_gold.dim_ficha_indicador
         as
        (SELECT
    HASH('FICHA_INDICADOR', ID)                                AS SK_FICHA_INDICADOR,
    ID                                                         AS ID_FICHA_INDICADOR,
    TITULO,
    GUIA_ID,
    DW_INGESTED_AT                                             AS DT_CARGA
FROM GIRAFFE_DB.munka_stg.stg_ficha_indicador
        );
      
  