
    
    

select
    SK_MOVIMENTO_CONTRATO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.fct_movimento_contrato
where SK_MOVIMENTO_CONTRATO is not null
group by SK_MOVIMENTO_CONTRATO
having count(*) > 1


