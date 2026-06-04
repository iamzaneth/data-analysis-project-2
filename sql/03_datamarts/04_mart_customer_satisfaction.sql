-- Mart: mart_customer_satisfaction
-- Domain: Customer Experience
-- Grain: 1 row = 1 review creation month + 1 customer state + 1 is_late flag.
-- Main sources: fact_reviews, fact_order_delivery, dim_customer, dim_date,
-- dim_order_status, dim_geolocation.
-- Purpose: analyze review score distribution, low/high review rates, comment
-- rates, review response time, and the relationship between late delivery and
-- customer satisfaction.
-- Duplication note: fact_order_delivery is unique by order_id, so joining it to
-- fact_reviews by order_id does not multiply review rows.

DROP TABLE IF EXISTS mart.mart_customer_satisfaction CASCADE;

CREATE TABLE mart.mart_customer_satisfaction AS
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
FROM dwh.fact_reviews r
LEFT JOIN dwh.fact_order_delivery delivery
    ON delivery.order_id = r.order_id
LEFT JOIN dwh.dim_date d
    ON d.date_key = r.review_creation_date_key
LEFT JOIN dwh.dim_customer c
    ON c.customer_key = r.customer_key
LEFT JOIN dwh.dim_order_status os
    ON os.order_status_key = r.order_status_key
LEFT JOIN dwh.dim_geolocation customer_geo
    ON customer_geo.geolocation_key = r.customer_geolocation_key
WHERE d.year IS NOT NULL
GROUP BY
    d.year,
    d.month,
    d.month_name,
    COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown'),
    COALESCE(delivery.is_late, FALSE);
