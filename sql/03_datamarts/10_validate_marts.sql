\echo '1. Mart row count by table'

SELECT 'mart_sales' AS table_name, COUNT(*) AS row_count FROM mart.mart_sales
UNION ALL
SELECT 'mart_logistics' AS table_name, COUNT(*) AS row_count FROM mart.mart_logistics
UNION ALL
SELECT 'mart_customer_satisfaction' AS table_name, COUNT(*) AS row_count FROM mart.mart_customer_satisfaction
UNION ALL
SELECT 'mart_seller_performance' AS table_name, COUNT(*) AS row_count FROM mart.mart_seller_performance
UNION ALL
SELECT 'mart_product_category' AS table_name, COUNT(*) AS row_count FROM mart.mart_product_category
UNION ALL
SELECT 'mart_payment' AS table_name, COUNT(*) AS row_count FROM mart.mart_payment
UNION ALL
SELECT 'mart_geolocation' AS table_name, COUNT(*) AS row_count FROM mart.mart_geolocation
ORDER BY table_name;

\echo '2. Empty mart tables'

WITH table_counts AS (
    SELECT 'mart_sales' AS table_name, COUNT(*) AS row_count FROM mart.mart_sales
    UNION ALL SELECT 'mart_logistics', COUNT(*) FROM mart.mart_logistics
    UNION ALL SELECT 'mart_customer_satisfaction', COUNT(*) FROM mart.mart_customer_satisfaction
    UNION ALL SELECT 'mart_seller_performance', COUNT(*) FROM mart.mart_seller_performance
    UNION ALL SELECT 'mart_product_category', COUNT(*) FROM mart.mart_product_category
    UNION ALL SELECT 'mart_payment', COUNT(*) FROM mart.mart_payment
    UNION ALL SELECT 'mart_geolocation', COUNT(*) FROM mart.mart_geolocation
)
SELECT table_name, row_count
FROM table_counts
WHERE row_count = 0
ORDER BY table_name;

\echo '3. Null grain fields'

SELECT 'mart_sales' AS table_name, COUNT(*) AS issue_count
FROM mart.mart_sales
WHERE year IS NULL OR month IS NULL OR product_category_name_english IS NULL OR customer_state IS NULL
UNION ALL
SELECT 'mart_logistics', COUNT(*)
FROM mart.mart_logistics
WHERE year IS NULL OR month IS NULL OR customer_state IS NULL OR order_status IS NULL
UNION ALL
SELECT 'mart_customer_satisfaction', COUNT(*)
FROM mart.mart_customer_satisfaction
WHERE year IS NULL OR month IS NULL OR customer_state IS NULL OR is_late IS NULL
UNION ALL
SELECT 'mart_seller_performance', COUNT(*)
FROM mart.mart_seller_performance
WHERE year IS NULL OR month IS NULL OR seller_id IS NULL OR product_category_name_english IS NULL
UNION ALL
SELECT 'mart_product_category', COUNT(*)
FROM mart.mart_product_category
WHERE year IS NULL OR month IS NULL OR product_category_name_english IS NULL
UNION ALL
SELECT 'mart_payment', COUNT(*)
FROM mart.mart_payment
WHERE year IS NULL OR month IS NULL OR payment_type IS NULL OR customer_state IS NULL
UNION ALL
SELECT 'mart_geolocation', COUNT(*)
FROM mart.mart_geolocation
WHERE year IS NULL OR month IS NULL OR customer_state IS NULL OR customer_city IS NULL
ORDER BY table_name;

\echo '4. Negative value checks'

