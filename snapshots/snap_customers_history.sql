{% snapshot snap_customers_history %}

{{
    config(
      target_schema='snapshots',
      unique_key='customer_id',
      strategy='timestamp',
      updated_at='updated_at',
      invalidate_hard_deletes=true
    )
}}

select
    customer_id,
    first_name,
    last_name,
    email,
    phone,
    customer_status,
    customer_region,
    is_active,
    updated_at
from {{ ref('stg_customers') }}

{% endsnapshot %}
