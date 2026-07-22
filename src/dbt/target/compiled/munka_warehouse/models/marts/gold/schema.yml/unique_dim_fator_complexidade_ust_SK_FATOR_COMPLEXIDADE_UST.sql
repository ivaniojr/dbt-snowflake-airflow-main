
    
    

select
    SK_FATOR_COMPLEXIDADE_UST as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_fator_complexidade_ust
where SK_FATOR_COMPLEXIDADE_UST is not null
group by SK_FATOR_COMPLEXIDADE_UST
having count(*) > 1


