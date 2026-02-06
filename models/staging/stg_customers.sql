{{ config(materialized='view') }}

with source_data as (
    select *
    from {{ source('raw', 'raw_customers') }}
),

standardized as (
    select
        customer_id as customer_id_raw,
        upper(nullif(trim(customer_id), '')) as customer_id,
        coalesce(initcap(nullif(trim(first_name), '')), 'Unknown') as first_name,
        coalesce(initcap(nullif(trim(last_name), '')), 'Unknown') as last_name,
        lower(nullif(trim(email), '')) as email,
        nullif(trim(phone), '') as phone,
        try_to_timestamp_ntz(created_at) as created_at,
        try_to_timestamp_ntz(updated_at) as updated_at,
        lower(coalesce(nullif(trim(status), ''), 'unknown')) as customer_status,
        case
            when upper(trim(region)) in ('NORTH AMERICA', 'NA') then 'North America'
            when upper(trim(region)) in ('EMEA') then 'EMEA'
            when upper(trim(region)) in ('APAC') then 'APAC'
            when upper(trim(region)) in ('LATAM', 'LATIN AMERICA') then 'LATAM'
            else 'Unknown'
        end as customer_region,
        iff(lower(coalesce(nullif(trim(status), ''), '')) = 'active', true, false) as is_active
    from source_data
)

select
    customer_id_raw,
    customer_id,
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_key,
    first_name,
    last_name,
    email,
    phone,
    created_at,
    updated_at,
    customer_status,
    customer_region,
    is_active
from standardized
