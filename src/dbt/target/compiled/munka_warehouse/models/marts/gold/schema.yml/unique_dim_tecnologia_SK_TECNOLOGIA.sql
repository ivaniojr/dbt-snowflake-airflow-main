
    
    

select
    SK_TECNOLOGIA as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_tecnologia
where SK_TECNOLOGIA is not null
group by SK_TECNOLOGIA
having count(*) > 1


