
    
    

select
    SK_FATURA as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.fct_fatura
where SK_FATURA is not null
group by SK_FATURA
having count(*) > 1


