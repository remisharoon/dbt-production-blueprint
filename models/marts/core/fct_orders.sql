{{ config(
    materialized='incremental',
    unique_key='order_id',
    incremental_strategy='merge',
    on_schema_change='fail',
    cluster_by=['updated_at']
) }}

with orders as (
    select *
    from {{ ref('stg_orders') }}

    {% if is_incremental() %}
    where updated_at >= (
        select coalesce(max(updated_at), to_timestamp_ntz('1900-01-01'))
        from {{ this }}
    )
    {% endif %}
),

payments as (
    select *
    from {{ ref('int_order_payments') }}
),

status_map as (
    select *
    from {{ ref('int_order_status_categorized') }}
),

dim_customers as (
    select customer_id, customer_key
    from {{ ref('dim_customers') }}
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
        case when o.is_deleted then current_timestamp() else null end as deleted_at,
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
