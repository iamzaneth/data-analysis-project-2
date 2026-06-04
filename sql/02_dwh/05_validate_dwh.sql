\echo '1. DWH row count by table'

SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM dwh.dim_date
UNION ALL
SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM dwh.dim_customer
UNION ALL
SELECT 'dim_seller' AS table_name, COUNT(*) AS row_count FROM dwh.dim_seller
UNION ALL
SELECT 'dim_product' AS table_name, COUNT(*) AS row_count FROM dwh.dim_product
UNION ALL
SELECT 'dim_order_status' AS table_name, COUNT(*) AS row_count FROM dwh.dim_order_status
UNION ALL
SELECT 'dim_payment_type' AS table_name, COUNT(*) AS row_count FROM dwh.dim_payment_type
UNION ALL
SELECT 'fact_order_item_sales' AS table_name, COUNT(*) AS row_count FROM dwh.fact_order_item_sales
UNION ALL
SELECT 'fact_order_delivery' AS table_name, COUNT(*) AS row_count FROM dwh.fact_order_delivery
UNION ALL
SELECT 'fact_payments' AS table_name, COUNT(*) AS row_count FROM dwh.fact_payments
UNION ALL
SELECT 'fact_reviews' AS table_name, COUNT(*) AS row_count FROM dwh.fact_reviews
ORDER BY table_name;

\echo '2. Empty DWH tables'

WITH table_counts AS (
    SELECT 'dim_date' AS table_name, COUNT(*) AS row_count FROM dwh.dim_date
    UNION ALL SELECT 'dim_customer' AS table_name, COUNT(*) AS row_count FROM dwh.dim_customer
    UNION ALL SELECT 'dim_seller' AS table_name, COUNT(*) AS row_count FROM dwh.dim_seller
    UNION ALL SELECT 'dim_product' AS table_name, COUNT(*) AS row_count FROM dwh.dim_product
    UNION ALL SELECT 'dim_order_status' AS table_name, COUNT(*) AS row_count FROM dwh.dim_order_status
    UNION ALL SELECT 'dim_payment_type' AS table_name, COUNT(*) AS row_count FROM dwh.dim_payment_type
    UNION ALL SELECT 'fact_order_item_sales' AS table_name, COUNT(*) AS row_count FROM dwh.fact_order_item_sales
    UNION ALL SELECT 'fact_order_delivery' AS table_name, COUNT(*) AS row_count FROM dwh.fact_order_delivery
    UNION ALL SELECT 'fact_payments' AS table_name, COUNT(*) AS row_count FROM dwh.fact_payments
    UNION ALL SELECT 'fact_reviews' AS table_name, COUNT(*) AS row_count FROM dwh.fact_reviews
)
SELECT table_name, row_count
FROM table_counts
WHERE row_count = 0
ORDER BY table_name;

\echo '3. Staging to DWH row count reconciliation'

SELECT
    'dim_customer' AS dwh_table,
    (SELECT COUNT(DISTINCT customer_id) FROM staging.olist_customers WHERE customer_id IS NOT NULL) AS staging_count,
    (SELECT COUNT(*) FROM dwh.dim_customer) AS dwh_count
UNION ALL
SELECT
    'dim_seller' AS dwh_table,
    (SELECT COUNT(DISTINCT seller_id) FROM staging.olist_sellers WHERE seller_id IS NOT NULL) AS staging_count,
    (SELECT COUNT(*) FROM dwh.dim_seller) AS dwh_count
UNION ALL
SELECT
    'dim_product' AS dwh_table,
    (SELECT COUNT(DISTINCT product_id) FROM staging.olist_products WHERE product_id IS NOT NULL) AS staging_count,
    (SELECT COUNT(*) FROM dwh.dim_product) AS dwh_count
UNION ALL
SELECT
    'dim_order_status' AS dwh_table,
    (SELECT COUNT(DISTINCT order_status) FROM staging.olist_orders WHERE order_status IS NOT NULL) AS staging_count,
    (SELECT COUNT(*) FROM dwh.dim_order_status) AS dwh_count
