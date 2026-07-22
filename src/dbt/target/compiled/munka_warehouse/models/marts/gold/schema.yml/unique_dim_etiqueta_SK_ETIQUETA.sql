
    
    

select
    SK_ETIQUETA as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_etiqueta
where SK_ETIQUETA is not null
group by SK_ETIQUETA
having count(*) > 1


