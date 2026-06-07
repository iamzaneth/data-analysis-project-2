-- Analysis group: Seller Performance Analysis
-- Objective: evaluate seller performance by revenue, order volume, review score,
-- late delivery risk, category mix, and quality-control priority.
-- Suggested charts: seller ranking table, bar chart by state/category, risk
-- scatter plot, priority list.
-- Expected insights: high-value sellers with poor customer experience or
-- operational issues, and best sellers with balanced performance.

-- Ranking: Top sellers by revenue
SELECT
    seller_id,
    seller_state,
    seller_city,
    SUM(total_orders) AS total_orders,
    SUM(total_items) AS total_items,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(gross_merchandise_value)::NUMERIC, 2) AS gross_merchandise_value,
    ROUND(SUM(total_freight_value)::NUMERIC, 2) AS total_freight_value,
    ROUND(SUM(total_revenue)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_order_value
FROM mart.mart_seller_performance
GROUP BY seller_id, seller_state, seller_city
ORDER BY total_revenue DESC
LIMIT 20;

-- Ranking: Top sellers by order count
SELECT
    seller_id,
    seller_state,
    seller_city,
    SUM(total_orders) AS total_orders,
    SUM(total_items) AS total_items,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue
FROM mart.mart_seller_performance
GROUP BY seller_id, seller_state, seller_city
ORDER BY total_orders DESC, total_revenue DESC
LIMIT 20;

-- Insight: High revenue sellers with low review score
SELECT
    seller_id,
    seller_state,
    seller_city,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0), 2) AS avg_review_score,
    ROUND(SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS low_review_rate_pct,
    ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS late_order_share_pct
FROM mart.mart_seller_performance
GROUP BY seller_id, seller_state, seller_city
HAVING SUM(total_revenue) >= 10000
ORDER BY avg_review_score ASC NULLS LAST, total_revenue DESC
LIMIT 20;

-- Insight: High revenue sellers with high late delivery rate
SELECT
    seller_id,
    seller_state,
    seller_city,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    SUM(total_orders) AS total_orders,
    SUM(late_orders) AS late_orders,
    ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS late_order_share_pct,
    ROUND(SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0), 2) AS avg_review_score
FROM mart.mart_seller_performance
GROUP BY seller_id, seller_state, seller_city
HAVING SUM(total_revenue) >= 10000
ORDER BY late_order_share_pct DESC, total_revenue DESC
LIMIT 20;

-- Chart: Seller performance by state
SELECT
    seller_state,
    COUNT(DISTINCT seller_id) AS total_sellers,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(total_revenue)::NUMERIC / NULLIF(COUNT(DISTINCT seller_id), 0), 2) AS revenue_per_seller,
    ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS late_order_share_pct
FROM mart.mart_seller_performance
GROUP BY seller_state
ORDER BY total_revenue DESC;

-- Chart: Seller performance by category
SELECT
    product_category_name AS product_category,
    COUNT(DISTINCT seller_id) AS total_sellers,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0), 2) AS avg_review_score,
    ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS late_order_share_pct
FROM mart.mart_seller_performance
GROUP BY product_category_name
ORDER BY total_revenue DESC
LIMIT 25;

-- Insight: Sellers with high low-review risk
SELECT
    seller_id,
    seller_state,
    seller_city,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    SUM(low_review_count) AS low_review_count,
    ROUND(SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS low_review_rate_pct
FROM mart.mart_seller_performance
GROUP BY seller_id, seller_state, seller_city
HAVING SUM(total_orders) >= 50
ORDER BY low_review_rate_pct DESC, total_revenue DESC
LIMIT 30;

-- Insight: Seller quality-control priority score
WITH seller_metrics AS (
    SELECT
        seller_id,
        seller_state,
        seller_city,
        SUM(total_orders) AS total_orders,
        SUM(total_revenue) AS total_revenue,
        SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100 AS low_review_rate_pct,
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
    ROUND(avg_review_score::NUMERIC, 2) AS avg_review_score,
    ROUND(low_review_rate_pct::NUMERIC, 2) AS low_review_rate_pct,
    ROUND(late_order_share_pct::NUMERIC, 2) AS late_order_share_pct,
    ROUND(
        (COALESCE(low_review_rate_pct, 0) * 0.45)
        + (COALESCE(late_order_share_pct, 0) * 0.35)
        + (CASE WHEN total_revenue >= 50000 THEN 20 ELSE 10 END),
        2
    ) AS quality_priority_score
FROM seller_metrics
WHERE total_orders >= 50
ORDER BY quality_priority_score DESC, total_revenue DESC
LIMIT 30;

-- Insight: Best balanced sellers
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
    ROUND(avg_review_score::NUMERIC, 2) AS avg_review_score,
    ROUND(late_order_share_pct::NUMERIC, 2) AS late_order_share_pct
FROM seller_metrics
WHERE total_orders >= 50
  AND avg_review_score >= 4
  AND late_order_share_pct <= 5
ORDER BY total_revenue DESC
LIMIT 20;
