TRUNCATE TABLE
    staging.olist_customers,
    staging.olist_geolocation,
    staging.olist_orders,
    staging.olist_order_items,
    staging.olist_order_payments,
    staging.olist_order_reviews,
    staging.olist_products,
    staging.olist_sellers,
    staging.product_category_name_translation;

COPY staging.olist_customers (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
FROM '/data/raw/olist_customers_dataset.csv'
WITH (FORMAT csv, HEADER true);

COPY staging.olist_geolocation (
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
)
FROM '/data/raw/olist_geolocation_dataset.csv'
WITH (FORMAT csv, HEADER true);

COPY staging.olist_orders (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
)
FROM '/data/raw/olist_orders_dataset.csv'
WITH (FORMAT csv, HEADER true);

COPY staging.olist_order_items (
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
)
FROM '/data/raw/olist_order_items_dataset.csv'
WITH (FORMAT csv, HEADER true);

COPY staging.olist_order_payments (
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
FROM '/data/raw/olist_order_payments_dataset.csv'
WITH (FORMAT csv, HEADER true);

COPY staging.olist_order_reviews (
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)
FROM '/data/raw/olist_order_reviews_dataset.csv'
WITH (FORMAT csv, HEADER true);

COPY staging.olist_products (
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
FROM '/data/raw/olist_products_dataset.csv'
WITH (FORMAT csv, HEADER true);

COPY staging.olist_sellers (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
FROM '/data/raw/olist_sellers_dataset.csv'
WITH (FORMAT csv, HEADER true);

COPY staging.product_category_name_translation (
    product_category_name,
    product_category_name_english
)
FROM '/data/raw/product_category_name_translation.csv'
WITH (FORMAT csv, HEADER true);
