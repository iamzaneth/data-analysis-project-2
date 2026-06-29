

SELECT DISTINCT
    md5(cast(coalesce(cast(order_status as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS order_status_key,
    order_status
FROM "olist_db"."staging"."olist_orders"
WHERE order_status IS NOT NULL