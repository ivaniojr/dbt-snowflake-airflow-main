
    
    

select
    SK_REQUISITO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_requisito
where SK_REQUISITO is not null
group by SK_REQUISITO
having count(*) > 1


