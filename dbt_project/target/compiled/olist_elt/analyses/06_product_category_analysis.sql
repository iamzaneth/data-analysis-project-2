-- Analysis group: Product Category Analysis
-- Objective: analyze category revenue, order/item volume, freight burden,
-- product size, and review quality.

-- Ranking: Top categories by revenue
SELECT
    product_category_name AS product_category,
    SUM(total_orders) AS total_orders,
    SUM(total_items) AS total_items,
    SUM(total_sellers) AS total_sellers,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(total_revenue)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_order_value
FROM "olist_db"."mart"."mart_product_category"
GROUP BY product_category_name
ORDER BY total_revenue DESC
LIMIT 20;

-- Ranking: Top categories by sold items
SELECT
    product_category_name AS product_category,
    SUM(total_items) AS total_items,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue
FROM "olist_db"."mart"."mart_product_category"
GROUP BY product_category_name
ORDER BY total_items DESC
LIMIT 20;

-- Insight: Categories with low review performance
SELECT
    product_category_name AS product_category,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0), 2) AS avg_review_score,
    SUM(low_review_count) AS low_review_count,
    ROUND(SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS low_review_rate_pct
FROM "olist_db"."mart"."mart_product_category"
GROUP BY product_category_name
HAVING SUM(total_orders) >= 100
ORDER BY low_review_rate_pct DESC, total_revenue DESC
LIMIT 25;

-- Insight: Categories with high freight value
SELECT
    product_category_name AS product_category,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(total_freight_value)::NUMERIC, 2) AS total_freight_value,
    ROUND(SUM(total_freight_value)::NUMERIC / NULLIF(SUM(gross_merchandise_value), 0) * 100, 2) AS freight_to_gmv_pct,
    ROUND(SUM(avg_freight_value * total_items)::NUMERIC / NULLIF(SUM(total_items), 0), 2) AS avg_freight_value
FROM "olist_db"."mart"."mart_product_category"
GROUP BY product_category_name
HAVING SUM(gross_merchandise_value) > 0
ORDER BY freight_to_gmv_pct DESC, total_revenue DESC
LIMIT 25;

-- Insight: Heavy or bulky product categories
SELECT
    product_category_name AS product_category,
    SUM(total_items) AS total_items,
    ROUND(SUM(avg_product_weight_g * total_items)::NUMERIC / NULLIF(SUM(total_items), 0), 2) AS avg_product_weight_g,
    ROUND(SUM(avg_product_volume_cm3 * total_items)::NUMERIC / NULLIF(SUM(total_items), 0), 2) AS avg_product_volume_cm3,
    ROUND(SUM(avg_freight_value * total_items)::NUMERIC / NULLIF(SUM(total_items), 0), 2) AS avg_freight_value
FROM "olist_db"."mart"."mart_product_category"
GROUP BY product_category_name
HAVING SUM(total_items) >= 100
ORDER BY avg_product_volume_cm3 DESC, avg_product_weight_g DESC
LIMIT 25;

-- Insight: High revenue categories with low review score
SELECT
    product_category_name AS product_category,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0), 2) AS avg_review_score,
    ROUND(SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS low_review_rate_pct
FROM "olist_db"."mart"."mart_product_category"
GROUP BY product_category_name
HAVING SUM(total_revenue) >= 100000
ORDER BY avg_review_score ASC NULLS LAST, total_revenue DESC
LIMIT 20;

-- Insight: Categories with high freight-to-revenue ratio
SELECT
    product_category_name AS product_category,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(total_freight_value)::NUMERIC, 2) AS total_freight_value,
    ROUND(SUM(total_freight_value)::NUMERIC / NULLIF(SUM(total_revenue), 0) * 100, 2) AS freight_to_revenue_pct,
    SUM(total_orders) AS total_orders
FROM "olist_db"."mart"."mart_product_category"
GROUP BY product_category_name
HAVING SUM(total_revenue) > 0
ORDER BY freight_to_revenue_pct DESC, total_revenue DESC
LIMIT 25;

-- Chart: Category performance by month for top categories
WITH top_categories AS (
    SELECT
        product_category_name
    FROM "olist_db"."mart"."mart_product_category"
    GROUP BY product_category_name
    ORDER BY SUM(total_revenue) DESC
    LIMIT 10
)
SELECT
    m.year,
    m.month,
    CONCAT(m.year, '-', LPAD(m.month::TEXT, 2, '0')) AS year_month,
    m.product_category_name AS product_category,
    SUM(m.total_orders) AS total_orders,
    ROUND(SUM(m.total_revenue)::NUMERIC, 2) AS total_revenue
FROM "olist_db"."mart"."mart_product_category" m
JOIN top_categories t
    ON t.product_category_name = m.product_category_name
GROUP BY m.year, m.month, m.product_category_name
ORDER BY m.year, m.month, total_revenue DESC;

-- Comparison: Revenue, review, and freight by category
SELECT
    product_category_name AS product_category,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0), 2) AS avg_review_score,
    ROUND(SUM(total_freight_value)::NUMERIC / NULLIF(SUM(total_revenue), 0) * 100, 2) AS freight_to_revenue_pct,
    SUM(total_orders) AS total_orders
FROM "olist_db"."mart"."mart_product_category"
GROUP BY product_category_name
HAVING SUM(total_orders) >= 100
ORDER BY total_revenue DESC
LIMIT 30;