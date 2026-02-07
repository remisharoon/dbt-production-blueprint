

with orders as (
    select *
    from ci.main_stg.stg_orders

    
),

payments as (
    select *
    from ci.main_int.int_order_payments
),

status_map as (
    select *
    from ci.main_int.int_order_status_categorized
),

dim_customers as (
    select customer_id, customer_key
    from ci.main_mart_core.dim_customers
),

joined as (
    select
        o.order_id,
        o.order_key,
        dc.customer_key,
        o.customer_id,
        o.order_date,
        o.updated_at,
        o.order_status,
        sm.order_status_group,
        o.order_total,
        o.currency,
        p.total_paid_amount,
        p.payment_coverage_status,
        p.payment_count,
        p.last_payment_date,
        p.has_refund_or_chargeback,
        o.is_deleted,
        case when o.is_deleted then now() else null end as deleted_at,
        case when o.is_deleted then 0 else o.order_total end as net_order_total
    from orders o
    left join payments p
        on o.order_id = p.order_id
    left join status_map sm
        on o.order_id = sm.order_id
    left join dim_customers dc
        on o.customer_id = dc.customer_id
)

select *
from joined