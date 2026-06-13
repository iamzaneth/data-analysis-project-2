-- Analysis group: Hypothesis Queries
-- Objective: export analysis-ready datasets for statistical tests in
-- Python/Jupyter. These queries use DWH-level detail when mart aggregates are
-- not granular enough for hypothesis testing.

-- H1 Dataset: Late delivery vs review score
-- Independent variable: is_late
-- Dependent variable: review_score
SELECT
    r.order_id,
    d.is_late,
    d.delivery_days,
    d.delay_days,
    r.review_score
FROM "olist_db"."dwh"."fact_reviews" r
JOIN "olist_db"."dwh"."fact_order_delivery" d
    ON d.order_id = r.order_id
WHERE r.review_score IS NOT NULL
  AND d.is_late IS NOT NULL;

-- H2 Dataset: Delay duration vs review score
-- Independent variable: delay_days
-- Dependent variable: review_score
SELECT
    r.order_id,
    d.delivery_days,
    d.estimated_delivery_days,
    d.delay_days,
    d.is_late,
    r.review_score,
    CASE
        WHEN d.delay_days <= 0 THEN 'on_time_or_early'
        WHEN d.delay_days <= 3 THEN 'delay_1_3_days'
        WHEN d.delay_days <= 7 THEN 'delay_4_7_days'
        ELSE 'delay_8_plus_days'
    END AS delay_bucket
FROM "olist_db"."dwh"."fact_reviews" r
JOIN "olist_db"."dwh"."fact_order_delivery" d
    ON d.order_id = r.order_id
WHERE r.review_score IS NOT NULL
  AND d.delay_days IS NOT NULL;

-- H3 Dataset: Freight cost vs low review probability
-- Independent variable: freight_value / freight_to_item_ratio
-- Dependent variable: is_low_review
WITH order_sales AS (
    SELECT
        order_id,
        SUM(price) AS order_gmv,
        SUM(freight_value) AS order_freight_value,
        SUM(total_item_value) AS order_revenue,
        COUNT(*) AS order_item_count
    FROM "olist_db"."dwh"."fact_order_item_sales"
    GROUP BY order_id
)
SELECT
    r.order_id,
    s.order_gmv,
    s.order_freight_value,
    s.order_revenue,
    s.order_item_count,
    ROUND(s.order_freight_value::NUMERIC / NULLIF(s.order_gmv, 0), 4) AS freight_to_gmv_ratio,
    r.review_score,
    CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END AS is_low_review
FROM "olist_db"."dwh"."fact_reviews" r
JOIN order_sales s
    ON s.order_id = r.order_id
WHERE r.review_score IS NOT NULL
  AND s.order_gmv > 0;

-- H4 Dataset: Installment count vs payment value
-- Independent variable: payment_installments
-- Dependent variable: payment_value
SELECT
    order_id,
    payment_type,
    payment_installments,
    payment_value,
    CASE
        WHEN payment_installments <= 1 THEN 'single_payment'
        WHEN payment_installments BETWEEN 2 AND 3 THEN '2_3_installments'
        WHEN payment_installments BETWEEN 4 AND 6 THEN '4_6_installments'
        ELSE '7_plus_installments'
    END AS installment_bucket
FROM "olist_db"."dwh"."fact_payments"
WHERE payment_value IS NOT NULL
  AND payment_installments IS NOT NULL;

-- H5 Dataset: Category differences in low review rate
-- Independent variable: product_category_name
-- Dependent variable: is_low_review
WITH distinct_order_category AS (
    SELECT DISTINCT
        f.order_id,
        COALESCE(p.product_category_name, 'Unknown') AS product_category
    FROM "olist_db"."dwh"."fact_order_item_sales" f
    LEFT JOIN "olist_db"."dwh"."dim_product" p
        ON p.product_key = f.product_key
)
SELECT
    bridge.order_id,
    bridge.product_category,
    r.review_score,
    CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END AS is_low_review
FROM distinct_order_category bridge
JOIN "olist_db"."dwh"."fact_reviews" r
    ON r.order_id = bridge.order_id
WHERE r.review_score IS NOT NULL;

-- H6 Dataset: Regional delivery duration vs low review rate
-- Independent variable: delivery_days / customer_state / customer_city
-- Dependent variable: is_low_review
SELECT
    r.order_id,
    COALESCE(c.customer_state, geo.geolocation_state, 'Unknown') AS customer_state,
    COALESCE(c.customer_city, geo.geolocation_city, 'Unknown') AS customer_city,
    d.delivery_days,
    d.delay_days,
    d.is_late,
    r.review_score,
    CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END AS is_low_review
FROM "olist_db"."dwh"."fact_reviews" r
JOIN "olist_db"."dwh"."fact_order_delivery" d
    ON d.order_id = r.order_id
LEFT JOIN "olist_db"."dwh"."dim_customer" c
    ON c.customer_key = r.customer_key
LEFT JOIN "olist_db"."dwh"."dim_geolocation" geo
    ON geo.geolocation_key = r.customer_geolocation_key
WHERE r.review_score IS NOT NULL
  AND d.delivery_days IS NOT NULL;

-- H6 Aggregated support: Region-level delivery and review metrics
SELECT
    customer_state,
    customer_city,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(avg_delivery_days * delivered_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0), 2) AS avg_delivery_days,
    ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) * 100, 2) AS late_rate_pct,
    ROUND(SUM(avg_review_score * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0), 2) AS avg_review_score,
    ROUND(SUM(low_review_rate_pct * total_orders)::NUMERIC / NULLIF(SUM(total_orders) FILTER (WHERE low_review_rate_pct IS NOT NULL), 0), 2) AS low_review_rate_pct
FROM "olist_db"."mart"."mart_geolocation"
GROUP BY customer_state, customer_city
HAVING SUM(total_orders) >= 50
ORDER BY avg_delivery_days DESC;