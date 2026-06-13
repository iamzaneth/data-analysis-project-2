



select
    1
from "olist_db"."mart"."mart_geolocation"

where not(late_rate_pct BETWEEN 0 AND 100)

