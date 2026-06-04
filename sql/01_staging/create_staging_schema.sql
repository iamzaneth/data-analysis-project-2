CREATE SCHEMA IF NOT EXISTS staging;

-- Customers table
DROP TABLE IF EXISTS staging.olist_customers;

CREATE TABLE staging.olist_customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);

-- Geolocation table
DROP TABLE IF EXISTS staging.olist_geolocation;

CREATE TABLE staging.olist_geolocation (
    geolocation_zip_code_prefix TEXT,
    geolocation_lat NUMERIC,
    geolocation_lng NUMERIC,
    geolocation_city TEXT,
    geolocation_state TEXT
);

-- Orders table
DROP TABLE IF EXISTS staging.olist_orders;

CREATE TABLE staging.olist_orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

-- Order Items table
DROP TABLE IF EXISTS staging.olist_order_items;

CREATE TABLE staging.olist_order_items (
    order_id TEXT,
    order_item_id INTEGER,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TIMESTAMP,
    price NUMERIC,
    freight_value NUMERIC
);

-- Order Payments table
DROP TABLE IF EXISTS staging.olist_order_payments;

CREATE TABLE staging.olist_order_payments (
    order_id TEXT,
    payment_sequential INTEGER,
    payment_type TEXT,
    payment_installments INTEGER,
    payment_value NUMERIC
);

-- Order Reviews table
DROP TABLE IF EXISTS staging.olist_order_reviews;

CREATE TABLE staging.olist_order_reviews (
    review_id TEXT,
    order_id TEXT,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);

-- Products table
DROP TABLE IF EXISTS staging.olist_products;

CREATE TABLE staging.olist_products (
    product_id TEXT,
    product_category_name TEXT,
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC
);

-- Sellers table
DROP TABLE IF EXISTS staging.olist_sellers;

CREATE TABLE staging.olist_sellers (
    seller_id TEXT,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);

-- Product Category Translation table
DROP TABLE IF EXISTS staging.product_category_name_translation;

CREATE TABLE staging.product_category_name_translation (
    product_category_name TEXT,
    product_category_name_english TEXT
);
