
    
    

select
    order_id as unique_field,
    count(*) as n_records

from ci.main_int.int_order_payments
where order_id is not null
group by order_id
having count(*) > 1


