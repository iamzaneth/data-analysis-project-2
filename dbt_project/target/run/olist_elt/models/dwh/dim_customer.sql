
  
    

  create  table "olist_db"."dwh"."dim_customer__dbt_tmp"
  
  
    as
  
  (
    

SELECT DISTINCT ON (customer_id)
    -- Tạo khóa chính (Surrogate Key) bằng md5 hash
    md5(cast(coalesce(cast(customer_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS customer_key,
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM "olist_db"."staging"."olist_customers"
WHERE customer_id IS NOT NULL
ORDER BY customer_id
  );
  