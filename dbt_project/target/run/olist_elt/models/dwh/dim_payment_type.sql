
  
    

  create  table "olist_db"."dwh"."dim_payment_type__dbt_tmp"
  
  
    as
  
  (
    

SELECT DISTINCT
    md5(cast(coalesce(cast(payment_type as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS payment_type_key,
    payment_type
FROM "olist_db"."staging"."olist_order_payments"
WHERE payment_type IS NOT NULL
  );
  