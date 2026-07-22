
    
    

select
    SK_SPRINT as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.fct_sprint
where SK_SPRINT is not null
group by SK_SPRINT
having count(*) > 1


