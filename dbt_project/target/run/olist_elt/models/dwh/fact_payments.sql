
  
    

  create  table "olist_db"."dwh"."fact_payments__dbt_tmp"
  
  
    as
  
  (
    

SELECT
    op.order_id,
    op.payment_sequential,
    
    md5(cast(coalesce(cast(o.customer_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS customer_key,
    md5(cast(coalesce(cast(c.customer_zip_code_prefix as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS customer_geolocation_key,
    md5(cast(coalesce(cast(op.payment_type as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS payment_type_key,
    md5(cast(coalesce(cast(o.order_status as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS order_status_key,
    TO_CHAR(o.order_purchase_timestamp::DATE, 'YYYYMMDD')::INTEGER AS purchase_date_key,
    
    o.customer_id,
    op.payment_type,
    op.payment_installments,
    op.payment_value

FROM "olist_db"."staging"."olist_order_payments" op
LEFT JOIN "olist_db"."staging"."olist_orders" o
    ON o.order_id = op.order_id
LEFT JOIN "olist_db"."staging"."olist_customers" c
    ON c.customer_id = o.customer_id
WHERE op.order_id IS NOT NULL
  AND op.payment_sequential IS NOT NULL
  );
  