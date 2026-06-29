-- Analysis group: Customer Satisfaction Analysis
-- Objective: analyze review score, low/neutral/high review distribution,
-- comment rate, and the relationship between late delivery and customer rating.

-- KPI: Overall review performance
SELECT
    SUM(total_reviews) AS total_reviews,
    ROUND(SUM(avg_review_score * total_reviews)::NUMERIC / NULLIF(SUM(total_reviews), 0), 2) AS avg_review_score,
    SUM(low_review_count) AS low_review_count,
    SUM(neutral_review_count) AS neutral_review_count,
    SUM(high_review_count) AS high_review_count,
    ROUND(SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_reviews), 0) * 100, 2) AS low_review_rate_pct,
    ROUND(SUM(high_review_count)::NUMERIC / NULLIF(SUM(total_reviews), 0) * 100, 2) AS high_review_rate_pct
FROM "olist_db"."mart"."mart_customer_satisfaction";

-- Chart: Low/neutral/high review distribution
SELECT
    'Low review (<=2)' AS review_group,
    SUM(low_review_count) AS review_count,
    ROUND(SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_reviews), 0) * 100, 2) AS review_share_pct
FROM "olist_db"."mart"."mart_customer_satisfaction"
UNION ALL
SELECT
    'Neutral review (=3)',
    SUM(neutral_review_count),
    ROUND(SUM(neutral_review_count)::NUMERIC / NULLIF(SUM(total_reviews), 0) * 100, 2)
FROM "olist_db"."mart"."mart_customer_satisfaction"
UNION ALL
SELECT
    'High review (>=4)',
    SUM(high_review_count),
    ROUND(SUM(high_review_count)::NUMERIC / NULLIF(SUM(total_reviews), 0) * 100, 2)
FROM "olist_db"."mart"."mart_customer_satisfaction";

-- Chart: Review score and low review rate by month
SELECT
    year,
    month,
    CONCAT(year, '-', LPAD(month::TEXT, 2, '0')) AS year_month,
    SUM(total_reviews) AS total_reviews,
    ROUND(SUM(avg_review_score * total_reviews)::NUMERIC / NULLIF(SUM(total_reviews), 0), 2) AS avg_review_score,
    ROUND(SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_reviews), 0) * 100, 2) AS low_review_rate_pct
FROM "olist_db"."mart"."mart_customer_satisfaction"
GROUP BY year, month
ORDER BY year, month;

-- Chart: Review performance by late delivery status
SELECT
    is_late,
    SUM(total_reviews) AS total_reviews,
    ROUND(SUM(avg_review_score * total_reviews)::NUMERIC / NULLIF(SUM(total_reviews), 0), 2) AS avg_review_score,
    SUM(low_review_count) AS low_review_count,
    ROUND(SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_reviews), 0) * 100, 2) AS low_review_rate_pct,
    ROUND(SUM(avg_delivery_days * total_reviews)::NUMERIC / NULLIF(SUM(total_reviews), 0), 2) AS avg_delivery_days,
    ROUND(SUM(avg_delay_days * total_reviews)::NUMERIC / NULLIF(SUM(total_reviews), 0), 2) AS avg_delay_days
FROM "olist_db"."mart"."mart_customer_satisfaction"
GROUP BY is_late
ORDER BY is_late;

-- Ranking: Low review rate by state
SELECT
    customer_state,
    SUM(total_reviews) AS total_reviews,
    ROUND(SUM(avg_review_score * total_reviews)::NUMERIC / NULLIF(SUM(total_reviews), 0), 2) AS avg_review_score,
    ROUND(SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_reviews), 0) * 100, 2) AS low_review_rate_pct,
    ROUND(SUM(comment_message_count)::NUMERIC / NULLIF(SUM(total_reviews), 0) * 100, 2) AS comment_message_rate_pct
FROM "olist_db"."mart"."mart_customer_satisfaction"
GROUP BY customer_state
HAVING SUM(total_reviews) >= 100
ORDER BY low_review_rate_pct DESC, total_reviews DESC;

-- Chart: Comment message rate by month
SELECT
    year,
    month,
    CONCAT(year, '-', LPAD(month::TEXT, 2, '0')) AS year_month,
    SUM(total_reviews) AS total_reviews,
    SUM(comment_message_count) AS comment_message_count,
    ROUND(SUM(comment_message_count)::NUMERIC / NULLIF(SUM(total_reviews), 0) * 100, 2) AS comment_message_rate_pct,
    ROUND(SUM(avg_review_response_days * total_reviews)::NUMERIC / NULLIF(SUM(total_reviews), 0), 2) AS avg_review_response_days
FROM "olist_db"."mart"."mart_customer_satisfaction"
GROUP BY year, month
ORDER BY year, month;

-- Insight: High-order states with low review performance
WITH review_state AS (
    SELECT
        customer_state,
        SUM(total_reviews) AS total_reviews,
        SUM(low_review_count) AS low_review_count,
        SUM(avg_review_score * total_reviews) AS weighted_review_score
    FROM "olist_db"."mart"."mart_customer_satisfaction"
    GROUP BY customer_state
),
sales_state AS (
    SELECT
        customer_state,
        SUM(total_orders) AS total_orders,
        SUM(total_item_revenue) AS total_revenue
    FROM "olist_db"."mart"."mart_sales"
    GROUP BY customer_state
)
SELECT
    s.customer_state,
    s.total_orders,
    ROUND(s.total_revenue::NUMERIC, 2) AS total_revenue,
    r.total_reviews,
    ROUND(r.weighted_review_score::NUMERIC / NULLIF(r.total_reviews, 0), 2) AS avg_review_score,
    ROUND(r.low_review_count::NUMERIC / NULLIF(r.total_reviews, 0) * 100, 2) AS low_review_rate_pct
FROM sales_state s
JOIN review_state r
    ON r.customer_state = s.customer_state
WHERE s.total_orders >= 1000
ORDER BY low_review_rate_pct DESC, s.total_orders DESC;

-- Insight: Late delivery lift on low review rate
WITH late_status AS (
    SELECT
        is_late,
        SUM(total_reviews) AS total_reviews,
        SUM(low_review_count) AS low_review_count
    FROM "olist_db"."mart"."mart_customer_satisfaction"
    GROUP BY is_late
)
SELECT
    is_late,
    total_reviews,
    low_review_count,
    ROUND(low_review_count::NUMERIC / NULLIF(total_reviews, 0) * 100, 2) AS low_review_rate_pct
FROM late_status
ORDER BY is_late;