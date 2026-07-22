
    
    

select
    SK_SERVICO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_servico
where SK_SERVICO is not null
group by SK_SERVICO
having count(*) > 1


