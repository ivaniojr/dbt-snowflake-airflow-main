
    
    

select
    SK_UNIDADE_SUPERIOR as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_unidade_superior
where SK_UNIDADE_SUPERIOR is not null
group by SK_UNIDADE_SUPERIOR
having count(*) > 1


