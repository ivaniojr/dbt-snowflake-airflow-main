
    
    

select
    SK_USUARIO_REGISTRO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_usuario_registro
where SK_USUARIO_REGISTRO is not null
group by SK_USUARIO_REGISTRO
having count(*) > 1


