with core as (
    select sum(net_order_total) as total_revenue
    from {{ ref('fct_orders') }}
    where is_deleted = false
),

finance as (
    select sum(total_revenue) as total_revenue
    from {{ ref('fct_revenue') }}
)

select
    core.total_revenue as core_total_revenue,
    finance.total_revenue as finance_total_revenue,
    abs(core.total_revenue - finance.total_revenue) as revenue_diff
from core, finance
where abs(core.total_revenue - finance.total_revenue) > 0.01
