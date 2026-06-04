-- Create mart schema and reset existing data mart tables.
-- Drop order is safe because current mart tables do not depend on each other.

CREATE SCHEMA IF NOT EXISTS mart;

DROP TABLE IF EXISTS mart.mart_geolocation CASCADE;
DROP TABLE IF EXISTS mart.mart_payment CASCADE;
DROP TABLE IF EXISTS mart.mart_product_category CASCADE;
DROP TABLE IF EXISTS mart.mart_seller_performance CASCADE;
DROP TABLE IF EXISTS mart.mart_customer_satisfaction CASCADE;
DROP TABLE IF EXISTS mart.mart_logistics CASCADE;
DROP TABLE IF EXISTS mart.mart_sales CASCADE;
