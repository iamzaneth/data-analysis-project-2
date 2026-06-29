



select
    1
from "olist_db"."mart"."mart_customer_satisfaction"

where not(high_review_rate_pct >= 0 AND <= 100)

