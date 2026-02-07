






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and order_total >= 0 and order_total <= 100000
)
 as expression


    from ci.main_stg.stg_orders
    

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







