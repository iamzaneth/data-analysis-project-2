{{ config(
    materialized='table',
    indexes=[
      {'columns': ['full_date'], 'unique': True}
    ]
) }}

WITH raw_dates AS (
    SELECT order_purchase_timestamp::DATE AS full_date FROM {{ source('staging', 'olist_orders') }} WHERE order_purchase_timestamp IS NOT NULL
    UNION
    SELECT order_approved_at::DATE AS full_date FROM {{ source('staging', 'olist_orders') }} WHERE order_approved_at IS NOT NULL
    UNION
    SELECT order_delivered_carrier_date::DATE AS full_date FROM {{ source('staging', 'olist_orders') }} WHERE order_delivered_carrier_date IS NOT NULL
    UNION
    SELECT order_delivered_customer_date::DATE AS full_date FROM {{ source('staging', 'olist_orders') }} WHERE order_delivered_customer_date IS NOT NULL
    UNION
    SELECT order_estimated_delivery_date::DATE AS full_date FROM {{ source('staging', 'olist_orders') }} WHERE order_estimated_delivery_date IS NOT NULL
    UNION
    SELECT shipping_limit_date::DATE AS full_date FROM {{ source('staging', 'olist_order_items') }} WHERE shipping_limit_date IS NOT NULL
    UNION
    SELECT review_creation_date::DATE AS full_date FROM {{ source('staging', 'olist_order_reviews') }} WHERE review_creation_date IS NOT NULL
    UNION
    SELECT review_answer_timestamp::DATE AS full_date FROM {{ source('staging', 'olist_order_reviews') }} WHERE review_answer_timestamp IS NOT NULL
),
date_bounds AS (
    SELECT
        MIN(full_date) AS min_date,
        MAX(full_date) AS max_date
    FROM raw_dates
)
SELECT
    TO_CHAR(date_value, 'YYYYMMDD')::INTEGER AS date_key,
    date_value::DATE AS full_date,
    EXTRACT(YEAR FROM date_value)::INTEGER AS year,
    EXTRACT(QUARTER FROM date_value)::INTEGER AS quarter,
    EXTRACT(MONTH FROM date_value)::INTEGER AS month,
    TO_CHAR(date_value, 'FMMonth') AS month_name,
    EXTRACT(DAY FROM date_value)::INTEGER AS day,
    EXTRACT(ISODOW FROM date_value)::INTEGER AS day_of_week,
    TO_CHAR(date_value, 'FMDay') AS day_name,
    -- Ép kiểu boolean thành true/false chuẩn
    CASE WHEN EXTRACT(ISODOW FROM date_value)::INTEGER IN (6, 7) THEN TRUE ELSE FALSE END AS is_weekend
FROM date_bounds
CROSS JOIN LATERAL generate_series(min_date, max_date, INTERVAL '1 day') AS d(date_value)
WHERE min_date IS NOT NULL
  AND max_date IS NOT NULL