





with validation_errors as (

    select
        order_id, payment_sequential
    from "olist_db"."dwh"."fact_payments"
    group by order_id, payment_sequential
    having count(*) > 1

)

select *
from validation_errors


