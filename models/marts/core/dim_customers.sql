{{ config(
    materialized='table',
    post_hook="grant select on {{ this }} to role reporter"
) }}

with ranked as (
    select
        customer_key,
        customer_id,
        first_name,
        last_name,
        email,
        phone,
        created_at,
        updated_at,
        customer_status,
        customer_region,
        is_active,
        row_number() over (partition by customer_id order by updated_at desc nulls last) as rn
    from {{ ref('stg_customers') }}
)

select
    customer_key,
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    created_at,
    updated_at,
    customer_status,
    customer_region,
    is_active
from ranked
where rn = 1