UNION ALL
SELECT
    'dim_payment_type' AS dwh_table,
    (SELECT COUNT(DISTINCT payment_type) FROM staging.olist_order_payments WHERE payment_type IS NOT NULL) AS staging_count,
    (SELECT COUNT(*) FROM dwh.dim_payment_type) AS dwh_count
UNION ALL
SELECT
    'fact_order_item_sales' AS dwh_table,
    (SELECT COUNT(*) FROM staging.olist_order_items WHERE order_id IS NOT NULL AND order_item_id IS NOT NULL) AS staging_count,
    (SELECT COUNT(*) FROM dwh.fact_order_item_sales) AS dwh_count
UNION ALL
SELECT
    'fact_order_delivery' AS dwh_table,
    (SELECT COUNT(*) FROM staging.olist_orders WHERE order_id IS NOT NULL) AS staging_count,
    (SELECT COUNT(*) FROM dwh.fact_order_delivery) AS dwh_count
UNION ALL
SELECT
    'fact_payments' AS dwh_table,
    (SELECT COUNT(*) FROM staging.olist_order_payments WHERE order_id IS NOT NULL AND payment_sequential IS NOT NULL) AS staging_count,
    (SELECT COUNT(*) FROM dwh.fact_payments) AS dwh_count
UNION ALL
SELECT
    'fact_reviews' AS dwh_table,
    (SELECT COUNT(*) FROM staging.olist_order_reviews WHERE review_id IS NOT NULL AND order_id IS NOT NULL) AS staging_count,
    (SELECT COUNT(*) FROM dwh.fact_reviews) AS dwh_count
ORDER BY dwh_table;

\echo '4. Missing dimension keys in facts'

SELECT 'fact_order_item_sales.customer_key' AS check_name, COUNT(*) AS issue_count
FROM dwh.fact_order_item_sales
WHERE customer_key IS NULL
UNION ALL
SELECT 'fact_order_item_sales.seller_key' AS check_name, COUNT(*) AS issue_count
FROM dwh.fact_order_item_sales
WHERE seller_key IS NULL
UNION ALL
SELECT 'fact_order_item_sales.product_key' AS check_name, COUNT(*) AS issue_count
FROM dwh.fact_order_item_sales
WHERE product_key IS NULL
UNION ALL
SELECT 'fact_order_item_sales.order_status_key' AS check_name, COUNT(*) AS issue_count
FROM dwh.fact_order_item_sales
WHERE order_status_key IS NULL
UNION ALL
SELECT 'fact_order_delivery.customer_key' AS check_name, COUNT(*) AS issue_count
FROM dwh.fact_order_delivery
WHERE customer_key IS NULL
UNION ALL
SELECT 'fact_order_delivery.order_status_key' AS check_name, COUNT(*) AS issue_count
FROM dwh.fact_order_delivery
WHERE order_status_key IS NULL
UNION ALL
SELECT 'fact_payments.customer_key' AS check_name, COUNT(*) AS issue_count
FROM dwh.fact_payments
WHERE customer_key IS NULL
UNION ALL
SELECT 'fact_payments.payment_type_key' AS check_name, COUNT(*) AS issue_count
FROM dwh.fact_payments
WHERE payment_type_key IS NULL
UNION ALL
SELECT 'fact_payments.order_status_key' AS check_name, COUNT(*) AS issue_count
FROM dwh.fact_payments
WHERE order_status_key IS NULL
UNION ALL
SELECT 'fact_reviews.customer_key' AS check_name, COUNT(*) AS issue_count
FROM dwh.fact_reviews
WHERE customer_key IS NULL
UNION ALL
SELECT 'fact_reviews.order_status_key' AS check_name, COUNT(*) AS issue_count
FROM dwh.fact_reviews
WHERE order_status_key IS NULL
ORDER BY check_name;

\echo '5. Negative money values in facts'

SELECT
    'fact_order_item_sales.price' AS check_name,
    COUNT(*) AS issue_count,
    MIN(price) AS min_value
