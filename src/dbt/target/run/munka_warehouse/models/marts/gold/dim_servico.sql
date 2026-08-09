
  
    

        create or replace transient table DRAGON_DB.munka_gold.dim_servico
         as
        (SELECT
    HASH('SERVICO', S.ID)                                      AS SK_SERVICO,
    S.ID                                                       AS ID_SERVICO,
    S.NOME,
    S.ESCOPO,
    S.ENTREGAVEIS,
    S.ATIVIDADES,
    S.FATURAVEL,
    HASH('CONTRATO', S.CONTRATO_ID)                            AS SK_CONTRATO,
    C.NOME                                                     AS CONTRATO,
    S.DW_INGESTED_AT                                           AS DT_CARGA
FROM DRAGON_DB.munka_stg.stg_servico S
LEFT JOIN DRAGON_DB.munka_stg.stg_contrato C ON C.ID = S.CONTRATO_ID
        );
      
  