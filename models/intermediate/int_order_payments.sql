{{ config(materialized='view') }}

with orders as (
    select
        order_id,
        order_total,
        currency,
        updated_at,
        is_deleted
    from {{ ref('stg_orders') }}
),

payments as (
    select
        payment_id,
        order_id,
        amount,
        payment_status,
        payment_date
    from {{ ref('stg_payments') }}
),

aggregated as (
    select
        o.order_id,
        o.order_total,
        o.currency,
        o.updated_at,
        o.is_deleted,
        coalesce(sum(p.amount), 0.00) as total_paid_amount,
        max(p.payment_date) as last_payment_date,
        count(p.payment_id) as payment_count,
        max(case when p.payment_status in ('refunded', 'chargeback') then 1 else 0 end) as has_refund_or_chargeback_flag
    from orders o
    left join payments p
        on o.order_id = p.order_id
    group by 1, 2, 3, 4, 5
)

select
    order_id,
    order_total,
    currency,
    updated_at,
    is_deleted,
    total_paid_amount,
    last_payment_date,
    payment_count,
    has_refund_or_chargeback_flag = 1 as has_refund_or_chargeback,
    case
        when total_paid_amount = 0 then 'unpaid'
        when total_paid_amount < order_total then 'partial'
        when total_paid_amount >= order_total then 'paid'
        else 'unknown'
    end as payment_coverage_status
from aggregated
