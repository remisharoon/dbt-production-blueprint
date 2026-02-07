
    
    

with all_values as (

    select
        payment_status as value_field,
        count(*) as n_records

    from ci.main_stg.stg_payments
    group by payment_status

)

select *
from all_values
where value_field not in (
    'settled','authorized','voided','failed','refunded','chargeback','unknown'
)


