{{ config(materialized='table') }}

with orders as (
    select
        customer_key,
        sum(net_order_total) as lifetime_value,
        count(distinct order_id) as order_count,
        max(order_date) as last_order_date
    from {{ ref('fct_orders') }}
    where is_deleted = false
    group by 1
)

select
    c.customer_key,
    c.customer_id,
    c.customer_region,
    o.lifetime_value,
    o.order_count,
    o.last_order_date
from {{ ref('dim_customers') }} c
left join orders o
    on c.customer_key = o.customer_key
