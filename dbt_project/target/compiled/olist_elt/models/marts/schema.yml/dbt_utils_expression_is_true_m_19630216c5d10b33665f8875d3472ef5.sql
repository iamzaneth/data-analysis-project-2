



select
    1
from "olist_db"."mart"."mart_payment"

where not(total_payment_value >= 0)

