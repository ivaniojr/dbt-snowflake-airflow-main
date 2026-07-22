
    
    

select
    SK_ORIGEM as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_origem
where SK_ORIGEM is not null
group by SK_ORIGEM
having count(*) > 1


