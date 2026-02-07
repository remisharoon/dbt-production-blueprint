
select *
from ci.main_stg.stg_orders
where order_id is not null
  and not 
    
    regexp_matches(cast(order_id as TEXT), '^[A-Za-z0-9]+$')


