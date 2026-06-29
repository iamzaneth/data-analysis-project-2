
  
    

  create  table "olist_db"."mart"."mart_payment__dbt_tmp"
  
  
    as
  
  (
    

SELECT
    d.year,
    d.month,
    d.month_name,
    COALESCE(pt.payment_type, f.payment_type, 'Unknown') AS payment_type,
    COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown') AS customer_state,
    COUNT(*) AS total_payment_records,
    COUNT(DISTINCT f.order_id) AS total_orders,
    COUNT(DISTINCT f.customer_key) AS total_customers,
    ROUND(SUM(f.payment_value)::NUMERIC, 2) AS total_payment_value,
    ROUND(AVG(f.payment_value)::NUMERIC, 2) AS avg_payment_value,
    ROUND(AVG(f.payment_installments)::NUMERIC, 2) AS avg_installments,
    MAX(f.payment_installments) AS max_installments,
    COUNT(DISTINCT f.order_id) FILTER (WHERE COALESCE(f.payment_installments, 0) <= 1) AS single_payment_orders,
    COUNT(DISTINCT f.order_id) FILTER (WHERE f.payment_installments > 1) AS installment_orders,
    ROUND(
        (100.0 * COUNT(DISTINCT f.order_id) FILTER (WHERE f.payment_installments > 1)
        / NULLIF(COUNT(DISTINCT f.order_id), 0))::NUMERIC,
        2
    ) AS installment_order_rate_pct
FROM "olist_db"."dwh"."fact_payments" f
LEFT JOIN "olist_db"."dwh"."dim_payment_type" pt
    ON pt.payment_type_key = f.payment_type_key
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
    COALESCE(pt.payment_type, f.payment_type, 'Unknown'),
    COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown')
  );
  