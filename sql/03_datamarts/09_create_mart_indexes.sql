-- Indexes for common dashboard filters and joins on mart tables.
-- Keep the set focused to avoid over-indexing aggregate tables.

CREATE INDEX IF NOT EXISTS idx_mart_sales_year_month
    ON mart.mart_sales (year, month);

CREATE INDEX IF NOT EXISTS idx_mart_sales_customer_state
    ON mart.mart_sales (customer_state);

CREATE INDEX IF NOT EXISTS idx_mart_sales_category
    ON mart.mart_sales (product_category_name_english);

CREATE INDEX IF NOT EXISTS idx_mart_logistics_year_month
    ON mart.mart_logistics (year, month);

CREATE INDEX IF NOT EXISTS idx_mart_logistics_customer_state
    ON mart.mart_logistics (customer_state);

CREATE INDEX IF NOT EXISTS idx_mart_logistics_order_status
    ON mart.mart_logistics (order_status);

CREATE INDEX IF NOT EXISTS idx_mart_customer_satisfaction_year_month
    ON mart.mart_customer_satisfaction (year, month);

CREATE INDEX IF NOT EXISTS idx_mart_customer_satisfaction_state_late
    ON mart.mart_customer_satisfaction (customer_state, is_late);

CREATE INDEX IF NOT EXISTS idx_mart_seller_performance_year_month
    ON mart.mart_seller_performance (year, month);

CREATE INDEX IF NOT EXISTS idx_mart_seller_performance_seller_id
    ON mart.mart_seller_performance (seller_id);

CREATE INDEX IF NOT EXISTS idx_mart_seller_performance_seller_state
    ON mart.mart_seller_performance (seller_state);

CREATE INDEX IF NOT EXISTS idx_mart_seller_performance_category
    ON mart.mart_seller_performance (product_category_name_english);

CREATE INDEX IF NOT EXISTS idx_mart_product_category_year_month
    ON mart.mart_product_category (year, month);

CREATE INDEX IF NOT EXISTS idx_mart_product_category_category
    ON mart.mart_product_category (product_category_name_english);

CREATE INDEX IF NOT EXISTS idx_mart_payment_year_month
    ON mart.mart_payment (year, month);

CREATE INDEX IF NOT EXISTS idx_mart_payment_type
    ON mart.mart_payment (payment_type);

CREATE INDEX IF NOT EXISTS idx_mart_payment_customer_state
    ON mart.mart_payment (customer_state);

CREATE INDEX IF NOT EXISTS idx_mart_geolocation_year_month
    ON mart.mart_geolocation (year, month);

CREATE INDEX IF NOT EXISTS idx_mart_geolocation_state_city
    ON mart.mart_geolocation (customer_state, customer_city);
