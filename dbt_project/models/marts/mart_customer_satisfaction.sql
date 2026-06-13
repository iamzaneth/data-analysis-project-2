{{ config(materialized='table') }}

SELECT
    d.year,
    d.month,
    d.month_name,
    COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown') AS customer_state,
    COALESCE(delivery.is_late, FALSE) AS is_late,
    COUNT(*) AS total_reviews,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(*) FILTER (WHERE r.review_score <= 2) AS low_review_count,
    COUNT(*) FILTER (WHERE r.review_score = 3) AS neutral_review_count,
    COUNT(*) FILTER (WHERE r.review_score >= 4) AS high_review_count,
    ROUND(100.0 * COUNT(*) FILTER (WHERE r.review_score <= 2) / NULLIF(COUNT(*), 0), 2) AS low_review_rate_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE r.review_score >= 4) / NULLIF(COUNT(*), 0), 2) AS high_review_rate_pct,
    COUNT(*) FILTER (WHERE r.has_comment_title IS TRUE) AS comment_title_count,
    COUNT(*) FILTER (WHERE r.has_comment_message IS TRUE) AS comment_message_count,
    ROUND(100.0 * COUNT(*) FILTER (WHERE r.has_comment_message IS TRUE) / NULLIF(COUNT(*), 0), 2) AS comment_message_rate_pct,
    ROUND(AVG(r.review_response_days), 2) AS avg_review_response_days,
    ROUND(AVG(delivery.delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(delivery.delay_days), 2) AS avg_delay_days
FROM {{ ref('fact_reviews') }} r
LEFT JOIN {{ ref('fact_order_delivery') }} delivery
    ON delivery.order_id = r.order_id
LEFT JOIN {{ ref('dim_date') }} d
    ON d.date_key = r.review_creation_date_key
LEFT JOIN {{ ref('dim_customer') }} c
    ON c.customer_key = r.customer_key
LEFT JOIN {{ ref('dim_order_status') }} os
    ON os.order_status_key = r.order_status_key
LEFT JOIN {{ ref('dim_geolocation') }} customer_geo
    ON customer_geo.geolocation_key = r.customer_geolocation_key
WHERE d.year IS NOT NULL
GROUP BY
    d.year,
    d.month,
    d.month_name,
    COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown'),
    COALESCE(delivery.is_late, FALSE)