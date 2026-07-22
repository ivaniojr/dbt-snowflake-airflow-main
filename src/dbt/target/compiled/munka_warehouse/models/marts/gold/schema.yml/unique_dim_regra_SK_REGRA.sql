
    
    

select
    SK_REGRA as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_regra
where SK_REGRA is not null
group by SK_REGRA
having count(*) > 1


