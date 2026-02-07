
select *
from ci.main_stg.stg_payments
where payment_id is not null
  and not 
    
    regexp_matches(cast(payment_id as TEXT), '^[A-Za-z0-9]+$')


