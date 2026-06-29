
    
    

with child as (
    select order_status_key as from_field
    from "olist_db"."dwh"."fact_order_delivery"
    where order_status_key is not null
),

parent as (
    select order_status_key as to_field
    from "olist_db"."dwh"."dim_order_status"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


