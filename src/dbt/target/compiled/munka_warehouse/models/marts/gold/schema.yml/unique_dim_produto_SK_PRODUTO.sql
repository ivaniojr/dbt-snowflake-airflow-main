
    
    

select
    SK_PRODUTO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_produto
where SK_PRODUTO is not null
group by SK_PRODUTO
having count(*) > 1


