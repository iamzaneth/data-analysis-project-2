

SELECT
    oi.order_id,
    oi.order_item_id,
    -- Tham chiếu surrogate key thay vì join bảng
    md5(cast(coalesce(cast(o.customer_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS customer_key,
    md5(cast(coalesce(cast(oi.seller_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS seller_key,
    md5(cast(coalesce(cast(oi.product_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS product_key,
    md5(cast(coalesce(cast(c.customer_zip_code_prefix as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS customer_geolocation_key,
    md5(cast(coalesce(cast(s.seller_zip_code_prefix as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS seller_geolocation_key,
    md5(cast(coalesce(cast(o.order_status as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS order_status_key,
    TO_CHAR(o.order_purchase_timestamp::DATE, 'YYYYMMDD')::INTEGER AS purchase_date_key,
    TO_CHAR(oi.shipping_limit_date::DATE, 'YYYYMMDD')::INTEGER AS shipping_limit_date_key,
    
    o.customer_id,
    oi.seller_id,
    oi.product_id,
    o.order_purchase_timestamp,
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,
    (oi.price + oi.freight_value) AS total_item_value

FROM "olist_db"."staging"."olist_order_items" oi
LEFT JOIN "olist_db"."staging"."olist_orders" o
    ON o.order_id = oi.order_id
LEFT JOIN "olist_db"."staging"."olist_customers" c
    ON c.customer_id = o.customer_id
LEFT JOIN "olist_db"."staging"."olist_sellers" s
    ON s.seller_id = oi.seller_id
WHERE oi.order_id IS NOT NULL
  AND oi.order_item_id IS NOT NULL