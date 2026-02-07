



with orders as (
    select
        order_id,
        order_status
    from ci.main_stg.stg_orders
)

select
    order_id,
    order_status,
    
case

    when lower(order_status) in (
        
            'completed', 
        
            'shipped', 
        
            'delivered'
        
    ) then 'completed'

    when lower(order_status) in (
        
            'created', 
        
            'pending', 
        
            'processing'
        
    ) then 'open'

    when lower(order_status) in (
        
            'cancelled', 
        
            'canceled', 
        
            'refunded', 
        
            'chargeback'
        
    ) then 'canceled'

    else 'other'
end
 as order_status_group
from orders