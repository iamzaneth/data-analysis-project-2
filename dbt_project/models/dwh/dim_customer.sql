{{ config(
    materialized='table',
    indexes=[
      {'columns': ['customer_id'], 'unique': True},
      {'columns': ['customer_state', 'customer_city']}
    ]
) }}

SELECT DISTINCT ON (customer_id)
    -- Tạo khóa chính (Surrogate Key) bằng md5 hash
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} AS customer_key,
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM {{ source('staging', 'olist_customers') }}
WHERE customer_id IS NOT NULL
ORDER BY customer_id