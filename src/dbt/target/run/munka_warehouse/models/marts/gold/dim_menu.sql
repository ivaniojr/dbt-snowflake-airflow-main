
  
    

        create or replace transient table DRAGON_DB.munka_gold.dim_menu
         as
        (SELECT HASH('MENU', ID) AS SK_MENU, ID AS ID_MENU, NAME AS NOME, DW_INGESTED_AT AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_ab_view_menu
        );
      
  