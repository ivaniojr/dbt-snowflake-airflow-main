
    
    

select
    SK_COORDENACAO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_coordenacao
where SK_COORDENACAO is not null
group by SK_COORDENACAO
having count(*) > 1


