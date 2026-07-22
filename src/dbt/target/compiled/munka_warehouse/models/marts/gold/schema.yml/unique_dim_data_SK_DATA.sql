
    
    

select
    SK_DATA as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_data
where SK_DATA is not null
group by SK_DATA
having count(*) > 1


