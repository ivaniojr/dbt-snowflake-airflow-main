
  
    

        create or replace transient table DRAGON_DB.munka_gold.dim_role
         as
        (SELECT HASH('ROLE', ID) AS SK_ROLE, ID AS ID_ROLE, NAME AS NOME, DW_INGESTED_AT AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_ab_role
        );
      
  