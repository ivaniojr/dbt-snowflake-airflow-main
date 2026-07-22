
    
    

select
    SK_CARGO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_cargo
where SK_CARGO is not null
group by SK_CARGO
having count(*) > 1


