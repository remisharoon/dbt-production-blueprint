






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and net_order_total >= 0 and net_order_total <= 100000
)
 as expression


    from ci.main_mart_core.fct_orders
    

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







