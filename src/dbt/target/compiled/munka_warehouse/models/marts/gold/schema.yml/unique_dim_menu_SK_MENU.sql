
    
    

select
    SK_MENU as unique_field,
    count(*) as n_records

from DRAGON_DB.munka_gold.dim_menu
where SK_MENU is not null
group by SK_MENU
having count(*) > 1


