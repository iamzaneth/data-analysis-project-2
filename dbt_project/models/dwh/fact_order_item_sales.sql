{{ config(
    materialized='table',
    indexes=[
      {'columns': ['order_id', 'order_item_id'], 'unique': True},
      {'columns': ['customer_key']},
      {'columns': ['product_key']}
    ]
) }}

SELECT
    oi.order_id,
    oi.order_item_id,
    -- Tham chiếu surrogate key thay vì join bảng
    {{ dbt_utils.generate_surrogate_key(['o.customer_id']) }} AS customer_key,
    {{ dbt_utils.generate_surrogate_key(['oi.seller_id']) }} AS seller_key,
    {{ dbt_utils.generate_surrogate_key(['oi.product_id']) }} AS product_key,
    {{ dbt_utils.generate_surrogate_key(['c.customer_zip_code_prefix']) }} AS customer_geolocation_key,
    {{ dbt_utils.generate_surrogate_key(['s.seller_zip_code_prefix']) }} AS seller_geolocation_key,
    {{ dbt_utils.generate_surrogate_key(['o.order_status']) }} AS order_status_key,
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

FROM {{ source('staging', 'olist_order_items') }} oi
LEFT JOIN {{ source('staging', 'olist_orders') }} o
    ON o.order_id = oi.order_id
LEFT JOIN {{ source('staging', 'olist_customers') }} c
    ON c.customer_id = o.customer_id
LEFT JOIN {{ source('staging', 'olist_sellers') }} s
    ON s.seller_id = oi.seller_id
WHERE oi.order_id IS NOT NULL
  AND oi.order_item_id IS NOT NULL