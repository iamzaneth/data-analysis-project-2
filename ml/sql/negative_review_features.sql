WITH sales_by_order AS (
    SELECT
        f.order_id,
        COUNT(*) AS order_item_count,
        COUNT(DISTINCT f.product_key) AS product_count,
        COUNT(DISTINCT f.seller_key) AS seller_count,
        SUM(f.price) AS total_price,
        SUM(f.freight_value) AS total_freight_value,
        AVG(f.price) AS avg_item_price,
        100.0 * SUM(f.freight_value) / NULLIF(SUM(f.price), 0) AS freight_to_price_pct,
        MIN(f.product_key) AS representative_product_key,
        MIN(f.seller_key) AS representative_seller_key
    FROM dwh.fact_order_item_sales f
    GROUP BY f.order_id
),
payments_by_order AS (
    SELECT
        f.order_id,
        SUM(f.payment_value) AS total_payment_value,
        MAX(f.payment_installments) AS max_payment_installments,
        MAX(f.payment_type) AS payment_type
    FROM dwh.fact_payments f
    GROUP BY f.order_id
)
SELECT
    r.review_id,
    r.order_id,
    CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END AS is_negative_review,
    r.review_score,

    COALESCE(delivery.is_late, FALSE) AS is_late,
    delivery.approval_hours,
    delivery.carrier_handoff_days,
    delivery.delivery_days,
    delivery.estimated_delivery_days,
    delivery.delay_days,
    delivery.order_status,

    sales.order_item_count,
    sales.product_count,
    sales.seller_count,
    sales.total_price,
    sales.total_freight_value,
    sales.avg_item_price,
    sales.freight_to_price_pct,

    payments.total_payment_value,
    payments.max_payment_installments,
    payments.payment_type,

    product.product_category_name,
    product.product_name_length,
    product.product_description_length,
    product.product_photos_qty,
    product.product_weight_g,
    product.product_volume_cm3,

    seller.seller_state,
    customer.customer_state,
    date_dim.year,
    date_dim.month
FROM dwh.fact_reviews r
LEFT JOIN dwh.fact_order_delivery delivery
    ON delivery.order_id = r.order_id
LEFT JOIN sales_by_order sales
    ON sales.order_id = r.order_id
LEFT JOIN payments_by_order payments
    ON payments.order_id = r.order_id
LEFT JOIN dwh.dim_product product
    ON product.product_key = sales.representative_product_key
LEFT JOIN dwh.dim_seller seller
    ON seller.seller_key = sales.representative_seller_key
LEFT JOIN dwh.dim_customer customer
    ON customer.customer_key = r.customer_key
LEFT JOIN dwh.dim_date date_dim
    ON date_dim.date_key = r.review_creation_date_key
WHERE r.review_score IS NOT NULL;
