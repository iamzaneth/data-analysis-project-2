



select
    1
from "olist_db"."mart"."mart_seller_performance"

where not(late_rate_pct >= 0 AND <= 100)

