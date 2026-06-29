{{ config(
    materialized='table',
    indexes=[
      {'columns': ['order_id'], 'unique': True},
      {'columns': ['customer_key']},
      {'columns': ['customer_geolocation_key']},
      {'columns': ['order_status_key']},
      {'columns': ['purchase_date_key']},
      {'columns': ['delivered_customer_date_key']},
      {'columns': ['estimated_delivery_date_key']},
      {'columns': ['is_late']}
    ]
) }}

SELECT
    o.order_id,
    
    -- Tạo các Surrogate Keys trực tiếp từ dữ liệu staging
    {{ dbt_utils.generate_surrogate_key(['o.customer_id']) }} AS customer_key,
    {{ dbt_utils.generate_surrogate_key(['c.customer_zip_code_prefix']) }} AS customer_geolocation_key,
    {{ dbt_utils.generate_surrogate_key(['o.order_status']) }} AS order_status_key,
    
    -- Xử lý Date Keys (Ép kiểu YYYYMMDD thành số nguyên)
    TO_CHAR(o.order_purchase_timestamp::DATE, 'YYYYMMDD')::INTEGER AS purchase_date_key,
    TO_CHAR(o.order_approved_at::DATE, 'YYYYMMDD')::INTEGER AS approved_date_key,
    TO_CHAR(o.order_delivered_carrier_date::DATE, 'YYYYMMDD')::INTEGER AS delivered_carrier_date_key,
    TO_CHAR(o.order_delivered_customer_date::DATE, 'YYYYMMDD')::INTEGER AS delivered_customer_date_key,
    TO_CHAR(o.order_estimated_delivery_date::DATE, 'YYYYMMDD')::INTEGER AS estimated_delivery_date_key,
    
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    
    -- Tính toán logic Business Metrics
    CASE 
        WHEN o.order_purchase_timestamp IS NOT NULL AND o.order_approved_at IS NOT NULL
        THEN ROUND((EXTRACT(EPOCH FROM (o.order_approved_at - o.order_purchase_timestamp)) / 3600.0)::NUMERIC, 2)
    END AS approval_hours,
    
    CASE 
        WHEN o.order_purchase_timestamp IS NOT NULL AND o.order_delivered_carrier_date IS NOT NULL
        THEN ROUND((EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_purchase_timestamp)) / 86400.0)::NUMERIC, 2)
    END AS carrier_handoff_days,
    
    CASE 
        WHEN o.order_purchase_timestamp IS NOT NULL AND o.order_delivered_customer_date IS NOT NULL
        THEN ROUND((EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0)::NUMERIC, 2)
    END AS delivery_days,
    
    CASE 
        WHEN o.order_purchase_timestamp IS NOT NULL AND o.order_estimated_delivery_date IS NOT NULL
        THEN ROUND((EXTRACT(EPOCH FROM (o.order_estimated_delivery_date - o.order_purchase_timestamp)) / 86400.0)::NUMERIC, 2)
    END AS estimated_delivery_days,
    
    CASE 
        WHEN o.order_delivered_customer_date IS NOT NULL AND o.order_estimated_delivery_date IS NOT NULL
        THEN ROUND((EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400.0)::NUMERIC, 2)
    END AS delay_days,
    
    CASE 
        WHEN o.order_delivered_customer_date IS NOT NULL AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_delivered_customer_date > o.order_estimated_delivery_date
    END AS is_late

FROM {{ source('staging', 'olist_orders') }} o
LEFT JOIN {{ source('staging', 'olist_customers') }} c
    ON c.customer_id = o.customer_id
WHERE o.order_id IS NOT NULL