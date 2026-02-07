
    
    

select
    customer_key as unique_field,
    count(*) as n_records

from ci.main_mart_core.fct_customer_ltv
where customer_key is not null
group by customer_key
having count(*) > 1


