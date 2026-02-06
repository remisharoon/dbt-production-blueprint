{{ config(materialized='view') }}

with source_data as (
    select *
    from {{ source('raw', 'raw_orders') }}
),

standardized as (
    select
        order_id as order_id_raw,
        upper(nullif(trim(order_id), '')) as order_id,
        upper(nullif(trim(customer_id), '')) as customer_id,
        try_to_date(order_date) as order_date,
        try_to_timestamp_ntz(updated_at) as updated_at,
        lower(coalesce(nullif(trim(order_status), ''), 'unknown')) as order_status,
        coalesce(try_to_decimal(order_total, 12, 2), 0.00) as order_total,
        upper(coalesce(nullif(trim(currency), ''), 'USD')) as currency,
        iff(lower(coalesce(nullif(trim(is_deleted), ''), 'false')) in ('true', '1', 'yes', 'y'), true, false) as is_deleted
    from source_data
)

select
    order_id_raw,
    order_id,
    customer_id,
    {{ dbt_utils.generate_surrogate_key(['order_id']) }} as order_key,
    order_date,
    updated_at,
    order_status,
    order_total,
    currency,
    is_deleted
from standardized
