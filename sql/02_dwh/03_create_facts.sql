-- Fact grain:
-- fact_order_item_sales: 1 row = 1 product item in 1 order.
-- fact_order_delivery: 1 row = 1 order.
-- fact_payments: 1 row = 1 payment record of 1 order.
-- fact_reviews: 1 row = 1 review of 1 order.

CREATE TABLE IF NOT EXISTS dwh.fact_order_item_sales (
    order_item_sales_key BIGSERIAL PRIMARY KEY,
    order_id TEXT NOT NULL,
    order_item_id INTEGER NOT NULL,
    customer_key BIGINT REFERENCES dwh.dim_customer(customer_key),
    seller_key BIGINT REFERENCES dwh.dim_seller(seller_key),
    product_key BIGINT REFERENCES dwh.dim_product(product_key),
    order_status_key BIGINT REFERENCES dwh.dim_order_status(order_status_key),
    purchase_date_key INTEGER REFERENCES dwh.dim_date(date_key),
    shipping_limit_date_key INTEGER REFERENCES dwh.dim_date(date_key),
    customer_id TEXT,
    seller_id TEXT,
    product_id TEXT,
    order_purchase_timestamp TIMESTAMP,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12, 2),
    freight_value NUMERIC(12, 2),
    total_item_value NUMERIC(12, 2),
    UNIQUE (order_id, order_item_id)
);

CREATE TABLE IF NOT EXISTS dwh.fact_order_delivery (
    order_delivery_key BIGSERIAL PRIMARY KEY,
    order_id TEXT UNIQUE NOT NULL,
    customer_key BIGINT REFERENCES dwh.dim_customer(customer_key),
    order_status_key BIGINT REFERENCES dwh.dim_order_status(order_status_key),
    purchase_date_key INTEGER REFERENCES dwh.dim_date(date_key),
    approved_date_key INTEGER REFERENCES dwh.dim_date(date_key),
    delivered_carrier_date_key INTEGER REFERENCES dwh.dim_date(date_key),
    delivered_customer_date_key INTEGER REFERENCES dwh.dim_date(date_key),
    estimated_delivery_date_key INTEGER REFERENCES dwh.dim_date(date_key),
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    approval_hours NUMERIC(12, 2),
    carrier_handoff_days NUMERIC(12, 2),
    delivery_days NUMERIC(12, 2),
    estimated_delivery_days NUMERIC(12, 2),
    delay_days NUMERIC(12, 2),
    is_late BOOLEAN
);

CREATE TABLE IF NOT EXISTS dwh.fact_payments (
    payment_key BIGSERIAL PRIMARY KEY,
    order_id TEXT NOT NULL,
    payment_sequential INTEGER NOT NULL,
    customer_key BIGINT REFERENCES dwh.dim_customer(customer_key),
    payment_type_key BIGINT REFERENCES dwh.dim_payment_type(payment_type_key),
    order_status_key BIGINT REFERENCES dwh.dim_order_status(order_status_key),
    purchase_date_key INTEGER REFERENCES dwh.dim_date(date_key),
    customer_id TEXT,
    payment_type TEXT,
    payment_installments INTEGER,
    payment_value NUMERIC(12, 2),
    UNIQUE (order_id, payment_sequential)
);

CREATE TABLE IF NOT EXISTS dwh.fact_reviews (
    review_key BIGSERIAL PRIMARY KEY,
    review_id TEXT NOT NULL,
    order_id TEXT NOT NULL,
    customer_key BIGINT REFERENCES dwh.dim_customer(customer_key),
    order_status_key BIGINT REFERENCES dwh.dim_order_status(order_status_key),
    purchase_date_key INTEGER REFERENCES dwh.dim_date(date_key),
    review_creation_date_key INTEGER REFERENCES dwh.dim_date(date_key),
    review_answer_date_key INTEGER REFERENCES dwh.dim_date(date_key),
    customer_id TEXT,
    review_score INTEGER,
    has_comment_title BOOLEAN,
    has_comment_message BOOLEAN,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    review_response_days NUMERIC(12, 2),
    UNIQUE (review_id, order_id)
);

