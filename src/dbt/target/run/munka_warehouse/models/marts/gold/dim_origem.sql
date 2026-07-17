
  
    

        create or replace transient table DRAGON_DB.munka_gold.dim_origem
         as
        (SELECT
    HASH('ORIGEM', O.ID)                                       AS SK_ORIGEM,
    O.ID                                                       AS ID_ORIGEM,
    O.NOME,
    O.ENDERECO,
    O.DESCRICAO,
    HASH('UNIDADE', O.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    O.DW_INGESTED_AT                                           AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_origem O
LEFT JOIN DRAGON_DB.munka_stg.stg_unidade_adm U ON U.ID = O.UNIDADE_ADM_ID
        );
      
  