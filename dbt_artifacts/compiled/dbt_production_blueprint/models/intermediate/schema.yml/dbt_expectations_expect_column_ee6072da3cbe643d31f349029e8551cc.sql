






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and total_paid_amount >= 0 and total_paid_amount <= 100000
)
 as expression


    from ci.main_int.int_order_payments
    

),
validation_errors as (

    select
        *
    from
        grouped_expression
    where
        not(expression = true)

)

select *
from validation_errors







