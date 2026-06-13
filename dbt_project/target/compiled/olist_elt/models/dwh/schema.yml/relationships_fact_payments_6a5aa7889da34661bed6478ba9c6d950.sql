
    
    

with child as (
    select payment_type_key as from_field
    from "olist_db"."dwh"."fact_payments"
    where payment_type_key is not null
),

parent as (
    select payment_type_key as to_field
    from "olist_db"."dwh"."dim_payment_type"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


