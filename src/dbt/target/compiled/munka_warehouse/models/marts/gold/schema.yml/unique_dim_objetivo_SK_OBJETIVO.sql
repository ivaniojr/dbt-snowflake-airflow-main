
    
    

select
    SK_OBJETIVO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_objetivo
where SK_OBJETIVO is not null
group by SK_OBJETIVO
having count(*) > 1


