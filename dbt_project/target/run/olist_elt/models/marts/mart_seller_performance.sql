
  
    

  create  table "olist_db"."mart"."mart_seller_performance__dbt_tmp"
  
  
    as
  
  (
    

WITH sales_base AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        f.order_id,
        f.seller_key,
        COALESCE(s.seller_id, f.seller_id, 'Unknown') AS seller_id,
        COALESCE(s.seller_state, seller_geo.geolocation_state, 'Unknown') AS seller_state,
        COALESCE(s.seller_city, seller_geo.geolocation_city, 'Unknown') AS seller_city,
        COALESCE(p.product_category_name, 'Unknown') AS product_category_name,
        f.price,
        f.freight_value,
        f.total_item_value
    FROM "olist_db"."dwh"."fact_order_item_sales" f
    LEFT JOIN "olist_db"."dwh"."dim_date" d
        ON d.date_key = f.purchase_date_key
    LEFT JOIN "olist_db"."dwh"."dim_seller" s
        ON s.seller_key = f.seller_key
    LEFT JOIN "olist_db"."dwh"."dim_product" p
        ON p.product_key = f.product_key
    LEFT JOIN "olist_db"."dwh"."dim_geolocation" seller_geo
        ON seller_geo.geolocation_key = f.seller_geolocation_key
    WHERE d.year IS NOT NULL
),
sales_by_seller_category_month AS (
    SELECT
        year,
        month,
        month_name,
        seller_key,
        seller_id,
        seller_state,
        seller_city,
        product_category_name,
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(*) AS total_items,
        ROUND(SUM(total_item_value)::NUMERIC, 2) AS total_revenue,
        ROUND(SUM(price)::NUMERIC, 2) AS gross_merchandise_value,
        ROUND(SUM(freight_value)::NUMERIC, 2) AS total_freight_value,
        ROUND(AVG(price)::NUMERIC, 2) AS avg_item_price,
        ROUND(AVG(freight_value)::NUMERIC, 2) AS avg_freight_value
    FROM sales_base
    GROUP BY
        year,
        month,
        month_name,
        seller_key,
        seller_id,
        seller_state,
        seller_city,
        product_category_name
),
distinct_order_seller_category_month AS (
    SELECT DISTINCT
        year,
        month,
        month_name,
        order_id,
        seller_key,
        seller_id,
        seller_state,
        seller_city,
        product_category_name
    FROM sales_base
),
delivery_by_seller_category_month AS (
    SELECT
        bridge.year,
        bridge.month,
        bridge.month_name,
        bridge.seller_key,
        bridge.seller_id,
        bridge.seller_state,
        bridge.seller_city,
        bridge.product_category_name,
        COUNT(DISTINCT bridge.order_id) FILTER (WHERE delivery.is_late IS TRUE) AS late_orders,
        ROUND(
            (100.0 * COUNT(DISTINCT bridge.order_id) FILTER (WHERE delivery.is_late IS TRUE)
            / NULLIF(COUNT(DISTINCT bridge.order_id) FILTER (WHERE delivery.order_delivered_customer_date IS NOT NULL), 0))::NUMERIC,
            2
        ) AS late_rate_pct
    FROM distinct_order_seller_category_month bridge
    LEFT JOIN "olist_db"."dwh"."fact_order_delivery" delivery
        ON delivery.order_id = bridge.order_id
    GROUP BY
        bridge.year,
        bridge.month,
        bridge.month_name,
        bridge.seller_key,
        bridge.seller_id,
        bridge.seller_state,
        bridge.seller_city,
        bridge.product_category_name
),
review_by_seller_category_month AS (
    SELECT
        bridge.year,
        bridge.month,
        bridge.month_name,
        bridge.seller_key,
        bridge.seller_id,
        bridge.seller_state,
        bridge.seller_city,
        bridge.product_category_name,
        COUNT(r.review_id) AS total_reviews,
        ROUND(AVG(r.review_score)::NUMERIC, 2) AS avg_review_score,
        COUNT(r.review_id) FILTER (WHERE r.review_score <= 2) AS low_review_count,
        ROUND((100.0 * COUNT(r.review_id) FILTER (WHERE r.review_score <= 2) / NULLIF(COUNT(r.review_id), 0))::NUMERIC, 2) AS low_review_rate_pct
    FROM distinct_order_seller_category_month bridge
    LEFT JOIN "olist_db"."dwh"."fact_reviews" r
        ON r.order_id = bridge.order_id
    GROUP BY
        bridge.year,
        bridge.month,
        bridge.month_name,
        bridge.seller_key,
        bridge.seller_id,
        bridge.seller_state,
        bridge.seller_city,
        bridge.product_category_name
)
SELECT
    sales.year,
    sales.month,
    sales.month_name,
    sales.seller_id,
    sales.seller_state,
    sales.seller_city,
    sales.product_category_name,
    sales.total_orders,
    sales.total_items,
    sales.total_revenue,
    sales.gross_merchandise_value,
    sales.total_freight_value,
    sales.avg_item_price,
    sales.avg_freight_value,
    review.avg_review_score,
    COALESCE(review.low_review_count, 0) AS low_review_count,
    review.low_review_rate_pct,
    COALESCE(delivery.late_orders, 0) AS late_orders,
    delivery.late_rate_pct
FROM sales_by_seller_category_month sales
LEFT JOIN delivery_by_seller_category_month delivery
    ON delivery.year = sales.year
   AND delivery.month = sales.month
   AND delivery.seller_key = sales.seller_key
   AND delivery.product_category_name = sales.product_category_name
LEFT JOIN review_by_seller_category_month review
    ON review.year = sales.year
   AND review.month = sales.month
   AND review.seller_key = sales.seller_key
   AND review.product_category_name = sales.product_category_name
  );
  