
    
    

select
    SK_CENARIO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_cenario
where SK_CENARIO is not null
group by SK_CENARIO
having count(*) > 1


