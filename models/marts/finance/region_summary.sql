{{ config(materialized='table') }}

{% set region_list = var('regions', ['North America', 'EMEA', 'APAC', 'LATAM', 'Unknown']) %}

{{ generate_region_summary_sql(region_list) }}
