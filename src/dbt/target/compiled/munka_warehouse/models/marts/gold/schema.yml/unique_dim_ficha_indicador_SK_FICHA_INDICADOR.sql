
    
    

select
    SK_FICHA_INDICADOR as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_ficha_indicador
where SK_FICHA_INDICADOR is not null
group by SK_FICHA_INDICADOR
having count(*) > 1


