-- Create the DWH schema and reset existing DWH objects.
-- Facts are dropped before dimensions because facts depend on dimension keys.

CREATE SCHEMA IF NOT EXISTS dwh;

DROP TABLE IF EXISTS dwh.fact_reviews CASCADE;
DROP TABLE IF EXISTS dwh.fact_payments CASCADE;
DROP TABLE IF EXISTS dwh.fact_order_delivery CASCADE;
DROP TABLE IF EXISTS dwh.fact_order_item_sales CASCADE;

DROP TABLE IF EXISTS dwh.dim_payment_type CASCADE;
DROP TABLE IF EXISTS dwh.dim_order_status CASCADE;
DROP TABLE IF EXISTS dwh.dim_product CASCADE;
DROP TABLE IF EXISTS dwh.dim_seller CASCADE;
DROP TABLE IF EXISTS dwh.dim_customer CASCADE;
DROP TABLE IF EXISTS dwh.dim_date CASCADE;
