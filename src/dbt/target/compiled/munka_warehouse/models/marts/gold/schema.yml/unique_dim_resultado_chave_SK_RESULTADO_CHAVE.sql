
    
    

select
    SK_RESULTADO_CHAVE as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_resultado_chave
where SK_RESULTADO_CHAVE is not null
group by SK_RESULTADO_CHAVE
having count(*) > 1


