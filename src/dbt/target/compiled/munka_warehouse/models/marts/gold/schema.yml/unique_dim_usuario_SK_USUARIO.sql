
    
    

select
    SK_USUARIO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_usuario
where SK_USUARIO is not null
group by SK_USUARIO
having count(*) > 1


