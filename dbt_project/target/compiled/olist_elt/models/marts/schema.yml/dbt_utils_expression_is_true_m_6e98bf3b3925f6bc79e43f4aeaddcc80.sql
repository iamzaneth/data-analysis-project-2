



select
    1
from "olist_db"."mart"."mart_sales"

where not(freight_to_gmv_pct BETWEEN 0 AND 100)

