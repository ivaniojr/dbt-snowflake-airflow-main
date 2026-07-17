
  
    

        create or replace transient table DRAGON_DB.munka_gold.dim_permissao
         as
        (SELECT HASH('PERMISSAO', ID) AS SK_PERMISSAO, ID AS ID_PERMISSAO, NAME AS NOME, DW_INGESTED_AT AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_ab_permission
        );
      
  