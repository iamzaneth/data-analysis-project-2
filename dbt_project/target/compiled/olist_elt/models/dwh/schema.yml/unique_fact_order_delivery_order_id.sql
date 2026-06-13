
    
    

select
    order_id as unique_field,
    count(*) as n_records

from "olist_db"."dwh"."fact_order_delivery"
where order_id is not null
group by order_id
having count(*) > 1


