
  
    

        create or replace transient table DRAGON_DB.munka_gold.dim_objetivo
         as
        (SELECT
    HASH('OBJETIVO', O.ID)                                     AS SK_OBJETIVO,
    O.ID                                                       AS ID_OBJETIVO,
    O.NUMERO,
    O.TITULO,
    O.DESCRICAO,
    HASH('UNIDADE', O.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    O.DW_INGESTED_AT                                           AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_objetivo O
LEFT JOIN DRAGON_DB.munka_stg.stg_unidade_adm U ON U.ID = O.UNIDADE_ADM_ID
        );
      
  