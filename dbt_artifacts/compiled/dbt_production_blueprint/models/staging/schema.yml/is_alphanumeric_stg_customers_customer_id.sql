
select *
from ci.main_stg.stg_customers
where customer_id is not null
  and not 
    
    regexp_matches(cast(customer_id as TEXT), '^[A-Za-z0-9]+$')


