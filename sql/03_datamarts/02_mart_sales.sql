-- Mart: mart_sales
-- Domain: Sales / Business Performance
-- Grain: 1 row = 1 purchase month + 1 product category + 1 customer state.
-- Main sources: fact_order_item_sales, dim_date, dim_product, dim_customer,
-- dim_seller, dim_order_status, dim_geolocation.
-- Purpose: track revenue, orders, sold items, GMV, freight, seller count, and
-- sales performance by time, product category, and customer region.

DROP TABLE IF EXISTS mart.mart_sales CASCADE;

CREATE TABLE mart.mart_sales AS
SELECT
    d.year,
    d.month,
    d.month_name,
    COALESCE(p.product_category_name, 'Unknown') AS product_category_name,
    COALESCE(p.product_category_name_english, 'Unknown') AS product_category_name_english,
    COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown') AS customer_state,
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(*) AS total_order_items,
    COUNT(DISTINCT f.seller_key) AS total_sellers,
    ROUND(SUM(f.price), 2) AS gross_merchandise_value,
    ROUND(SUM(f.freight_value), 2) AS total_freight_value,
    ROUND(SUM(f.total_item_value), 2) AS total_item_revenue,
    ROUND(AVG(f.price), 2) AS avg_item_price,
    ROUND(AVG(f.freight_value), 2) AS avg_freight_value,
    ROUND(AVG(f.total_item_value), 2) AS avg_item_revenue,
    ROUND(100.0 * SUM(f.freight_value) / NULLIF(SUM(f.price), 0), 2) AS freight_to_gmv_pct,
    ROUND(SUM(f.total_item_value) / NULLIF(COUNT(DISTINCT f.order_id), 0), 2) AS avg_order_value
FROM dwh.fact_order_item_sales f
LEFT JOIN dwh.dim_date d
    ON d.date_key = f.purchase_date_key
LEFT JOIN dwh.dim_product p
    ON p.product_key = f.product_key
LEFT JOIN dwh.dim_customer c
    ON c.customer_key = f.customer_key
LEFT JOIN dwh.dim_seller s
    ON s.seller_key = f.seller_key
LEFT JOIN dwh.dim_order_status os
    ON os.order_status_key = f.order_status_key
LEFT JOIN dwh.dim_geolocation customer_geo
    ON customer_geo.geolocation_key = f.customer_geolocation_key
WHERE d.year IS NOT NULL
GROUP BY
    d.year,
    d.month,
    d.month_name,
    COALESCE(p.product_category_name, 'Unknown'),
    COALESCE(p.product_category_name_english, 'Unknown'),
    COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown');
