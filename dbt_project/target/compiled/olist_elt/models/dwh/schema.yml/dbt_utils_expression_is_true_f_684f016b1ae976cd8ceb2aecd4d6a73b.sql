



select
    1
from "olist_db"."dwh"."fact_order_item_sales"

where not(freight_value >= 0)

