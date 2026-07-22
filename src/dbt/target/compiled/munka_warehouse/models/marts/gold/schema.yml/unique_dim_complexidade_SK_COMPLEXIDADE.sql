
    
    

select
    SK_COMPLEXIDADE as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_complexidade
where SK_COMPLEXIDADE is not null
group by SK_COMPLEXIDADE
having count(*) > 1


