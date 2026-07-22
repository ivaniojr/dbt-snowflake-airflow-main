
    
    

select
    SK_ROLE as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_role
where SK_ROLE is not null
group by SK_ROLE
having count(*) > 1


