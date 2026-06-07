-- Dimensions for the Olist analytical DWH.
-- dim_date is a role-playing dimension and can be joined by many date keys.

CREATE TABLE IF NOT EXISTS dwh.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE UNIQUE NOT NULL,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name TEXT NOT NULL,
    day INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name TEXT NOT NULL,
    is_weekend BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS dwh.dim_customer (
    customer_key BIGSERIAL PRIMARY KEY,
    customer_id TEXT UNIQUE NOT NULL,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);

CREATE TABLE IF NOT EXISTS dwh.dim_seller (
    seller_key BIGSERIAL PRIMARY KEY,
    seller_id TEXT UNIQUE NOT NULL,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);

CREATE TABLE IF NOT EXISTS dwh.dim_product (
    product_key BIGSERIAL PRIMARY KEY,
    product_id TEXT UNIQUE NOT NULL,
    product_category_name TEXT,
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC,
    product_volume_cm3 NUMERIC
);

ALTER TABLE dwh.dim_product
    DROP COLUMN IF EXISTS product_category_name_english;

CREATE TABLE IF NOT EXISTS dwh.dim_geolocation (
    geolocation_key BIGSERIAL PRIMARY KEY,
    zip_code_prefix TEXT UNIQUE NOT NULL,
    geolocation_city TEXT,
    geolocation_state TEXT,
    geolocation_lat NUMERIC(12, 8),
    geolocation_lng NUMERIC(12, 8),
    source_record_count INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS dwh.dim_order_status (
    order_status_key BIGSERIAL PRIMARY KEY,
    order_status TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS dwh.dim_payment_type (
    payment_type_key BIGSERIAL PRIMARY KEY,
    payment_type TEXT UNIQUE NOT NULL
);

WITH raw_dates AS (
    SELECT order_purchase_timestamp::DATE AS full_date
    FROM staging.olist_orders
    WHERE order_purchase_timestamp IS NOT NULL
    UNION
    SELECT order_approved_at::DATE AS full_date
    FROM staging.olist_orders
    WHERE order_approved_at IS NOT NULL
    UNION
    SELECT order_delivered_carrier_date::DATE AS full_date
    FROM staging.olist_orders
    WHERE order_delivered_carrier_date IS NOT NULL
    UNION
    SELECT order_delivered_customer_date::DATE AS full_date
    FROM staging.olist_orders
    WHERE order_delivered_customer_date IS NOT NULL
    UNION
    SELECT order_estimated_delivery_date::DATE AS full_date
    FROM staging.olist_orders
    WHERE order_estimated_delivery_date IS NOT NULL
    UNION
    SELECT shipping_limit_date::DATE AS full_date
    FROM staging.olist_order_items
    WHERE shipping_limit_date IS NOT NULL
    UNION
    SELECT review_creation_date::DATE AS full_date
    FROM staging.olist_order_reviews
    WHERE review_creation_date IS NOT NULL
    UNION
    SELECT review_answer_timestamp::DATE AS full_date
    FROM staging.olist_order_reviews
    WHERE review_answer_timestamp IS NOT NULL
),
date_bounds AS (
    SELECT
        MIN(full_date) AS min_date,
        MAX(full_date) AS max_date
    FROM raw_dates
)
INSERT INTO dwh.dim_date (
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    day,
    day_of_week,
    day_name,
    is_weekend
)
SELECT
    TO_CHAR(date_value, 'YYYYMMDD')::INTEGER AS date_key,
    date_value::DATE AS full_date,
    EXTRACT(YEAR FROM date_value)::INTEGER AS year,
    EXTRACT(QUARTER FROM date_value)::INTEGER AS quarter,
    EXTRACT(MONTH FROM date_value)::INTEGER AS month,
    TO_CHAR(date_value, 'FMMonth') AS month_name,
    EXTRACT(DAY FROM date_value)::INTEGER AS day,
    EXTRACT(ISODOW FROM date_value)::INTEGER AS day_of_week,
    TO_CHAR(date_value, 'FMDay') AS day_name,
    EXTRACT(ISODOW FROM date_value)::INTEGER IN (6, 7) AS is_weekend
FROM date_bounds
CROSS JOIN LATERAL generate_series(min_date, max_date, INTERVAL '1 day') AS d(date_value)
WHERE min_date IS NOT NULL
  AND max_date IS NOT NULL
ON CONFLICT (date_key) DO UPDATE SET
    full_date = EXCLUDED.full_date,
    year = EXCLUDED.year,
    quarter = EXCLUDED.quarter,
    month = EXCLUDED.month,
    month_name = EXCLUDED.month_name,
    day = EXCLUDED.day,
    day_of_week = EXCLUDED.day_of_week,
    day_name = EXCLUDED.day_name,
    is_weekend = EXCLUDED.is_weekend;

INSERT INTO dwh.dim_customer (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT DISTINCT ON (customer_id)
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM staging.olist_customers
WHERE customer_id IS NOT NULL
ORDER BY customer_id
ON CONFLICT (customer_id) DO UPDATE SET
    customer_unique_id = EXCLUDED.customer_unique_id,
    customer_zip_code_prefix = EXCLUDED.customer_zip_code_prefix,
    customer_city = EXCLUDED.customer_city,
    customer_state = EXCLUDED.customer_state;

INSERT INTO dwh.dim_seller (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT DISTINCT ON (seller_id)
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM staging.olist_sellers
WHERE seller_id IS NOT NULL
ORDER BY seller_id
ON CONFLICT (seller_id) DO UPDATE SET
    seller_zip_code_prefix = EXCLUDED.seller_zip_code_prefix,
    seller_city = EXCLUDED.seller_city,
    seller_state = EXCLUDED.seller_state;

INSERT INTO dwh.dim_product (
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    product_volume_cm3
)
SELECT DISTINCT ON (p.product_id)
    p.product_id,
    COALESCE(t.product_category_name_english, 'Unknown') AS product_category_name,
    p.product_name_lenght AS product_name_length,
    p.product_description_lenght AS product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    p.product_length_cm * p.product_height_cm * p.product_width_cm AS product_volume_cm3
FROM staging.olist_products p
LEFT JOIN staging.product_category_name_translation t
    ON t.product_category_name = p.product_category_name
WHERE p.product_id IS NOT NULL
ORDER BY p.product_id
ON CONFLICT (product_id) DO UPDATE SET
    product_category_name = EXCLUDED.product_category_name,
    product_name_length = EXCLUDED.product_name_length,
    product_description_length = EXCLUDED.product_description_length,
    product_photos_qty = EXCLUDED.product_photos_qty,
    product_weight_g = EXCLUDED.product_weight_g,
    product_length_cm = EXCLUDED.product_length_cm,
    product_height_cm = EXCLUDED.product_height_cm,
    product_width_cm = EXCLUDED.product_width_cm,
    product_volume_cm3 = EXCLUDED.product_volume_cm3;

WITH geo_aggregates AS (
    SELECT
        geolocation_zip_code_prefix AS zip_code_prefix,
        ROUND(AVG(geolocation_lat)::NUMERIC, 8) AS geolocation_lat,
        ROUND(AVG(geolocation_lng)::NUMERIC, 8) AS geolocation_lng,
        COUNT(*)::INTEGER AS source_record_count
    FROM staging.olist_geolocation
    WHERE geolocation_zip_code_prefix IS NOT NULL
    GROUP BY geolocation_zip_code_prefix
),
geo_city_state_ranked AS (
    SELECT
        geolocation_zip_code_prefix AS zip_code_prefix,
        geolocation_city,
        geolocation_state,
        ROW_NUMBER() OVER (
            PARTITION BY geolocation_zip_code_prefix
            ORDER BY COUNT(*) DESC, geolocation_state, geolocation_city
        ) AS location_rank
    FROM staging.olist_geolocation
    WHERE geolocation_zip_code_prefix IS NOT NULL
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state
)
INSERT INTO dwh.dim_geolocation (
    zip_code_prefix,
    geolocation_city,
    geolocation_state,
    geolocation_lat,
    geolocation_lng,
    source_record_count
)
SELECT
    a.zip_code_prefix,
    r.geolocation_city,
    r.geolocation_state,
    a.geolocation_lat,
    a.geolocation_lng,
    a.source_record_count
FROM geo_aggregates a
LEFT JOIN geo_city_state_ranked r
    ON r.zip_code_prefix = a.zip_code_prefix
   AND r.location_rank = 1
ON CONFLICT (zip_code_prefix) DO UPDATE SET
    geolocation_city = EXCLUDED.geolocation_city,
    geolocation_state = EXCLUDED.geolocation_state,
    geolocation_lat = EXCLUDED.geolocation_lat,
    geolocation_lng = EXCLUDED.geolocation_lng,
    source_record_count = EXCLUDED.source_record_count;

INSERT INTO dwh.dim_order_status (order_status)
SELECT DISTINCT order_status
FROM staging.olist_orders
WHERE order_status IS NOT NULL
ON CONFLICT (order_status) DO NOTHING;

INSERT INTO dwh.dim_payment_type (payment_type)
SELECT DISTINCT payment_type
FROM staging.olist_order_payments
WHERE payment_type IS NOT NULL
ON CONFLICT (payment_type) DO NOTHING;
