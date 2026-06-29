{{ config(
    materialized='table',
    indexes=[
      {'columns': ['year', 'month']},
      {'columns': ['customer_state', 'customer_city']}
    ]
) }}

WITH sales_geo_agg AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown') AS customer_state,
        COALESCE(c.customer_city, customer_geo.geolocation_city, 'Unknown') AS customer_city,
        COUNT(DISTINCT f.order_id) AS total_orders,
        COUNT(DISTINCT f.customer_key) AS total_customers,
        ROUND(SUM(f.total_item_value)::NUMERIC, 2) AS total_revenue,
        ROUND(SUM(f.price)::NUMERIC, 2) AS gross_merchandise_value,
        ROUND(SUM(f.freight_value)::NUMERIC, 2) AS total_freight_value,
        ROUND((SUM(f.total_item_value) / NULLIF(COUNT(DISTINCT f.order_id), 0))::NUMERIC, 2) AS avg_order_value
    FROM {{ ref('fact_order_item_sales') }} f
    LEFT JOIN {{ ref('dim_date') }} d
        ON d.date_key = f.purchase_date_key
    LEFT JOIN {{ ref('dim_customer') }} c
        ON c.customer_key = f.customer_key
    LEFT JOIN {{ ref('dim_geolocation') }} customer_geo
        ON customer_geo.geolocation_key = f.customer_geolocation_key
    WHERE d.year IS NOT NULL
    GROUP BY
        d.year,
        d.month,
        d.month_name,
        COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown'),
        COALESCE(c.customer_city, customer_geo.geolocation_city, 'Unknown')
),
delivery_geo_agg AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown') AS customer_state,
        COALESCE(c.customer_city, customer_geo.geolocation_city, 'Unknown') AS customer_city,
        COUNT(DISTINCT f.order_id) FILTER (WHERE f.order_delivered_customer_date IS NOT NULL) AS delivered_orders,
        COUNT(DISTINCT f.order_id) FILTER (WHERE f.is_late IS TRUE) AS late_orders,
        ROUND(
            (100.0 * COUNT(DISTINCT f.order_id) FILTER (WHERE f.is_late IS TRUE)
            / NULLIF(COUNT(DISTINCT f.order_id) FILTER (WHERE f.order_delivered_customer_date IS NOT NULL), 0))::NUMERIC,
            2
        ) AS late_rate_pct,
        ROUND(AVG(f.delivery_days)::NUMERIC, 2) AS avg_delivery_days,
        ROUND(AVG(f.delay_days)::NUMERIC, 2) AS avg_delay_days
    FROM {{ ref('fact_order_delivery') }} f
    LEFT JOIN {{ ref('dim_date') }} d
        ON d.date_key = f.purchase_date_key
    LEFT JOIN {{ ref('dim_customer') }} c
        ON c.customer_key = f.customer_key
    LEFT JOIN {{ ref('dim_geolocation') }} customer_geo
        ON customer_geo.geolocation_key = f.customer_geolocation_key
    WHERE d.year IS NOT NULL
    GROUP BY
        d.year,
        d.month,
        d.month_name,
        COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown'),
        COALESCE(c.customer_city, customer_geo.geolocation_city, 'Unknown')
),
review_geo_agg AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown') AS customer_state,
        COALESCE(c.customer_city, customer_geo.geolocation_city, 'Unknown') AS customer_city,
        ROUND(AVG(r.review_score)::NUMERIC, 2) AS avg_review_score,
        ROUND((100.0 * COUNT(*) FILTER (WHERE r.review_score <= 2) / NULLIF(COUNT(*), 0))::NUMERIC, 2) AS low_review_rate_pct
    FROM {{ ref('fact_reviews') }} r
    LEFT JOIN {{ ref('dim_date') }} d
        ON d.date_key = r.review_creation_date_key
    LEFT JOIN {{ ref('dim_customer') }} c
        ON c.customer_key = r.customer_key
    LEFT JOIN {{ ref('dim_geolocation') }} customer_geo
        ON customer_geo.geolocation_key = r.customer_geolocation_key
    WHERE d.year IS NOT NULL
    GROUP BY
        d.year,
        d.month,
        d.month_name,
        COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown'),
        COALESCE(c.customer_city, customer_geo.geolocation_city, 'Unknown')
),
payment_geo_agg AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown') AS customer_state,
        COALESCE(c.customer_city, customer_geo.geolocation_city, 'Unknown') AS customer_city,
        ROUND(SUM(f.payment_value)::NUMERIC, 2) AS total_payment_value,
        ROUND(AVG(f.payment_value)::NUMERIC, 2) AS avg_payment_value
    FROM {{ ref('fact_payments') }} f
    LEFT JOIN {{ ref('dim_date') }} d
        ON d.date_key = f.purchase_date_key
    LEFT JOIN {{ ref('dim_customer') }} c
        ON c.customer_key = f.customer_key
    LEFT JOIN {{ ref('dim_geolocation') }} customer_geo
        ON customer_geo.geolocation_key = f.customer_geolocation_key
    WHERE d.year IS NOT NULL
    GROUP BY
        d.year,
        d.month,
        d.month_name,
        COALESCE(c.customer_state, customer_geo.geolocation_state, 'Unknown'),
        COALESCE(c.customer_city, customer_geo.geolocation_city, 'Unknown')
),
geo_keys AS (
    SELECT year, month, month_name, customer_state, customer_city FROM sales_geo_agg
    UNION
    SELECT year, month, month_name, customer_state, customer_city FROM delivery_geo_agg
    UNION
    SELECT year, month, month_name, customer_state, customer_city FROM review_geo_agg
    UNION
    SELECT year, month, month_name, customer_state, customer_city FROM payment_geo_agg
)
SELECT
    keys.year,
    keys.month,
    keys.month_name,
    keys.customer_state,
    keys.customer_city,
    COALESCE(sales.total_orders, 0) AS total_orders,
    COALESCE(sales.total_customers, 0) AS total_customers,
    COALESCE(sales.total_revenue, 0) AS total_revenue,
    COALESCE(sales.gross_merchandise_value, 0) AS gross_merchandise_value,
    COALESCE(sales.total_freight_value, 0) AS total_freight_value,
    sales.avg_order_value,
    COALESCE(delivery.delivered_orders, 0) AS delivered_orders,
    COALESCE(delivery.late_orders, 0) AS late_orders,
    delivery.late_rate_pct,
    delivery.avg_delivery_days,
    delivery.avg_delay_days,
    review.avg_review_score,
    review.low_review_rate_pct,
    COALESCE(payment.total_payment_value, 0) AS total_payment_value,
    payment.avg_payment_value
FROM geo_keys keys
LEFT JOIN sales_geo_agg sales
    ON sales.year = keys.year
   AND sales.month = keys.month
   AND sales.customer_state = keys.customer_state
   AND sales.customer_city = keys.customer_city
LEFT JOIN delivery_geo_agg delivery
    ON delivery.year = keys.year
   AND delivery.month = keys.month
   AND delivery.customer_state = keys.customer_state
   AND delivery.customer_city = keys.customer_city
LEFT JOIN review_geo_agg review
    ON review.year = keys.year
   AND review.month = keys.month
   AND review.customer_state = keys.customer_state
   AND review.customer_city = keys.customer_city
LEFT JOIN payment_geo_agg payment
    ON payment.year = keys.year
   AND payment.month = keys.month
   AND payment.customer_state = keys.customer_state
   AND payment.customer_city = keys.customer_city