FROM dwh.fact_order_item_sales
WHERE price < 0
UNION ALL
SELECT
    'fact_order_item_sales.freight_value' AS check_name,
    COUNT(*) AS issue_count,
    MIN(freight_value) AS min_value
FROM dwh.fact_order_item_sales
WHERE freight_value < 0
UNION ALL
SELECT
    'fact_order_item_sales.total_item_value' AS check_name,
    COUNT(*) AS issue_count,
    MIN(total_item_value) AS min_value
FROM dwh.fact_order_item_sales
WHERE total_item_value < 0
UNION ALL
SELECT
    'fact_payments.payment_value' AS check_name,
    COUNT(*) AS issue_count,
    MIN(payment_value) AS min_value
FROM dwh.fact_payments
WHERE payment_value < 0
ORDER BY check_name;

\echo '6. Review scores outside 1-5 in DWH'

SELECT
    COUNT(*) AS issue_count,
    MIN(review_score) AS min_review_score,
    MAX(review_score) AS max_review_score
FROM dwh.fact_reviews
WHERE review_score NOT BETWEEN 1 AND 5
   OR review_score IS NULL;

\echo '7. Late delivery rate'

SELECT
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NOT NULL) AS delivered_order_count,
    COUNT(*) FILTER (WHERE is_late IS TRUE) AS late_order_count,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE is_late IS TRUE)
        / NULLIF(COUNT(*) FILTER (WHERE order_delivered_customer_date IS NOT NULL), 0),
        2
    ) AS late_rate_pct,
    ROUND(AVG(delay_days) FILTER (WHERE delay_days > 0), 2) AS avg_delay_days_for_late_orders
FROM dwh.fact_order_delivery;

\echo '8. Total revenue from fact_order_item_sales'

SELECT
    COUNT(*) AS order_item_count,
    ROUND(SUM(price), 2) AS gross_merchandise_value,
    ROUND(SUM(freight_value), 2) AS total_freight_value,
    ROUND(SUM(total_item_value), 2) AS total_item_revenue
FROM dwh.fact_order_item_sales;

\echo '9. DWH validation summary'

