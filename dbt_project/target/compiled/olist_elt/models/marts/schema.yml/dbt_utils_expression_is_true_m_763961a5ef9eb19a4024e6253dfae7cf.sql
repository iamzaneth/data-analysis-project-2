



select
    1
from "olist_db"."mart"."mart_logistics"

where not(late_rate_pct >= 0 AND <= 100)

