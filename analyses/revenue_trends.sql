-- Example ad-hoc analysis of revenue trends by region
select
    order_date,
    customer_region,
    sum(total_revenue) as total_revenue
from {{ ref('fct_revenue') }}
group by 1, 2
order by 1, 2
