






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and amount >= 0 and amount <= 100000
)
 as expression


    from ci.main_stg.stg_payments
    

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







