{{ config(
    materialized='table',
    indexes=[
      {'columns': ['payment_type'], 'unique': True}
    ]
) }}

SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key(['payment_type']) }} AS payment_type_key,
    payment_type
FROM {{ source('staging', 'olist_order_payments') }}
WHERE payment_type IS NOT NULL