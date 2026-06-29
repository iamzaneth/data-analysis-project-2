



select
    1
from "olist_db"."mart"."mart_seller_performance"

where not(low_review_rate_pct >= 0 AND <= 100)

