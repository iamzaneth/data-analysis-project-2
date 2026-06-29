



select
    1
from "olist_db"."dwh"."fact_payments"

where not(payment_value >= 0)

