-- Analysis group: Geolocation Analysis
-- Objective: analyze market performance by customer state and city, including
-- revenue, order volume, AOV, delivery risk, review quality, and payment value.

-- Map/ranking: Regional market performance by state
SELECT
    customer_state,
    SUM(total_orders) AS total_orders,
    SUM(total_customers) AS total_customers,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(total_revenue)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_order_value,
    SUM(delivered_orders) AS delivered_orders,
    SUM(late_orders) AS late_orders,
    ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) * 100, 2) AS late_rate_pct,
    ROUND(SUM(avg_delivery_days * delivered_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0), 2) AS avg_delivery_days,
    ROUND(SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0), 2) AS avg_review_score,
    ROUND(SUM(total_payment_value)::NUMERIC, 2) AS total_payment_value
FROM "olist_db"."mart"."mart_geolocation"
GROUP BY customer_state
ORDER BY total_revenue DESC;

-- Ranking: Top cities by revenue
SELECT
    customer_state,
    customer_city,
    SUM(total_orders) AS total_orders,
    SUM(total_customers) AS total_customers,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(total_revenue)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_order_value
FROM "olist_db"."mart"."mart_geolocation"
GROUP BY customer_state, customer_city
ORDER BY total_revenue DESC
LIMIT 30;

-- Ranking: Top states by order count
SELECT
    customer_state,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(total_revenue)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_order_value
FROM "olist_db"."mart"."mart_geolocation"
GROUP BY customer_state
ORDER BY total_orders DESC;

-- Ranking: Average order value by state
SELECT
    customer_state,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(total_revenue)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_order_value
FROM "olist_db"."mart"."mart_geolocation"
GROUP BY customer_state
HAVING SUM(total_orders) >= 100
ORDER BY avg_order_value DESC;

-- Map: Late rate by region
SELECT
    customer_state,
    customer_city,
    SUM(delivered_orders) AS delivered_orders,
    SUM(late_orders) AS late_orders,
    ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) * 100, 2) AS late_rate_pct,
    ROUND(SUM(avg_delivery_days * delivered_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0), 2) AS avg_delivery_days
FROM "olist_db"."mart"."mart_geolocation"
GROUP BY customer_state, customer_city
HAVING SUM(delivered_orders) >= 50
ORDER BY late_rate_pct DESC, delivered_orders DESC
LIMIT 50;

-- Map: Review score by region
SELECT
    customer_state,
    customer_city,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0), 2) AS avg_review_score,
    ROUND(SUM(low_review_rate_pct * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE low_review_rate_pct IS NOT NULL), 0), 2) AS low_review_rate_pct
FROM "olist_db"."mart"."mart_geolocation"
GROUP BY customer_state, customer_city
HAVING SUM(total_orders) >= 50
ORDER BY avg_review_score ASC NULLS LAST, total_orders DESC
LIMIT 50;

-- Insight: High revenue regions with high late rate
SELECT
    customer_state,
    customer_city,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    SUM(delivered_orders) AS delivered_orders,
    SUM(late_orders) AS late_orders,
    ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) * 100, 2) AS late_rate_pct,
    ROUND(SUM(avg_delivery_days * delivered_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0), 2) AS avg_delivery_days
FROM "olist_db"."mart"."mart_geolocation"
GROUP BY customer_state, customer_city
HAVING SUM(total_revenue) >= 50000
   AND SUM(delivered_orders) >= 50
ORDER BY late_rate_pct DESC, total_revenue DESC
LIMIT 30;

-- Insight: High revenue regions with low review score
SELECT
    customer_state,
    customer_city,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0), 2) AS avg_review_score,
    ROUND(SUM(low_review_rate_pct * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE low_review_rate_pct IS NOT NULL), 0), 2) AS low_review_rate_pct
FROM "olist_db"."mart"."mart_geolocation"
GROUP BY customer_state, customer_city
HAVING SUM(total_revenue) >= 50000
ORDER BY avg_review_score ASC NULLS LAST, total_revenue DESC
LIMIT 30;

-- Ranking: Regional market score
WITH region_metrics AS (
    SELECT
        customer_state,
        customer_city,
        SUM(total_orders) AS total_orders,
        SUM(total_revenue) AS total_revenue,
        SUM(late_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) * 100 AS late_rate_pct,
        SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0) AS avg_review_score
    FROM "olist_db"."mart"."mart_geolocation"
    GROUP BY customer_state, customer_city
)
SELECT
    customer_state,
    customer_city,
    total_orders,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(late_rate_pct::NUMERIC, 2) AS late_rate_pct,
    ROUND(avg_review_score::NUMERIC, 2) AS avg_review_score,
    ROUND(
        (LN(total_revenue + 1) * 10)
        + (COALESCE(avg_review_score, 0) * 8)
        - (COALESCE(late_rate_pct, 0) * 0.5),
        2
    ) AS regional_market_score
FROM region_metrics
WHERE total_orders >= 50
ORDER BY regional_market_score DESC
LIMIT 30;