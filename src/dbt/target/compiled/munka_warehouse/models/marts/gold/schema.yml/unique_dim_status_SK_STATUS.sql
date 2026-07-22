
    
    

select
    SK_STATUS as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_status
where SK_STATUS is not null
group by SK_STATUS
having count(*) > 1


