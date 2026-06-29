



select
    1
from "olist_db"."mart"."mart_payment"

where not(avg_payment_value >= 0)

