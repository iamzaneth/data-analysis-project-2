



select
    1
from "olist_db"."mart"."mart_payment"

where not(installment_order_rate_pct >= 0 AND <= 100)

