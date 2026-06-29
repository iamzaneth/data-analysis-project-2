
  
    

  create  table "olist_db"."dwh"."dim_seller__dbt_tmp"
  
  
    as
  
  (
    

SELECT DISTINCT ON (seller_id)
    md5(cast(coalesce(cast(seller_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS seller_key,
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM "olist_db"."staging"."olist_sellers"
WHERE seller_id IS NOT NULL
ORDER BY seller_id
  );
  