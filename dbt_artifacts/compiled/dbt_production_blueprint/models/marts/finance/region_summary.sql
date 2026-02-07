




        select
            'North America' as region,
            count(distinct f.order_id) as order_count,
            sum(f.net_order_total) as total_revenue
        from ci.main_mart_core.fct_orders f
        join ci.main_mart_core.dim_customers d
            on f.customer_key = d.customer_key
        where d.customer_region = 'North America'
          and f.is_deleted = false
     union all 
        select
            'EMEA' as region,
            count(distinct f.order_id) as order_count,
            sum(f.net_order_total) as total_revenue
        from ci.main_mart_core.fct_orders f
        join ci.main_mart_core.dim_customers d
            on f.customer_key = d.customer_key
        where d.customer_region = 'EMEA'
          and f.is_deleted = false
     union all 
        select
            'APAC' as region,
            count(distinct f.order_id) as order_count,
            sum(f.net_order_total) as total_revenue
        from ci.main_mart_core.fct_orders f
        join ci.main_mart_core.dim_customers d
            on f.customer_key = d.customer_key
        where d.customer_region = 'APAC'
          and f.is_deleted = false
     union all 
        select
            'LATAM' as region,
            count(distinct f.order_id) as order_count,
            sum(f.net_order_total) as total_revenue
        from ci.main_mart_core.fct_orders f
        join ci.main_mart_core.dim_customers d
            on f.customer_key = d.customer_key
        where d.customer_region = 'LATAM'
          and f.is_deleted = false
    