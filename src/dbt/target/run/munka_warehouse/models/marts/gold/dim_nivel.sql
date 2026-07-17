
  
    

        create or replace transient table DRAGON_DB.munka_gold.dim_nivel
         as
        (SELECT HASH('NIVEL', ID) AS SK_NIVEL, ID AS ID_NIVEL, NOME, DW_INGESTED_AT AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_nivel
        );
      
  