
  
    

  create  table "olist_db"."mart"."mart_sales__dbt_tmp"
  
  
    as
  
  (
    

SELECT
    d.year,
    d.month,
    d.month_name,
    COALESCE(p.product_category_name, 'Unknown') AS product_category_name,
    COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown') AS customer_state,
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(*) AS total_order_items,
    COUNT(DISTINCT f.seller_key) AS total_sellers,
    ROUND(SUM(f.price)::NUMERIC, 2) AS gross_merchandise_value,
    ROUND(SUM(f.freight_value)::NUMERIC, 2) AS total_freight_value,
    ROUND(SUM(f.total_item_value)::NUMERIC, 2) AS total_item_revenue,
    ROUND(AVG(f.price)::NUMERIC, 2) AS avg_item_price,
    ROUND(AVG(f.freight_value)::NUMERIC, 2) AS avg_freight_value,
    ROUND(AVG(f.total_item_value)::NUMERIC, 2) AS avg_item_revenue,
    ROUND((100.0 * SUM(f.freight_value) / NULLIF(SUM(f.price), 0))::NUMERIC, 2) AS freight_to_gmv_pct,
    ROUND((SUM(f.total_item_value) / NULLIF(COUNT(DISTINCT f.order_id), 0))::NUMERIC, 2) AS avg_order_value
FROM "olist_db"."dwh"."fact_order_item_sales" f
LEFT JOIN "olist_db"."dwh"."dim_date" d
    ON d.date_key = f.purchase_date_key
LEFT JOIN "olist_db"."dwh"."dim_product" p
    ON p.product_key = f.product_key
LEFT JOIN "olist_db"."dwh"."dim_customer" c
    ON c.customer_key = f.customer_key
LEFT JOIN "olist_db"."dwh"."dim_seller" s
    ON s.seller_key = f.seller_key
LEFT JOIN "olist_db"."dwh"."dim_order_status" os
    ON os.order_status_key = f.order_status_key
LEFT JOIN "olist_db"."dwh"."dim_geolocation" customer_geo
    ON customer_geo.geolocation_key = f.customer_geolocation_key
WHERE d.year IS NOT NULL
GROUP BY
    d.year,
    d.month,
    d.month_name,
    COALESCE(p.product_category_name, 'Unknown'),
    COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown')
  );
  