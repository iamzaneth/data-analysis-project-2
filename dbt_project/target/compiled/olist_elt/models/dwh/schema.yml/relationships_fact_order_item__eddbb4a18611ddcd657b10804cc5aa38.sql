
    
    

with child as (
    select product_key as from_field
    from "olist_db"."dwh"."fact_order_item_sales"
    where product_key is not null
),

parent as (
    select product_key as to_field
    from "olist_db"."dwh"."dim_product"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