TRUNCATE TABLE
    dwh.fact_reviews,
    dwh.fact_payments,
    dwh.fact_order_delivery,
    dwh.fact_order_item_sales
RESTART IDENTITY;

INSERT INTO dwh.fact_order_item_sales (
    order_id,
    order_item_id,
    customer_key,
    seller_key,
    product_key,
    order_status_key,
    purchase_date_key,
    shipping_limit_date_key,
    customer_id,
    seller_id,
    product_id,
    order_purchase_timestamp,
    shipping_limit_date,
    price,
    freight_value,
    total_item_value
)
SELECT
    oi.order_id,
    oi.order_item_id,
    c.customer_key,
    s.seller_key,
    p.product_key,
    os.order_status_key,
    purchase_date.date_key AS purchase_date_key,
    shipping_limit_date.date_key AS shipping_limit_date_key,
    o.customer_id,
    oi.seller_id,
    oi.product_id,
    o.order_purchase_timestamp,
    oi.shipping_limit_date,
    oi.price,
    oi.freight_value,
    oi.price + oi.freight_value AS total_item_value
FROM staging.olist_order_items oi
LEFT JOIN staging.olist_orders o
    ON o.order_id = oi.order_id
LEFT JOIN dwh.dim_customer c
    ON c.customer_id = o.customer_id
LEFT JOIN dwh.dim_seller s
    ON s.seller_id = oi.seller_id
LEFT JOIN dwh.dim_product p
    ON p.product_id = oi.product_id
LEFT JOIN dwh.dim_order_status os
    ON os.order_status = o.order_status
LEFT JOIN dwh.dim_date purchase_date
    ON purchase_date.full_date = o.order_purchase_timestamp::DATE
LEFT JOIN dwh.dim_date shipping_limit_date
    ON shipping_limit_date.full_date = oi.shipping_limit_date::DATE
WHERE oi.order_id IS NOT NULL
  AND oi.order_item_id IS NOT NULL;

INSERT INTO dwh.fact_order_delivery (
    order_id,
    customer_key,
    order_status_key,
    purchase_date_key,
    approved_date_key,
    delivered_carrier_date_key,
    delivered_customer_date_key,
    estimated_delivery_date_key,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    approval_hours,
    carrier_handoff_days,
    delivery_days,
    estimated_delivery_days,
    delay_days,
    is_late
)
SELECT
    o.order_id,
    c.customer_key,
    os.order_status_key,
    purchase_date.date_key AS purchase_date_key,
    approved_date.date_key AS approved_date_key,
    carrier_date.date_key AS delivered_carrier_date_key,
    customer_delivery_date.date_key AS delivered_customer_date_key,
    estimated_date.date_key AS estimated_delivery_date_key,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    CASE
        WHEN o.order_purchase_timestamp IS NOT NULL
         AND o.order_approved_at IS NOT NULL
        THEN ROUND((EXTRACT(EPOCH FROM (o.order_approved_at - o.order_purchase_timestamp)) / 3600.0)::NUMERIC, 2)
    END AS approval_hours,
    CASE
        WHEN o.order_purchase_timestamp IS NOT NULL
         AND o.order_delivered_carrier_date IS NOT NULL
        THEN ROUND((EXTRACT(EPOCH FROM (o.order_delivered_carrier_date - o.order_purchase_timestamp)) / 86400.0)::NUMERIC, 2)
    END AS carrier_handoff_days,
    CASE
        WHEN o.order_purchase_timestamp IS NOT NULL
         AND o.order_delivered_customer_date IS NOT NULL
        THEN ROUND((EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400.0)::NUMERIC, 2)
    END AS delivery_days,
    CASE
        WHEN o.order_purchase_timestamp IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN ROUND((EXTRACT(EPOCH FROM (o.order_estimated_delivery_date - o.order_purchase_timestamp)) / 86400.0)::NUMERIC, 2)
    END AS estimated_delivery_days,
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN ROUND((EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400.0)::NUMERIC, 2)
    END AS delay_days,
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN o.order_delivered_customer_date > o.order_estimated_delivery_date
    END AS is_late
