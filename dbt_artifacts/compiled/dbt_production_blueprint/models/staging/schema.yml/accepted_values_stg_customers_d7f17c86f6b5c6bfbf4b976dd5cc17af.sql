
    
    

with all_values as (

    select
        customer_region as value_field,
        count(*) as n_records

    from ci.main_stg.stg_customers
    group by customer_region

)

select *
from all_values
where value_field not in (
    'North America','EMEA','APAC','LATAM','Unknown'
)


