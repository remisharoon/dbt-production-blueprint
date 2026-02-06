{% macro generate_region_summary_sql(regions) %}
{% if regions is none or regions | length == 0 %}
    {% set regions = ['Unknown'] %}
{% endif %}

{% set statements = [] %}
{% for region in regions %}
    {% set stmt %}
        select
            '{{ region }}' as region,
            count(distinct f.order_id) as order_count,
            sum(f.net_order_total) as total_revenue
        from {{ ref('fct_orders') }} f
        join {{ ref('dim_customers') }} d
            on f.customer_key = d.customer_key
        where d.customer_region = '{{ region }}'
          and f.is_deleted = false
    {% endset %}
    {% do statements.append(stmt) %}
{% endfor %}

{{ return(statements | join(' union all ')) }}
{% endmacro %}
