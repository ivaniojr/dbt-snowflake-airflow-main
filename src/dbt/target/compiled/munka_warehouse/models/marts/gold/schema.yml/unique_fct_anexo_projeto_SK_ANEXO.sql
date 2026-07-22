
    
    

select
    SK_ANEXO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.fct_anexo_projeto
where SK_ANEXO is not null
group by SK_ANEXO
having count(*) > 1


