{{ config(
    materialized='table',
    indexes=[
      {'columns': ['order_status'], 'unique': True}
    ]
) }}

SELECT DISTINCT
    {{ dbt_utils.generate_surrogate_key(['order_status']) }} AS order_status_key,
    order_status
FROM {{ source('staging', 'olist_orders') }}
WHERE order_status IS NOT NULL