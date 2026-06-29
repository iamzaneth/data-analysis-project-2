





with validation_errors as (

    select
        order_id, order_item_id
    from "olist_db"."dwh"."fact_order_item_sales"
    group by order_id, order_item_id
    having count(*) > 1

)

select *
from validation_errors


