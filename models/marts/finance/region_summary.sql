{{ config(materialized='table') }}

{% set region_list = var('regions', []) %}
{% if region_list | length == 0 %}
    {% set region_list = dbt_utils.get_column_values(ref('dim_customers'), 'customer_region') %}
{% endif %}

{{ generate_region_summary_sql(region_list) }}
