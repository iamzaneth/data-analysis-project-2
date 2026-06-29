-- Optional Power BI insight views.
-- These views do not replace the 7 mart tables. They pre-aggregate cross-domain
-- insight datasets at a safe comparison grain for Power BI visuals.

CREATE OR REPLACE VIEW mart.pbi_category_risk AS
WITH category_metrics AS (
    SELECT
        product_category_name AS product_category,
        SUM(total_orders) AS total_orders,
        SUM(total_revenue) AS total_revenue,
        SUM(total_freight_value) AS total_freight_value,
        SUM(avg_review_score * total_orders)::NUMERIC
            / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0) AS avg_review_score,
        SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100 AS low_review_rate_pct
    FROM mart.mart_product_category
    GROUP BY product_category_name
)
SELECT
    product_category,
    total_orders,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(avg_review_score::NUMERIC, 2) AS avg_review_score,
    ROUND(low_review_rate_pct::NUMERIC, 2) AS low_review_rate_pct,
    ROUND(total_freight_value::NUMERIC / NULLIF(total_revenue, 0) * 100, 2) AS freight_to_revenue_pct,
    ROUND(
        (COALESCE(low_review_rate_pct, 0) * 0.5)
        + (COALESCE(total_freight_value::NUMERIC / NULLIF(total_revenue, 0) * 100, 0) * 0.3)
        + (CASE WHEN total_revenue >= 100000 THEN 20 ELSE 10 END),
        2
    ) AS category_risk_score
FROM category_metrics
WHERE total_orders >= 100;

CREATE OR REPLACE VIEW mart.pbi_seller_risk AS
SELECT
    seller_id,
    seller_state,
    seller_city,
    product_category_name AS product_category,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(
        SUM(avg_review_score * total_orders)::NUMERIC
        / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0),
        2
    ) AS avg_review_score,
    ROUND(SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS low_review_rate_pct,
    ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS late_order_share_pct,
    ROUND(
        (SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100 * 0.5)
        + (SUM(late_orders)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100 * 0.3)
        + (CASE WHEN SUM(total_revenue) >= 10000 THEN 20 ELSE 10 END),
        2
    ) AS seller_quality_risk_score
FROM mart.mart_seller_performance
GROUP BY seller_id, seller_state, seller_city, product_category_name
HAVING SUM(total_orders) >= 20;

CREATE OR REPLACE VIEW mart.pbi_region_market_risk AS
WITH region_metrics AS (
    SELECT
        customer_state,
        customer_city,
        SUM(total_orders) AS total_orders,
        SUM(total_customers) AS total_customers,
        SUM(total_revenue) AS total_revenue,
        SUM(late_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) * 100 AS late_rate_pct,
        SUM(avg_delivery_days * delivered_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) AS avg_delivery_days,
        SUM(avg_review_score * total_orders)::NUMERIC
            / NULLIF(SUM(total_orders) FILTER (WHERE avg_review_score IS NOT NULL), 0) AS avg_review_score,
        SUM(low_review_rate_pct * total_orders)::NUMERIC
            / NULLIF(SUM(total_orders) FILTER (WHERE low_review_rate_pct IS NOT NULL), 0) AS low_review_rate_pct
    FROM mart.mart_geolocation
    GROUP BY customer_state, customer_city
)
SELECT
    customer_state,
    customer_city,
    total_orders,
    total_customers,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(total_revenue::NUMERIC / NULLIF(total_orders, 0), 2) AS avg_order_value,
    ROUND(late_rate_pct::NUMERIC, 2) AS late_rate_pct,
    ROUND(avg_delivery_days::NUMERIC, 2) AS avg_delivery_days,
    ROUND(avg_review_score::NUMERIC, 2) AS avg_review_score,
    ROUND(low_review_rate_pct::NUMERIC, 2) AS low_review_rate_pct,
    ROUND(
        (total_revenue::NUMERIC / 100000)
        - (COALESCE(late_rate_pct, 0) * 0.2)
        - (COALESCE(5 - avg_review_score, 0) * 4),
        2
    ) AS regional_market_score
FROM region_metrics
WHERE total_orders >= 50;

CREATE OR REPLACE VIEW mart.pbi_payment_behavior AS
SELECT
    payment_type,
    SUM(total_orders) AS total_orders,
    SUM(total_customers) AS total_customers,
    ROUND(SUM(total_payment_value)::NUMERIC, 2) AS total_payment_value,
    ROUND(SUM(total_payment_value)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_payment_per_order,
    ROUND(SUM(installment_orders)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS installment_order_rate_pct,
    ROUND(
        SUM(avg_installments * total_payment_records)::NUMERIC / NULLIF(SUM(total_payment_records), 0),
        2
    ) AS avg_installments
FROM mart.mart_payment
GROUP BY payment_type;
