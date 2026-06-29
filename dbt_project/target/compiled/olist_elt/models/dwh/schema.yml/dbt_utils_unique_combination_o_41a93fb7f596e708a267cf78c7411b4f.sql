





with validation_errors as (

    select
        review_id, order_id
    from "olist_db"."dwh"."fact_reviews"
    group by review_id, order_id
    having count(*) > 1

)

select *
from validation_errors


