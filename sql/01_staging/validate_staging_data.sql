\echo '1. Row count by staging table'

SELECT 'olist_customers' AS table_name, COUNT(*) AS row_count
FROM staging.olist_customers
UNION ALL
SELECT 'olist_geolocation' AS table_name, COUNT(*) AS row_count
FROM staging.olist_geolocation
UNION ALL
SELECT 'olist_orders' AS table_name, COUNT(*) AS row_count
FROM staging.olist_orders
UNION ALL
SELECT 'olist_order_items' AS table_name, COUNT(*) AS row_count
FROM staging.olist_order_items
UNION ALL
SELECT 'olist_order_payments' AS table_name, COUNT(*) AS row_count
FROM staging.olist_order_payments
UNION ALL
SELECT 'olist_order_reviews' AS table_name, COUNT(*) AS row_count
FROM staging.olist_order_reviews
UNION ALL
SELECT 'olist_products' AS table_name, COUNT(*) AS row_count
FROM staging.olist_products
UNION ALL
SELECT 'olist_sellers' AS table_name, COUNT(*) AS row_count
FROM staging.olist_sellers
UNION ALL
SELECT 'product_category_name_translation' AS table_name, COUNT(*) AS row_count
FROM staging.product_category_name_translation
ORDER BY table_name;

\echo '2. Empty staging tables'

WITH table_counts AS (
    SELECT 'olist_customers' AS table_name, COUNT(*) AS row_count
    FROM staging.olist_customers
    UNION ALL
    SELECT 'olist_geolocation' AS table_name, COUNT(*) AS row_count
    FROM staging.olist_geolocation
    UNION ALL
    SELECT 'olist_orders' AS table_name, COUNT(*) AS row_count
    FROM staging.olist_orders
    UNION ALL
    SELECT 'olist_order_items' AS table_name, COUNT(*) AS row_count
    FROM staging.olist_order_items
    UNION ALL
    SELECT 'olist_order_payments' AS table_name, COUNT(*) AS row_count
    FROM staging.olist_order_payments
    UNION ALL
    SELECT 'olist_order_reviews' AS table_name, COUNT(*) AS row_count
    FROM staging.olist_order_reviews
    UNION ALL
    SELECT 'olist_products' AS table_name, COUNT(*) AS row_count
    FROM staging.olist_products
    UNION ALL
    SELECT 'olist_sellers' AS table_name, COUNT(*) AS row_count
    FROM staging.olist_sellers
    UNION ALL
    SELECT 'product_category_name_translation' AS table_name, COUNT(*) AS row_count
    FROM staging.product_category_name_translation
)
SELECT table_name, row_count
FROM table_counts
WHERE row_count = 0
ORDER BY table_name;

\echo '3. Orders missing customer'

SELECT COUNT(*) AS missing_customer_order_count
FROM staging.olist_orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM staging.olist_customers c
    WHERE c.customer_id = o.customer_id
);

\echo '4. Order items missing product or seller'

SELECT
    COUNT(*) FILTER (
        WHERE NOT EXISTS (
            SELECT 1
            FROM staging.olist_products p
            WHERE p.product_id = oi.product_id
        )
    ) AS missing_product_order_item_count,
    COUNT(*) FILTER (
        WHERE NOT EXISTS (
            SELECT 1
            FROM staging.olist_sellers s
            WHERE s.seller_id = oi.seller_id
        )
    ) AS missing_seller_order_item_count
FROM staging.olist_order_items oi;

\echo '5. Negative price, freight, or payment values'

SELECT
    'olist_order_items.price' AS check_name,
    COUNT(*) AS invalid_count,
    MIN(price) AS min_value
FROM staging.olist_order_items
WHERE price < 0
UNION ALL
SELECT
    'olist_order_items.freight_value' AS check_name,
    COUNT(*) AS invalid_count,
    MIN(freight_value) AS min_value
FROM staging.olist_order_items
WHERE freight_value < 0
UNION ALL
SELECT
    'olist_order_payments.payment_value' AS check_name,
    COUNT(*) AS invalid_count,
    MIN(payment_value) AS min_value
FROM staging.olist_order_payments
WHERE payment_value < 0
ORDER BY check_name;

\echo '6. Review scores outside 1-5'

SELECT
    COUNT(*) AS invalid_review_score_count,
    MIN(review_score) AS min_review_score,
    MAX(review_score) AS max_review_score
FROM staging.olist_order_reviews
WHERE review_score NOT BETWEEN 1 AND 5
   OR review_score IS NULL;

\echo '7. Validation summary'

WITH checks AS (
    SELECT
        'empty_tables' AS check_name,
        COUNT(*) AS issue_count
    FROM (
        SELECT COUNT(*) AS row_count FROM staging.olist_customers
        UNION ALL SELECT COUNT(*) AS row_count FROM staging.olist_geolocation
        UNION ALL SELECT COUNT(*) AS row_count FROM staging.olist_orders
        UNION ALL SELECT COUNT(*) AS row_count FROM staging.olist_order_items
        UNION ALL SELECT COUNT(*) AS row_count FROM staging.olist_order_payments
        UNION ALL SELECT COUNT(*) AS row_count FROM staging.olist_order_reviews
        UNION ALL SELECT COUNT(*) AS row_count FROM staging.olist_products
        UNION ALL SELECT COUNT(*) AS row_count FROM staging.olist_sellers
        UNION ALL SELECT COUNT(*) AS row_count FROM staging.product_category_name_translation
    ) table_counts
    WHERE row_count = 0

    UNION ALL
    SELECT
        'orders_missing_customer' AS check_name,
        COUNT(*) AS issue_count
    FROM staging.olist_orders o
    WHERE NOT EXISTS (
        SELECT 1
        FROM staging.olist_customers c
        WHERE c.customer_id = o.customer_id
    )

    UNION ALL
    SELECT
        'order_items_missing_product' AS check_name,
        COUNT(*) AS issue_count
    FROM staging.olist_order_items oi
    WHERE NOT EXISTS (
        SELECT 1
        FROM staging.olist_products p
        WHERE p.product_id = oi.product_id
    )

    UNION ALL
    SELECT
        'order_items_missing_seller' AS check_name,
        COUNT(*) AS issue_count
    FROM staging.olist_order_items oi
    WHERE NOT EXISTS (
        SELECT 1
        FROM staging.olist_sellers s
        WHERE s.seller_id = oi.seller_id
    )

    UNION ALL
    SELECT
        'negative_price' AS check_name,
        COUNT(*) AS issue_count
    FROM staging.olist_order_items
    WHERE price < 0

    UNION ALL
    SELECT
        'negative_freight_value' AS check_name,
        COUNT(*) AS issue_count
    FROM staging.olist_order_items
    WHERE freight_value < 0

    UNION ALL
    SELECT
        'negative_payment_value' AS check_name,
        COUNT(*) AS issue_count
    FROM staging.olist_order_payments
    WHERE payment_value < 0

    UNION ALL
    SELECT
        'review_score_outside_1_5' AS check_name,
        COUNT(*) AS issue_count
    FROM staging.olist_order_reviews
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
