{{ config(materialized='view') }}

{% set status_groups = {
    'completed': ['completed', 'shipped', 'delivered'],
    'open': ['created', 'pending', 'processing'],
    'canceled': ['cancelled', 'canceled', 'refunded', 'chargeback']
} %}

with orders as (
    select
        order_id,
        order_status
    from {{ ref('stg_orders') }}
)

select
    order_id,
    order_status,
    {{ order_status_case(status_groups, 'order_status') }} as order_status_group
from orders
