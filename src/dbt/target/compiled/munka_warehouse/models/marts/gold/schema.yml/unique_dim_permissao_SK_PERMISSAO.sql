
    
    

select
    SK_PERMISSAO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_permissao
where SK_PERMISSAO is not null
group by SK_PERMISSAO
having count(*) > 1


