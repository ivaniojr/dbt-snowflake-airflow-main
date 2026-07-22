
    
    

select
    SK_COMENTARIO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.fct_comentario
where SK_COMENTARIO is not null
group by SK_COMENTARIO
having count(*) > 1


