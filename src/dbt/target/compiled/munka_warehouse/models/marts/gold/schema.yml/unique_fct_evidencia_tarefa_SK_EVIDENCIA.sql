
    
    

select
    SK_EVIDENCIA as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.fct_evidencia_tarefa
where SK_EVIDENCIA is not null
group by SK_EVIDENCIA
having count(*) > 1


