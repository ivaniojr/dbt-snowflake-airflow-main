
    
    

select
    SK_CONTRATO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.fct_contrato
where SK_CONTRATO is not null
group by SK_CONTRATO
having count(*) > 1


