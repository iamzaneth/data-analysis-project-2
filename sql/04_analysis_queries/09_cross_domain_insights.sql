-- Analysis group: Cross-Domain Insights
-- Objective: combine mart-level aggregates carefully to find business issues
-- spanning sales, logistics, reviews, payment, category, seller, and geography.
-- Suggested charts: risk tables, scatter plots, quadrant charts, priority lists.
-- Expected insights: high revenue but low review segments, high value regions
-- with poor delivery, sellers/categories needing operational intervention.
-- Duplication note: each CTE aggregates to the intended comparison grain before
-- joining across domains.

-- Insight: Categories with high revenue and low review performance
WITH category_metrics AS (
    SELECT
        product_category_name_english AS product_category,
        SUM(total_orders) AS total_orders,
        SUM(total_revenue) AS total_revenue,
        SUM(total_freight_value) AS total_freight_value,
        SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0) AS avg_review_score,
        SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100 AS low_review_rate_pct
    FROM mart.mart_product_category
    GROUP BY product_category_name_english
)
SELECT
    product_category,
    total_orders,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(avg_review_score::NUMERIC, 2) AS avg_review_score,
    ROUND(low_review_rate_pct::NUMERIC, 2) AS low_review_rate_pct,
    ROUND(total_freight_value::NUMERIC / NULLIF(total_revenue, 0) * 100, 2) AS freight_to_revenue_pct
FROM category_metrics
WHERE total_revenue >= 100000
ORDER BY avg_review_score ASC NULLS LAST, total_revenue DESC
LIMIT 30;

-- Insight: Sellers with high revenue and high late delivery risk
WITH seller_metrics AS (
    SELECT
        seller_id,
        seller_state,
        seller_city,
        SUM(total_orders) AS total_orders,
        SUM(total_revenue) AS total_revenue,
        SUM(late_orders)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100 AS late_order_share_pct,
        SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0) AS avg_review_score
    FROM mart.mart_seller_performance
    GROUP BY seller_id, seller_state, seller_city
)
SELECT
    seller_id,
    seller_state,
    seller_city,
    total_orders,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(late_order_share_pct::NUMERIC, 2) AS late_order_share_pct,
    ROUND(avg_review_score::NUMERIC, 2) AS avg_review_score
FROM seller_metrics
WHERE total_revenue >= 10000
ORDER BY late_order_share_pct DESC, total_revenue DESC
LIMIT 30;

-- Insight: Regions with high revenue but weak delivery performance
WITH region_metrics AS (
    SELECT
        customer_state,
        SUM(total_orders) AS total_orders,
        SUM(total_revenue) AS total_revenue,
        SUM(late_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) * 100 AS late_rate_pct,
        SUM(avg_delivery_days * delivered_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) AS avg_delivery_days
    FROM mart.mart_geolocation
    GROUP BY customer_state
)
SELECT
    customer_state,
    total_orders,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(late_rate_pct::NUMERIC, 2) AS late_rate_pct,
    ROUND(avg_delivery_days::NUMERIC, 2) AS avg_delivery_days
FROM region_metrics
WHERE total_revenue >= 100000
ORDER BY late_rate_pct DESC, total_revenue DESC;

-- Insight: Regions with low review and high late rate
WITH region_metrics AS (
    SELECT
        customer_state,
        SUM(total_orders) AS total_orders,
        SUM(total_revenue) AS total_revenue,
        SUM(late_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) * 100 AS late_rate_pct,
        SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0) AS avg_review_score,
        SUM(low_review_rate_pct * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE low_review_rate_pct IS NOT NULL), 0) AS low_review_rate_pct
    FROM mart.mart_geolocation
    GROUP BY customer_state
)
SELECT
    customer_state,
    total_orders,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(late_rate_pct::NUMERIC, 2) AS late_rate_pct,
    ROUND(avg_review_score::NUMERIC, 2) AS avg_review_score,
    ROUND(low_review_rate_pct::NUMERIC, 2) AS low_review_rate_pct
FROM region_metrics
WHERE total_orders >= 1000
ORDER BY low_review_rate_pct DESC, late_rate_pct DESC;

-- Insight: Payment types with high average payment value
SELECT
    payment_type,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_payment_value)::NUMERIC, 2) AS total_payment_value,
    ROUND(SUM(total_payment_value)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_payment_per_order,
    ROUND(SUM(installment_orders)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS installment_order_rate_pct
FROM mart.mart_payment
GROUP BY payment_type
ORDER BY avg_payment_per_order DESC;

-- Insight: Categories with both high freight and high low-review rate
WITH category_metrics AS (
    SELECT
        product_category_name_english AS product_category,
        SUM(total_orders) AS total_orders,
        SUM(total_revenue) AS total_revenue,
        SUM(total_freight_value) AS total_freight_value,
        SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100 AS low_review_rate_pct
    FROM mart.mart_product_category
    GROUP BY product_category_name_english
)
SELECT
    product_category,
    total_orders,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(total_freight_value::NUMERIC / NULLIF(total_revenue, 0) * 100, 2) AS freight_to_revenue_pct,
    ROUND(low_review_rate_pct::NUMERIC, 2) AS low_review_rate_pct
FROM category_metrics
WHERE total_orders >= 100
ORDER BY freight_to_revenue_pct DESC, low_review_rate_pct DESC
LIMIT 30;

-- Insight: Seller/category combinations needing improvement
SELECT
    seller_id,
    seller_state,
    seller_city,
    product_category_name_english AS product_category,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0), 2) AS avg_review_score,
    ROUND(SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS low_review_rate_pct,
    ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS late_order_share_pct
FROM mart.mart_seller_performance
GROUP BY seller_id, seller_state, seller_city, product_category_name_english
HAVING SUM(total_orders) >= 20
ORDER BY low_review_rate_pct DESC, late_order_share_pct DESC, total_revenue DESC
LIMIT 50;

-- Risk table: Category risk score
WITH category_metrics AS (
    SELECT
        product_category_name_english AS product_category,
        SUM(total_orders) AS total_orders,
        SUM(total_revenue) AS total_revenue,
        SUM(total_freight_value)::NUMERIC / NULLIF(SUM(total_revenue), 0) * 100 AS freight_to_revenue_pct,
        SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100 AS low_review_rate_pct,
        SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0) AS avg_review_score
    FROM mart.mart_product_category
    GROUP BY product_category_name_english
)
SELECT
    product_category,
    total_orders,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(avg_review_score::NUMERIC, 2) AS avg_review_score,
    ROUND(low_review_rate_pct::NUMERIC, 2) AS low_review_rate_pct,
    ROUND(freight_to_revenue_pct::NUMERIC, 2) AS freight_to_revenue_pct,
    ROUND(
        (COALESCE(low_review_rate_pct, 0) * 0.5)
        + (COALESCE(freight_to_revenue_pct, 0) * 0.3)
        + (CASE WHEN total_revenue >= 100000 THEN 20 ELSE 10 END),
        2
    ) AS category_risk_score
FROM category_metrics
WHERE total_orders >= 100
ORDER BY category_risk_score DESC, total_revenue DESC
LIMIT 30;
