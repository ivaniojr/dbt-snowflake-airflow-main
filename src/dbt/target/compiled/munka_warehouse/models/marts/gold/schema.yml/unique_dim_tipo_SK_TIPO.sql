
    
    

select
    SK_TIPO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_tipo
where SK_TIPO is not null
group by SK_TIPO
having count(*) > 1


