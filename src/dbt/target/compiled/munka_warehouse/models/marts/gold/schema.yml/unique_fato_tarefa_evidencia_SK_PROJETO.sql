
    
    

select
    SK_PROJETO as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.fato_tarefa_evidencia
where SK_PROJETO is not null
group by SK_PROJETO
having count(*) > 1