SELECT 'mart_sales_money' AS check_name, COUNT(*) AS issue_count
FROM mart.mart_sales
WHERE gross_merchandise_value < 0 OR total_freight_value < 0 OR total_item_revenue < 0
UNION ALL
SELECT 'mart_product_category_money', COUNT(*)
FROM mart.mart_product_category
WHERE gross_merchandise_value < 0 OR total_freight_value < 0 OR total_revenue < 0
UNION ALL
SELECT 'mart_payment_value', COUNT(*)
FROM mart.mart_payment
WHERE total_payment_value < 0 OR avg_payment_value < 0
UNION ALL
SELECT 'mart_geolocation_money', COUNT(*)
FROM mart.mart_geolocation
WHERE total_revenue < 0 OR gross_merchandise_value < 0 OR total_freight_value < 0 OR total_payment_value < 0
ORDER BY check_name;

\echo '5. Revenue and payment reconciliation'

WITH checks AS (
    SELECT
        'mart_sales_total_item_revenue_vs_dwh' AS check_name,
        ROUND((SELECT SUM(total_item_revenue) FROM mart.mart_sales), 2) AS mart_total,
        ROUND((SELECT SUM(total_item_value) FROM dwh.fact_order_item_sales), 2) AS dwh_total
    UNION ALL
    SELECT
        'mart_product_category_total_revenue_vs_dwh',
        ROUND((SELECT SUM(total_revenue) FROM mart.mart_product_category), 2),
        ROUND((SELECT SUM(total_item_value) FROM dwh.fact_order_item_sales), 2)
    UNION ALL
    SELECT
        'mart_payment_total_payment_value_vs_dwh',
        ROUND((SELECT SUM(total_payment_value) FROM mart.mart_payment), 2),
        ROUND((SELECT SUM(payment_value) FROM dwh.fact_payments), 2)
    UNION ALL
    SELECT
        'mart_geolocation_total_revenue_vs_dwh',
        ROUND((SELECT SUM(total_revenue) FROM mart.mart_geolocation), 2),
        ROUND((SELECT SUM(total_item_value) FROM dwh.fact_order_item_sales), 2)
    UNION ALL
    SELECT
        'mart_geolocation_total_payment_value_vs_dwh',
        ROUND((SELECT SUM(total_payment_value) FROM mart.mart_geolocation), 2),
        ROUND((SELECT SUM(payment_value) FROM dwh.fact_payments), 2)
)
SELECT
    check_name,
    mart_total,
    dwh_total,
    ROUND(mart_total - dwh_total, 2) AS difference,
    CASE
        WHEN ABS(COALESCE(mart_total, 0) - COALESCE(dwh_total, 0)) <= 0.01 THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM checks
ORDER BY check_name;

\echo '6. Percentage rate bounds'

SELECT 'mart_sales.freight_to_gmv_pct' AS check_name, COUNT(*) AS issue_count
FROM mart.mart_sales
WHERE freight_to_gmv_pct < 0
UNION ALL
SELECT 'mart_logistics.late_rate_pct', COUNT(*)
FROM mart.mart_logistics
WHERE late_rate_pct < 0 OR late_rate_pct > 100
UNION ALL
SELECT 'mart_customer_satisfaction.low_review_rate_pct', COUNT(*)
FROM mart.mart_customer_satisfaction
WHERE low_review_rate_pct < 0 OR low_review_rate_pct > 100
UNION ALL
SELECT 'mart_customer_satisfaction.high_review_rate_pct', COUNT(*)
FROM mart.mart_customer_satisfaction
WHERE high_review_rate_pct < 0 OR high_review_rate_pct > 100
UNION ALL
SELECT 'mart_customer_satisfaction.comment_message_rate_pct', COUNT(*)
FROM mart.mart_customer_satisfaction
WHERE comment_message_rate_pct < 0 OR comment_message_rate_pct > 100
UNION ALL
SELECT 'mart_seller_performance.low_review_rate_pct', COUNT(*)
FROM mart.mart_seller_performance
WHERE low_review_rate_pct < 0 OR low_review_rate_pct > 100
UNION ALL
SELECT 'mart_seller_performance.late_rate_pct', COUNT(*)
FROM mart.mart_seller_performance
WHERE late_rate_pct < 0 OR late_rate_pct > 100
UNION ALL
SELECT 'mart_product_category.low_review_rate_pct', COUNT(*)
FROM mart.mart_product_category
WHERE low_review_rate_pct < 0 OR low_review_rate_pct > 100
UNION ALL
SELECT 'mart_payment.installment_order_rate_pct', COUNT(*)
FROM mart.mart_payment
WHERE installment_order_rate_pct < 0 OR installment_order_rate_pct > 100
UNION ALL
SELECT 'mart_geolocation.late_rate_pct', COUNT(*)
FROM mart.mart_geolocation
WHERE late_rate_pct < 0 OR late_rate_pct > 100
UNION ALL
SELECT 'mart_geolocation.low_review_rate_pct', COUNT(*)
FROM mart.mart_geolocation
WHERE low_review_rate_pct < 0 OR low_review_rate_pct > 100
ORDER BY check_name;

