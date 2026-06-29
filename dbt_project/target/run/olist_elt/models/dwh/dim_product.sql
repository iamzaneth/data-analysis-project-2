
  
    

  create  table "olist_db"."dwh"."dim_product__dbt_tmp"
  
  
    as
  
  (
    

SELECT DISTINCT ON (p.product_id)
    md5(cast(coalesce(cast(p.product_id as TEXT), '_dbt_utils_surrogate_key_null_') as TEXT)) AS product_key,
    p.product_id,
    COALESCE(t.product_category_name_english, 'Unknown') AS product_category_name,
    p.product_name_lenght AS product_name_length,
    p.product_description_lenght AS product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    (p.product_length_cm * p.product_height_cm * p.product_width_cm) AS product_volume_cm3
FROM "olist_db"."staging"."olist_products" p
LEFT JOIN "olist_db"."staging"."product_category_name_translation" t
    ON t.product_category_name = p.product_category_name
WHERE p.product_id IS NOT NULL
ORDER BY p.product_id
  );
  