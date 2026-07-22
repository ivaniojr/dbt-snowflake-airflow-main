
    
    

select
    SK_TAREFA as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.fct_tarefa
where SK_TAREFA is not null
group by SK_TAREFA
having count(*) > 1


