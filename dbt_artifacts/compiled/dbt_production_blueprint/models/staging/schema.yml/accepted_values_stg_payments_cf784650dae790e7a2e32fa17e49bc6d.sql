
    
    

with all_values as (

    select
        payment_method as value_field,
        count(*) as n_records

    from ci.main_stg.stg_payments
    group by payment_method

)

select *
from all_values
where value_field not in (
    'card','paypal','unknown'
)


