






    with grouped_expression as (
    select
        
        
    
  
( 1=1 and lifetime_value >= 0 and lifetime_value <= 1000000
)
 as expression


    from ci.main_mart_core.fct_customer_ltv
    

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







