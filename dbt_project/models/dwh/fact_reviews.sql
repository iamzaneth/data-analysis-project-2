{{ config(
    materialized='table',
    indexes=[
      {'columns': ['review_id', 'order_id'], 'unique': True},
      {'columns': ['order_id']},
      {'columns': ['customer_key']},
      {'columns': ['customer_geolocation_key']},
      {'columns': ['order_status_key']},
      {'columns': ['purchase_date_key']},
      {'columns': ['review_creation_date_key']},
      {'columns': ['review_score']}
    ]
) }}

SELECT
    r.review_id,
    r.order_id,
    
    {{ dbt_utils.generate_surrogate_key(['o.customer_id']) }} AS customer_key,
    {{ dbt_utils.generate_surrogate_key(['c.customer_zip_code_prefix']) }} AS customer_geolocation_key,
    {{ dbt_utils.generate_surrogate_key(['o.order_status']) }} AS order_status_key,
    TO_CHAR(o.order_purchase_timestamp::DATE, 'YYYYMMDD')::INTEGER AS purchase_date_key,
    TO_CHAR(r.review_creation_date::DATE, 'YYYYMMDD')::INTEGER AS review_creation_date_key,
    TO_CHAR(r.review_answer_timestamp::DATE, 'YYYYMMDD')::INTEGER AS review_answer_date_key,
    
    o.customer_id,
    r.review_score,
    
    -- Chuẩn hóa cờ boolean cho các comment (Xóa khoảng trắng và check null)
    NULLIF(BTRIM(r.review_comment_title), '') IS NOT NULL AS has_comment_title,
    NULLIF(BTRIM(r.review_comment_message), '') IS NOT NULL AS has_comment_message,
    
    r.review_creation_date,
    r.review_answer_timestamp,
    
    -- Tính thời gian phản hồi đánh giá
    CASE 
        WHEN r.review_creation_date IS NOT NULL AND r.review_answer_timestamp IS NOT NULL
        THEN ROUND((EXTRACT(EPOCH FROM (r.review_answer_timestamp - r.review_creation_date)) / 86400.0)::NUMERIC, 2)
    END AS review_response_days

FROM {{ source('staging', 'olist_order_reviews') }} r
LEFT JOIN {{ source('staging', 'olist_orders') }} o
    ON o.order_id = r.order_id
LEFT JOIN {{ source('staging', 'olist_customers') }} c
    ON c.customer_id = o.customer_id
WHERE r.review_id IS NOT NULL
  AND r.order_id IS NOT NULL