FROM staging.olist_orders o
LEFT JOIN dwh.dim_customer c
    ON c.customer_id = o.customer_id
LEFT JOIN dwh.dim_order_status os
    ON os.order_status = o.order_status
LEFT JOIN dwh.dim_date purchase_date
    ON purchase_date.full_date = o.order_purchase_timestamp::DATE
LEFT JOIN dwh.dim_date approved_date
    ON approved_date.full_date = o.order_approved_at::DATE
LEFT JOIN dwh.dim_date carrier_date
    ON carrier_date.full_date = o.order_delivered_carrier_date::DATE
LEFT JOIN dwh.dim_date customer_delivery_date
    ON customer_delivery_date.full_date = o.order_delivered_customer_date::DATE
LEFT JOIN dwh.dim_date estimated_date
    ON estimated_date.full_date = o.order_estimated_delivery_date::DATE
WHERE o.order_id IS NOT NULL;

INSERT INTO dwh.fact_payments (
    order_id,
    payment_sequential,
    customer_key,
    payment_type_key,
    order_status_key,
    purchase_date_key,
    customer_id,
    payment_type,
    payment_installments,
    payment_value
)
SELECT
    op.order_id,
    op.payment_sequential,
    c.customer_key,
    pt.payment_type_key,
    os.order_status_key,
    purchase_date.date_key AS purchase_date_key,
    o.customer_id,
    op.payment_type,
    op.payment_installments,
    op.payment_value
FROM staging.olist_order_payments op
LEFT JOIN staging.olist_orders o
    ON o.order_id = op.order_id
LEFT JOIN dwh.dim_customer c
    ON c.customer_id = o.customer_id
LEFT JOIN dwh.dim_payment_type pt
    ON pt.payment_type = op.payment_type
LEFT JOIN dwh.dim_order_status os
    ON os.order_status = o.order_status
LEFT JOIN dwh.dim_date purchase_date
    ON purchase_date.full_date = o.order_purchase_timestamp::DATE
WHERE op.order_id IS NOT NULL
  AND op.payment_sequential IS NOT NULL;

INSERT INTO dwh.fact_reviews (
    review_id,
    order_id,
    customer_key,
    order_status_key,
    purchase_date_key,
    review_creation_date_key,
    review_answer_date_key,
    customer_id,
    review_score,
    has_comment_title,
    has_comment_message,
    review_creation_date,
    review_answer_timestamp,
    review_response_days
)
SELECT
    r.review_id,
    r.order_id,
    c.customer_key,
    os.order_status_key,
    purchase_date.date_key AS purchase_date_key,
    review_creation_date.date_key AS review_creation_date_key,
    review_answer_date.date_key AS review_answer_date_key,
    o.customer_id,
    r.review_score,
    NULLIF(BTRIM(r.review_comment_title), '') IS NOT NULL AS has_comment_title,
    NULLIF(BTRIM(r.review_comment_message), '') IS NOT NULL AS has_comment_message,
    r.review_creation_date,
    r.review_answer_timestamp,
    CASE
        WHEN r.review_creation_date IS NOT NULL
         AND r.review_answer_timestamp IS NOT NULL
        THEN ROUND((EXTRACT(EPOCH FROM (r.review_answer_timestamp - r.review_creation_date)) / 86400.0)::NUMERIC, 2)
    END AS review_response_days
FROM staging.olist_order_reviews r
LEFT JOIN staging.olist_orders o
    ON o.order_id = r.order_id
LEFT JOIN dwh.dim_customer c
    ON c.customer_id = o.customer_id
LEFT JOIN dwh.dim_order_status os
    ON os.order_status = o.order_status
LEFT JOIN dwh.dim_date purchase_date
    ON purchase_date.full_date = o.order_purchase_timestamp::DATE
LEFT JOIN dwh.dim_date review_creation_date
    ON review_creation_date.full_date = r.review_creation_date::DATE
LEFT JOIN dwh.dim_date review_answer_date
    ON review_answer_date.full_date = r.review_answer_timestamp::DATE
WHERE r.review_id IS NOT NULL
  AND r.order_id IS NOT NULL;
