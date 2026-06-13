{{ config(
    materialized='table',
    indexes=[
      {'columns': ['seller_id'], 'unique': True},
      {'columns': ['seller_state', 'seller_city']}
    ]
) }}

SELECT DISTINCT ON (seller_id)
    {{ dbt_utils.generate_surrogate_key(['seller_id']) }} AS seller_key,
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM {{ source('staging', 'olist_sellers') }}
WHERE seller_id IS NOT NULL
ORDER BY seller_id