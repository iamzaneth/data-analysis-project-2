-- Analysis group: Sales Analysis
-- Objective: analyze revenue, GMV, order count, sold items, and freight burden.

-- Chart: Revenue trend by month
SELECT
    year,
    month,
    CONCAT(year, '-', LPAD(month::TEXT, 2, '0')) AS year_month,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_item_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(total_item_revenue)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_order_value
FROM "olist_db"."mart"."mart_sales"
GROUP BY year, month
ORDER BY year, month;

-- Chart: GMV and freight by month
SELECT
    year,
    month,
    CONCAT(year, '-', LPAD(month::TEXT, 2, '0')) AS year_month,
    ROUND(SUM(gross_merchandise_value)::NUMERIC, 2) AS gross_merchandise_value,
    ROUND(SUM(total_freight_value)::NUMERIC, 2) AS total_freight_value,
    ROUND(SUM(total_item_revenue)::NUMERIC, 2) AS total_item_revenue,
    ROUND(SUM(total_freight_value)::NUMERIC / NULLIF(SUM(gross_merchandise_value), 0) * 100, 2) AS freight_to_gmv_pct
FROM "olist_db"."mart"."mart_sales"
GROUP BY year, month
ORDER BY year, month;

-- Ranking: Top 10 categories by revenue
SELECT
    product_category_name AS product_category,
    SUM(total_orders) AS total_orders,
    SUM(total_order_items) AS total_items,
    ROUND(SUM(total_item_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(total_item_revenue)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_order_value
FROM "olist_db"."mart"."mart_sales"
GROUP BY product_category_name
ORDER BY total_revenue DESC
LIMIT 10;

-- Ranking: Top 10 states by revenue
SELECT
    customer_state,
    SUM(total_orders) AS total_orders,
    SUM(total_order_items) AS total_items,
    ROUND(SUM(total_item_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(total_item_revenue)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_order_value
FROM "olist_db"."mart"."mart_sales"
GROUP BY customer_state
ORDER BY total_revenue DESC
LIMIT 10;

-- Ranking: Top categories by order count
SELECT
    product_category_name AS product_category,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_item_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(total_item_revenue)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_order_value
FROM "olist_db"."mart"."mart_sales"
GROUP BY product_category_name
ORDER BY total_orders DESC
LIMIT 15;

-- Insight: Freight-to-GMV ratio by category
SELECT
    product_category_name AS product_category,
    ROUND(SUM(gross_merchandise_value)::NUMERIC, 2) AS gross_merchandise_value,
    ROUND(SUM(total_freight_value)::NUMERIC, 2) AS total_freight_value,
    ROUND(SUM(total_freight_value)::NUMERIC / NULLIF(SUM(gross_merchandise_value), 0) * 100, 2) AS freight_to_gmv_pct,
    SUM(total_orders) AS total_orders
FROM "olist_db"."mart"."mart_sales"
GROUP BY product_category_name
HAVING SUM(gross_merchandise_value) > 0
ORDER BY freight_to_gmv_pct DESC, gross_merchandise_value DESC
LIMIT 20;

-- Insight: High revenue categories with high freight burden
WITH category_sales AS (
    SELECT
        product_category_name AS product_category,
        SUM(total_orders) AS total_orders,
        SUM(gross_merchandise_value) AS gross_merchandise_value,
        SUM(total_freight_value) AS total_freight_value,
        SUM(total_item_revenue) AS total_revenue
    FROM "olist_db"."mart"."mart_sales"
    GROUP BY product_category_name
)
SELECT
    product_category,
    total_orders,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(gross_merchandise_value::NUMERIC, 2) AS gross_merchandise_value,
    ROUND(total_freight_value::NUMERIC, 2) AS total_freight_value,
    ROUND(total_freight_value::NUMERIC / NULLIF(gross_merchandise_value, 0) * 100, 2) AS freight_to_gmv_pct
FROM category_sales
WHERE total_revenue >= 100000
ORDER BY freight_to_gmv_pct DESC, total_revenue DESC
LIMIT 20;

-- Chart: Revenue share by category
WITH category_sales AS (
    SELECT
        product_category_name AS product_category,
        SUM(total_item_revenue) AS total_revenue
    FROM "olist_db"."mart"."mart_sales"
    GROUP BY product_category_name
)
SELECT
    product_category,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(total_revenue::NUMERIC / NULLIF(SUM(total_revenue) OVER (), 0) * 100, 2) AS revenue_share_pct
FROM category_sales
ORDER BY total_revenue DESC
LIMIT 20;

-- Chart: Revenue share by customer state
WITH state_sales AS (
    SELECT
        customer_state,
        SUM(total_item_revenue) AS total_revenue
    FROM "olist_db"."mart"."mart_sales"
    GROUP BY customer_state
)
SELECT
    customer_state,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(total_revenue::NUMERIC / NULLIF(SUM(total_revenue) OVER (), 0) * 100, 2) AS revenue_share_pct
FROM state_sales
ORDER BY total_revenue DESC;

-- Chart: Average order value by month
SELECT
    year,
    month,
    CONCAT(year, '-', LPAD(month::TEXT, 2, '0')) AS year_month,
    ROUND(SUM(total_item_revenue)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_order_value,
    SUM(total_orders) AS total_orders
FROM "olist_db"."mart"."mart_sales"
GROUP BY year, month
ORDER BY year, month;