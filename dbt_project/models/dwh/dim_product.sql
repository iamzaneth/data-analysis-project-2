{{ config(
    materialized='table',
    indexes=[
      {'columns': ['product_id'], 'unique': True},
      {'columns': ['product_category_name']}
    ]
) }}

SELECT DISTINCT ON (p.product_id)
    {{ dbt_utils.generate_surrogate_key(['p.product_id']) }} AS product_key,
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
FROM {{ source('staging', 'olist_products') }} p
LEFT JOIN {{ source('staging', 'product_category_name_translation') }} t
    ON t.product_category_name = p.product_category_name
WHERE p.product_id IS NOT NULL
ORDER BY p.product_id