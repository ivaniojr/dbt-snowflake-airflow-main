
  
    

        create or replace transient table DRAGON_DB.munka_gold.dim_contrato
         as
        (SELECT
    HASH('CONTRATO', C.ID)                                     AS SK_CONTRATO,
    C.ID                                                       AS ID_CONTRATO,
    C.NOME,
    C.ATIVO                                                    AS FL_ATIVO,
    C.UST_VALOR,
    C.UST_CONTRATADAS,
    C.UST_ADITIVADAS,
    C.DEDUCOES_HORAS,
    C.DEDUCOES_UST,
    C.OUTROS_HORAS,
    C.OUTROS_UST,
    C.DATA_INICIO,
    C.DATA_FIM,
    C.DATA_VIGENCIA,
    C.FATURAR_HPA,
    HASH('UNIDADE', C.UNIDADE_ADM_ID)                          AS SK_UNIDADE,
    U.NOME_UNIDADE,
    C.DW_INGESTED_AT                                           AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_contrato C
LEFT JOIN DRAGON_DB.munka_stg.stg_unidade_adm U ON U.ID = C.UNIDADE_ADM_ID
        );
      
  