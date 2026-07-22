
    
    

select
    SK_UNIDADE as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_unidade
where SK_UNIDADE is not null
group by SK_UNIDADE
having count(*) > 1


