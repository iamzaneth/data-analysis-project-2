{{ config(
    materialized='table',
    indexes=[
      {'columns': ['order_id', 'payment_sequential'], 'unique': True},
      {'columns': ['order_id']},
      {'columns': ['customer_key']},
      {'columns': ['customer_geolocation_key']},
      {'columns': ['payment_type_key']},
      {'columns': ['order_status_key']},
      {'columns': ['purchase_date_key']}
    ]
) }}

SELECT
    op.order_id,
    op.payment_sequential,
    
    {{ dbt_utils.generate_surrogate_key(['o.customer_id']) }} AS customer_key,
    {{ dbt_utils.generate_surrogate_key(['c.customer_zip_code_prefix']) }} AS customer_geolocation_key,
    {{ dbt_utils.generate_surrogate_key(['op.payment_type']) }} AS payment_type_key,
    {{ dbt_utils.generate_surrogate_key(['o.order_status']) }} AS order_status_key,
    TO_CHAR(o.order_purchase_timestamp::DATE, 'YYYYMMDD')::INTEGER AS purchase_date_key,
    
    o.customer_id,
    op.payment_type,
    op.payment_installments,
    op.payment_value

FROM {{ source('staging', 'olist_order_payments') }} op
LEFT JOIN {{ source('staging', 'olist_orders') }} o
    ON o.order_id = op.order_id
LEFT JOIN {{ source('staging', 'olist_customers') }} c
    ON c.customer_id = o.customer_id
WHERE op.order_id IS NOT NULL
  AND op.payment_sequential IS NOT NULL