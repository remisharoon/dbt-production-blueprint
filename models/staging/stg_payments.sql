{{ config(materialized='view') }}

with source_data as (
    select *
    from {{ source('raw', 'raw_payments') }}
),

standardized as (
    select
        payment_id as payment_id_raw,
        upper(nullif(trim(payment_id), '')) as payment_id,
        upper(nullif(trim(order_id), '')) as order_id,
        cast(nullif(trim(cast(payment_date as text)), '') as date) as payment_date,
        lower(coalesce(nullif(trim(payment_method), ''), 'unknown')) as payment_method,
         coalesce(cast(nullif(trim(cast(amount as text)), '') as numeric(12, 2)), 0.00) as amount,
        lower(coalesce(nullif(trim(status), ''), 'unknown')) as payment_status,
        nullif(trim(provider_txn_id), '') as provider_txn_id
    from source_data
)

select
    payment_id_raw,
    payment_id,
    order_id,
    {{ dbt_utils.generate_surrogate_key(['payment_id']) }} as payment_key,
    payment_date,
    payment_method,
    amount,
    payment_status,
    provider_txn_id
from standardized