\echo '7. Mart validation summary'

WITH empty_tables AS (
    SELECT COUNT(*) AS issue_count
    FROM (
        SELECT COUNT(*) AS row_count FROM mart.mart_sales
        UNION ALL SELECT COUNT(*) FROM mart.mart_logistics
        UNION ALL SELECT COUNT(*) FROM mart.mart_customer_satisfaction
        UNION ALL SELECT COUNT(*) FROM mart.mart_seller_performance
        UNION ALL SELECT COUNT(*) FROM mart.mart_product_category
        UNION ALL SELECT COUNT(*) FROM mart.mart_payment
        UNION ALL SELECT COUNT(*) FROM mart.mart_geolocation
    ) table_counts
    WHERE row_count = 0
),
null_grain_fields AS (
    SELECT COUNT(*) AS issue_count FROM mart.mart_sales
    WHERE year IS NULL OR month IS NULL OR product_category_name_english IS NULL OR customer_state IS NULL
    UNION ALL SELECT COUNT(*) FROM mart.mart_logistics
    WHERE year IS NULL OR month IS NULL OR customer_state IS NULL OR order_status IS NULL
    UNION ALL SELECT COUNT(*) FROM mart.mart_customer_satisfaction
    WHERE year IS NULL OR month IS NULL OR customer_state IS NULL OR is_late IS NULL
    UNION ALL SELECT COUNT(*) FROM mart.mart_seller_performance
    WHERE year IS NULL OR month IS NULL OR seller_id IS NULL OR product_category_name_english IS NULL
    UNION ALL SELECT COUNT(*) FROM mart.mart_product_category
    WHERE year IS NULL OR month IS NULL OR product_category_name_english IS NULL
    UNION ALL SELECT COUNT(*) FROM mart.mart_payment
    WHERE year IS NULL OR month IS NULL OR payment_type IS NULL OR customer_state IS NULL
    UNION ALL SELECT COUNT(*) FROM mart.mart_geolocation
    WHERE year IS NULL OR month IS NULL OR customer_state IS NULL OR customer_city IS NULL
),
negative_values AS (
    SELECT COUNT(*) AS issue_count FROM mart.mart_sales
    WHERE gross_merchandise_value < 0 OR total_freight_value < 0 OR total_item_revenue < 0
    UNION ALL SELECT COUNT(*) FROM mart.mart_product_category
    WHERE gross_merchandise_value < 0 OR total_freight_value < 0 OR total_revenue < 0
    UNION ALL SELECT COUNT(*) FROM mart.mart_payment
    WHERE total_payment_value < 0 OR avg_payment_value < 0
    UNION ALL SELECT COUNT(*) FROM mart.mart_geolocation
    WHERE total_revenue < 0 OR gross_merchandise_value < 0 OR total_freight_value < 0 OR total_payment_value < 0
),
reconciliation AS (
    SELECT
        CASE
            WHEN ABS(COALESCE((SELECT ROUND(SUM(total_item_revenue), 2) FROM mart.mart_sales), 0)
                   - COALESCE((SELECT ROUND(SUM(total_item_value), 2) FROM dwh.fact_order_item_sales), 0)) <= 0.01 THEN 0
            ELSE 1
        END AS issue_count
    UNION ALL
    SELECT
        CASE
            WHEN ABS(COALESCE((SELECT ROUND(SUM(total_revenue), 2) FROM mart.mart_product_category), 0)
                   - COALESCE((SELECT ROUND(SUM(total_item_value), 2) FROM dwh.fact_order_item_sales), 0)) <= 0.01 THEN 0
            ELSE 1
        END
    UNION ALL
    SELECT
        CASE
            WHEN ABS(COALESCE((SELECT ROUND(SUM(total_payment_value), 2) FROM mart.mart_payment), 0)
                   - COALESCE((SELECT ROUND(SUM(payment_value), 2) FROM dwh.fact_payments), 0)) <= 0.01 THEN 0
            ELSE 1
        END
    UNION ALL
    SELECT
        CASE
            WHEN ABS(COALESCE((SELECT ROUND(SUM(total_revenue), 2) FROM mart.mart_geolocation), 0)
                   - COALESCE((SELECT ROUND(SUM(total_item_value), 2) FROM dwh.fact_order_item_sales), 0)) <= 0.01 THEN 0
            ELSE 1
        END
    UNION ALL
    SELECT
        CASE
            WHEN ABS(COALESCE((SELECT ROUND(SUM(total_payment_value), 2) FROM mart.mart_geolocation), 0)
                   - COALESCE((SELECT ROUND(SUM(payment_value), 2) FROM dwh.fact_payments), 0)) <= 0.01 THEN 0
            ELSE 1
        END
),
rate_bounds AS (
    SELECT COUNT(*) AS issue_count FROM mart.mart_sales WHERE freight_to_gmv_pct < 0
    UNION ALL SELECT COUNT(*) FROM mart.mart_logistics WHERE late_rate_pct < 0 OR late_rate_pct > 100
    UNION ALL SELECT COUNT(*) FROM mart.mart_customer_satisfaction WHERE low_review_rate_pct < 0 OR low_review_rate_pct > 100
    UNION ALL SELECT COUNT(*) FROM mart.mart_customer_satisfaction WHERE high_review_rate_pct < 0 OR high_review_rate_pct > 100
    UNION ALL SELECT COUNT(*) FROM mart.mart_customer_satisfaction WHERE comment_message_rate_pct < 0 OR comment_message_rate_pct > 100
    UNION ALL SELECT COUNT(*) FROM mart.mart_seller_performance WHERE low_review_rate_pct < 0 OR low_review_rate_pct > 100
    UNION ALL SELECT COUNT(*) FROM mart.mart_seller_performance WHERE late_rate_pct < 0 OR late_rate_pct > 100
    UNION ALL SELECT COUNT(*) FROM mart.mart_product_category WHERE low_review_rate_pct < 0 OR low_review_rate_pct > 100
    UNION ALL SELECT COUNT(*) FROM mart.mart_payment WHERE installment_order_rate_pct < 0 OR installment_order_rate_pct > 100
    UNION ALL SELECT COUNT(*) FROM mart.mart_geolocation WHERE late_rate_pct < 0 OR late_rate_pct > 100
    UNION ALL SELECT COUNT(*) FROM mart.mart_geolocation WHERE low_review_rate_pct < 0 OR low_review_rate_pct > 100
),
checks AS (
    SELECT 'empty_tables' AS check_name, issue_count FROM empty_tables
    UNION ALL
    SELECT 'null_grain_fields', COALESCE(SUM(issue_count), 0)::BIGINT FROM null_grain_fields
    UNION ALL
    SELECT 'negative_values', COALESCE(SUM(issue_count), 0)::BIGINT FROM negative_values
    UNION ALL
    SELECT 'reconciliation', COALESCE(SUM(issue_count), 0)::BIGINT FROM reconciliation
    UNION ALL
    SELECT 'rate_bounds', COALESCE(SUM(issue_count), 0)::BIGINT FROM rate_bounds
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
