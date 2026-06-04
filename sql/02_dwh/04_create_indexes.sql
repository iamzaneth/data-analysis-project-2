-- Indexes for common dashboard joins and filters.

CREATE INDEX IF NOT EXISTS idx_dim_date_full_date
    ON dwh.dim_date (full_date);

CREATE INDEX IF NOT EXISTS idx_dim_customer_business_key
    ON dwh.dim_customer (customer_id);

CREATE INDEX IF NOT EXISTS idx_dim_customer_state_city
    ON dwh.dim_customer (customer_state, customer_city);

CREATE INDEX IF NOT EXISTS idx_dim_seller_business_key
    ON dwh.dim_seller (seller_id);

CREATE INDEX IF NOT EXISTS idx_dim_seller_state_city
    ON dwh.dim_seller (seller_state, seller_city);

CREATE INDEX IF NOT EXISTS idx_dim_product_business_key
    ON dwh.dim_product (product_id);

CREATE INDEX IF NOT EXISTS idx_dim_product_category
    ON dwh.dim_product (product_category_name_english, product_category_name);

CREATE INDEX IF NOT EXISTS idx_dim_geolocation_zip_code_prefix
    ON dwh.dim_geolocation (zip_code_prefix);

CREATE INDEX IF NOT EXISTS idx_dim_geolocation_state_city
    ON dwh.dim_geolocation (geolocation_state, geolocation_city);

CREATE INDEX IF NOT EXISTS idx_dim_order_status_business_key
    ON dwh.dim_order_status (order_status);

CREATE INDEX IF NOT EXISTS idx_dim_payment_type_business_key
    ON dwh.dim_payment_type (payment_type);

CREATE INDEX IF NOT EXISTS idx_fact_order_item_sales_order_id
    ON dwh.fact_order_item_sales (order_id);

CREATE INDEX IF NOT EXISTS idx_fact_order_item_sales_customer_key
    ON dwh.fact_order_item_sales (customer_key);

CREATE INDEX IF NOT EXISTS idx_fact_order_item_sales_seller_key
    ON dwh.fact_order_item_sales (seller_key);

CREATE INDEX IF NOT EXISTS idx_fact_order_item_sales_product_key
    ON dwh.fact_order_item_sales (product_key);

CREATE INDEX IF NOT EXISTS idx_fact_order_item_sales_customer_geo_key
    ON dwh.fact_order_item_sales (customer_geolocation_key);

CREATE INDEX IF NOT EXISTS idx_fact_order_item_sales_seller_geo_key
    ON dwh.fact_order_item_sales (seller_geolocation_key);

CREATE INDEX IF NOT EXISTS idx_fact_order_item_sales_status_key
    ON dwh.fact_order_item_sales (order_status_key);

CREATE INDEX IF NOT EXISTS idx_fact_order_item_sales_purchase_date_key
    ON dwh.fact_order_item_sales (purchase_date_key);

CREATE INDEX IF NOT EXISTS idx_fact_order_item_sales_shipping_limit_date_key
    ON dwh.fact_order_item_sales (shipping_limit_date_key);

CREATE INDEX IF NOT EXISTS idx_fact_order_delivery_order_id
    ON dwh.fact_order_delivery (order_id);

CREATE INDEX IF NOT EXISTS idx_fact_order_delivery_customer_key
    ON dwh.fact_order_delivery (customer_key);

CREATE INDEX IF NOT EXISTS idx_fact_order_delivery_customer_geo_key
    ON dwh.fact_order_delivery (customer_geolocation_key);

CREATE INDEX IF NOT EXISTS idx_fact_order_delivery_status_key
    ON dwh.fact_order_delivery (order_status_key);

CREATE INDEX IF NOT EXISTS idx_fact_order_delivery_purchase_date_key
    ON dwh.fact_order_delivery (purchase_date_key);

CREATE INDEX IF NOT EXISTS idx_fact_order_delivery_delivered_customer_date_key
    ON dwh.fact_order_delivery (delivered_customer_date_key);

CREATE INDEX IF NOT EXISTS idx_fact_order_delivery_estimated_date_key
    ON dwh.fact_order_delivery (estimated_delivery_date_key);

CREATE INDEX IF NOT EXISTS idx_fact_order_delivery_is_late
    ON dwh.fact_order_delivery (is_late);

CREATE INDEX IF NOT EXISTS idx_fact_payments_order_id
    ON dwh.fact_payments (order_id);

CREATE INDEX IF NOT EXISTS idx_fact_payments_customer_key
    ON dwh.fact_payments (customer_key);

CREATE INDEX IF NOT EXISTS idx_fact_payments_customer_geo_key
    ON dwh.fact_payments (customer_geolocation_key);

CREATE INDEX IF NOT EXISTS idx_fact_payments_payment_type_key
    ON dwh.fact_payments (payment_type_key);

CREATE INDEX IF NOT EXISTS idx_fact_payments_status_key
    ON dwh.fact_payments (order_status_key);

CREATE INDEX IF NOT EXISTS idx_fact_payments_purchase_date_key
    ON dwh.fact_payments (purchase_date_key);

CREATE INDEX IF NOT EXISTS idx_fact_reviews_order_id
    ON dwh.fact_reviews (order_id);

CREATE INDEX IF NOT EXISTS idx_fact_reviews_customer_key
    ON dwh.fact_reviews (customer_key);

CREATE INDEX IF NOT EXISTS idx_fact_reviews_customer_geo_key
    ON dwh.fact_reviews (customer_geolocation_key);

CREATE INDEX IF NOT EXISTS idx_fact_reviews_status_key
    ON dwh.fact_reviews (order_status_key);

CREATE INDEX IF NOT EXISTS idx_fact_reviews_purchase_date_key
    ON dwh.fact_reviews (purchase_date_key);

CREATE INDEX IF NOT EXISTS idx_fact_reviews_creation_date_key
    ON dwh.fact_reviews (review_creation_date_key);

CREATE INDEX IF NOT EXISTS idx_fact_reviews_score
    ON dwh.fact_reviews (review_score);
