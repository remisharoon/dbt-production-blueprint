

with base as (
    select
        order_id,
        order_date,
        currency,
        customer_key,
        net_order_total
    from ci.main_mart_core.fct_orders
    where is_deleted = false
),

customers as (
    select
        customer_key,
        customer_region
    from ci.main_mart_core.dim_customers
)

select
    b.order_date,
    b.currency,
    c.customer_region,
    sum(b.net_order_total) as total_revenue,
    count(distinct b.order_id) as order_count
from base b
left join customers c
    on b.customer_key = c.customer_key
group by 1, 2, 3