



select
    1
from "olist_db"."mart"."mart_product_category"

where not(low_review_rate_pct BETWEEN 0 AND 100)

