{{ config(
    materialized='table',
    indexes=[
      {'columns': ['year', 'month']},
      {'columns': ['product_category_name']}
    ]
) }}

WITH sales_base AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        f.order_id,
        f.seller_key,
        COALESCE(p.product_category_name, 'Unknown') AS product_category_name,
        f.price,
        f.freight_value,
        f.total_item_value,
        p.product_weight_g,
        p.product_volume_cm3
    FROM {{ ref('fact_order_item_sales') }} f
    LEFT JOIN {{ ref('dim_date') }} d
        ON d.date_key = f.purchase_date_key
    LEFT JOIN {{ ref('dim_product') }} p
        ON p.product_key = f.product_key
    LEFT JOIN {{ ref('dim_seller') }} s
        ON s.seller_key = f.seller_key
    WHERE d.year IS NOT NULL
),
sales_by_category_month AS (
    SELECT
        year,
        month,
        month_name,
        product_category_name,
        COUNT(DISTINCT order_id) AS total_orders,
        COUNT(*) AS total_items,
        COUNT(DISTINCT seller_key) AS total_sellers,
        ROUND(SUM(price)::NUMERIC, 2) AS gross_merchandise_value,
        ROUND(SUM(freight_value)::NUMERIC, 2) AS total_freight_value,
        ROUND(SUM(total_item_value)::NUMERIC, 2) AS total_revenue,
        ROUND(AVG(price)::NUMERIC, 2) AS avg_price,
        ROUND(AVG(freight_value)::NUMERIC, 2) AS avg_freight_value,
        ROUND(AVG(product_weight_g)::NUMERIC, 2) AS avg_product_weight_g,
        ROUND(AVG(product_volume_cm3)::NUMERIC, 2) AS avg_product_volume_cm3
    FROM sales_base
    GROUP BY
        year,
        month,
        month_name,
        product_category_name
),
distinct_order_category_month AS (
    SELECT DISTINCT
        year,
        month,
        month_name,
        order_id,
        product_category_name
    FROM sales_base
),
review_by_category_month AS (
    SELECT
        bridge.year,
        bridge.month,
        bridge.month_name,
        bridge.product_category_name,
        COUNT(r.review_id) AS total_reviews,
        ROUND(AVG(r.review_score)::NUMERIC, 2) AS avg_review_score,
        COUNT(r.review_id) FILTER (WHERE r.review_score <= 2) AS low_review_count,
        ROUND((100.0 * COUNT(r.review_id) FILTER (WHERE r.review_score <= 2) / NULLIF(COUNT(r.review_id), 0))::NUMERIC, 2) AS low_review_rate_pct
    FROM distinct_order_category_month bridge
    LEFT JOIN {{ ref('fact_reviews') }} r
        ON r.order_id = bridge.order_id
    GROUP BY
        bridge.year,
        bridge.month,
        bridge.month_name,
        bridge.product_category_name
)
SELECT
    sales.year,
    sales.month,
    sales.month_name,
    sales.product_category_name,
    sales.total_orders,
    sales.total_items,
    sales.total_sellers,
    sales.gross_merchandise_value,
    sales.total_freight_value,
    sales.total_revenue,
    sales.avg_price,
    sales.avg_freight_value,
    sales.avg_product_weight_g,
    sales.avg_product_volume_cm3,
    review.avg_review_score,
    COALESCE(review.low_review_count, 0) AS low_review_count,
    review.low_review_rate_pct
FROM sales_by_category_month sales
LEFT JOIN review_by_category_month review
    ON review.year = sales.year
   AND review.month = sales.month
   AND review.product_category_name = sales.product_category_name