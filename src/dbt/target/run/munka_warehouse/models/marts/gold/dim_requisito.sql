
  
    

        create or replace transient table DRAGON_DB.munka_gold.dim_requisito
         as
        (SELECT
    HASH('REQUISITO', R.ID)                                    AS SK_REQUISITO,
    R.ID                                                       AS ID_REQUISITO,
    R.NOME,
    HASH('UNIDADE', R.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    R.DW_INGESTED_AT                                           AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_requisito R
LEFT JOIN DRAGON_DB.munka_stg.stg_unidade_adm U ON U.ID = R.UNIDADE_ADM_ID
        );
      
  