WITH row_reconciliation AS (
    SELECT
        (SELECT COUNT(DISTINCT customer_id) FROM staging.olist_customers WHERE customer_id IS NOT NULL) AS staging_count,
        (SELECT COUNT(*) FROM dwh.dim_customer) AS dwh_count
    UNION ALL
    SELECT
        (SELECT COUNT(DISTINCT seller_id) FROM staging.olist_sellers WHERE seller_id IS NOT NULL),
        (SELECT COUNT(*) FROM dwh.dim_seller)
    UNION ALL
    SELECT
        (SELECT COUNT(DISTINCT product_id) FROM staging.olist_products WHERE product_id IS NOT NULL),
        (SELECT COUNT(*) FROM dwh.dim_product)
    UNION ALL
    SELECT
        (SELECT COUNT(DISTINCT order_status) FROM staging.olist_orders WHERE order_status IS NOT NULL),
        (SELECT COUNT(*) FROM dwh.dim_order_status)
    UNION ALL
    SELECT
        (SELECT COUNT(DISTINCT payment_type) FROM staging.olist_order_payments WHERE payment_type IS NOT NULL),
        (SELECT COUNT(*) FROM dwh.dim_payment_type)
    UNION ALL
    SELECT
        (SELECT COUNT(*) FROM staging.olist_order_items WHERE order_id IS NOT NULL AND order_item_id IS NOT NULL),
        (SELECT COUNT(*) FROM dwh.fact_order_item_sales)
    UNION ALL
    SELECT
        (SELECT COUNT(*) FROM staging.olist_orders WHERE order_id IS NOT NULL),
        (SELECT COUNT(*) FROM dwh.fact_order_delivery)
    UNION ALL
    SELECT
        (SELECT COUNT(*) FROM staging.olist_order_payments WHERE order_id IS NOT NULL AND payment_sequential IS NOT NULL),
        (SELECT COUNT(*) FROM dwh.fact_payments)
    UNION ALL
    SELECT
        (SELECT COUNT(*) FROM staging.olist_order_reviews WHERE review_id IS NOT NULL AND order_id IS NOT NULL),
        (SELECT COUNT(*) FROM dwh.fact_reviews)
),
missing_dimension_keys AS (
    SELECT COUNT(*) AS issue_count FROM dwh.fact_order_item_sales WHERE customer_key IS NULL
    UNION ALL SELECT COUNT(*) FROM dwh.fact_order_item_sales WHERE seller_key IS NULL
    UNION ALL SELECT COUNT(*) FROM dwh.fact_order_item_sales WHERE product_key IS NULL
    UNION ALL SELECT COUNT(*) FROM dwh.fact_order_item_sales WHERE order_status_key IS NULL
    UNION ALL SELECT COUNT(*) FROM dwh.fact_order_delivery WHERE customer_key IS NULL
    UNION ALL SELECT COUNT(*) FROM dwh.fact_order_delivery WHERE order_status_key IS NULL
    UNION ALL SELECT COUNT(*) FROM dwh.fact_payments WHERE customer_key IS NULL
    UNION ALL SELECT COUNT(*) FROM dwh.fact_payments WHERE payment_type_key IS NULL
    UNION ALL SELECT COUNT(*) FROM dwh.fact_payments WHERE order_status_key IS NULL
    UNION ALL SELECT COUNT(*) FROM dwh.fact_reviews WHERE customer_key IS NULL
    UNION ALL SELECT COUNT(*) FROM dwh.fact_reviews WHERE order_status_key IS NULL
),
checks AS (
    SELECT
        'empty_tables' AS check_name,
        COUNT(*) AS issue_count
    FROM (
        SELECT COUNT(*) AS row_count FROM dwh.dim_date
        UNION ALL SELECT COUNT(*) FROM dwh.dim_customer
        UNION ALL SELECT COUNT(*) FROM dwh.dim_seller
        UNION ALL SELECT COUNT(*) FROM dwh.dim_product
        UNION ALL SELECT COUNT(*) FROM dwh.dim_order_status
        UNION ALL SELECT COUNT(*) FROM dwh.dim_payment_type
        UNION ALL SELECT COUNT(*) FROM dwh.fact_order_item_sales
        UNION ALL SELECT COUNT(*) FROM dwh.fact_order_delivery
        UNION ALL SELECT COUNT(*) FROM dwh.fact_payments
        UNION ALL SELECT COUNT(*) FROM dwh.fact_reviews
    ) table_counts
    WHERE row_count = 0

    UNION ALL
    SELECT
        'row_count_mismatch' AS check_name,
        COUNT(*) AS issue_count
    FROM row_reconciliation
    WHERE staging_count <> dwh_count

    UNION ALL
    SELECT
        'missing_dimension_keys' AS check_name,
        COALESCE(SUM(issue_count), 0)::BIGINT AS issue_count
    FROM missing_dimension_keys

    UNION ALL
    SELECT
        'negative_money_values' AS check_name,
        SUM(issue_count)::BIGINT AS issue_count
    FROM (
        SELECT COUNT(*) AS issue_count FROM dwh.fact_order_item_sales WHERE price < 0
        UNION ALL SELECT COUNT(*) FROM dwh.fact_order_item_sales WHERE freight_value < 0
        UNION ALL SELECT COUNT(*) FROM dwh.fact_order_item_sales WHERE total_item_value < 0
        UNION ALL SELECT COUNT(*) FROM dwh.fact_payments WHERE payment_value < 0
    ) negative_values

    UNION ALL
    SELECT
        'review_score_outside_1_5' AS check_name,
        COUNT(*) AS issue_count
    FROM dwh.fact_reviews
    WHERE review_score NOT BETWEEN 1 AND 5
       OR review_score IS NULL
)
SELECT
    check_name,
    issue_count,
    CASE
        WHEN issue_count = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM checks
ORDER BY check_name;
