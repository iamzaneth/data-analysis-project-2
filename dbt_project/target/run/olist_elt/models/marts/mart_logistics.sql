
  
    

  create  table "olist_db"."mart"."mart_logistics__dbt_tmp"
  
  
    as
  
  (
    

SELECT
    d.year,
    d.month,
    d.month_name,
    COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown') AS customer_state,
    COALESCE(os.order_status, f.order_status, 'Unknown') AS order_status,
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(DISTINCT f.order_id) FILTER (WHERE f.order_delivered_customer_date IS NOT NULL) AS delivered_orders,
    COUNT(DISTINCT f.order_id) FILTER (WHERE f.is_late IS TRUE) AS late_orders,
    ROUND(
        100.0 * COUNT(DISTINCT f.order_id) FILTER (WHERE f.is_late IS TRUE)
        / NULLIF(COUNT(DISTINCT f.order_id) FILTER (WHERE f.order_delivered_customer_date IS NOT NULL), 0),
        2
    ) AS late_rate_pct,
    ROUND(AVG(f.approval_hours) / 24.0, 2) AS avg_approval_days,
    ROUND(AVG(f.delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(f.estimated_delivery_days), 2) AS avg_estimated_delivery_days,
    ROUND(AVG(f.delay_days), 2) AS avg_delay_days,
    ROUND(AVG(f.delay_days) FILTER (WHERE f.delay_days > 0), 2) AS avg_delay_days_for_late_orders,
    ROUND(MAX(f.delay_days), 2) AS max_delay_days
FROM "olist_db"."dwh"."fact_order_delivery" f
LEFT JOIN "olist_db"."dwh"."dim_date" d
    ON d.date_key = f.purchase_date_key
LEFT JOIN "olist_db"."dwh"."dim_customer" c
    ON c.customer_key = f.customer_key
LEFT JOIN "olist_db"."dwh"."dim_order_status" os
    ON os.order_status_key = f.order_status_key
LEFT JOIN "olist_db"."dwh"."dim_geolocation" customer_geo
    ON customer_geo.geolocation_key = f.customer_geolocation_key
WHERE d.year IS NOT NULL
GROUP BY
    d.year,
    d.month,
    d.month_name,
    COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown'),
    COALESCE(os.order_status, f.order_status, 'Unknown')
  );
  