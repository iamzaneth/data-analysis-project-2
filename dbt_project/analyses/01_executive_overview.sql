-- Analysis group: Executive Overview
-- Objective: provide top-level KPI cards and trend widgets for the first dashboard page.

-- KPI: Overall business performance
SELECT
    ROUND(SUM(total_item_revenue)::NUMERIC, 2) AS total_revenue,
    SUM(total_orders) AS total_orders,
    SUM(total_order_items) AS total_items,
    SUM(total_sellers) AS seller_category_state_rows,
    ROUND(SUM(total_freight_value)::NUMERIC, 2) AS total_freight_value,
    ROUND(SUM(total_item_revenue)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_order_value,
    ROUND(100.0 * SUM(total_freight_value)::NUMERIC / NULLIF(SUM(gross_merchandise_value), 0), 2) AS freight_to_gmv_pct
FROM {{ ref('mart_sales') }};

-- KPI: Payment summary
SELECT
    ROUND(SUM(total_payment_value)::NUMERIC, 2) AS total_payment_value,
    SUM(total_payment_records) AS total_payment_records,
    SUM(total_orders) AS payment_orders,
    ROUND(SUM(total_payment_value)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_payment_per_order,
    ROUND(SUM(installment_orders)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS installment_order_rate_pct
FROM {{ ref('mart_payment') }};

-- KPI: Customer satisfaction summary
SELECT
    SUM(total_reviews) AS total_reviews,
    ROUND(SUM(avg_review_score * total_reviews)::NUMERIC / NULLIF(SUM(total_reviews), 0), 2) AS avg_review_score,
    SUM(low_review_count) AS low_review_count,
    ROUND(SUM(low_review_count)::NUMERIC / NULLIF(SUM(total_reviews), 0) * 100, 2) AS low_review_rate_pct,
    ROUND(SUM(comment_message_count)::NUMERIC / NULLIF(SUM(total_reviews), 0) * 100, 2) AS comment_message_rate_pct
FROM {{ ref('mart_customer_satisfaction') }};

-- KPI: Logistics summary
SELECT
    SUM(total_orders) AS total_orders,
    SUM(delivered_orders) AS delivered_orders,
    SUM(late_orders) AS late_orders,
    ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) * 100, 2) AS late_rate_pct,
    ROUND(SUM(avg_delivery_days * delivered_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0), 2) AS avg_delivery_days
FROM {{ ref('mart_logistics') }};

-- Chart: Monthly revenue and orders
SELECT
    year,
    month,
    CONCAT(year, '-', LPAD(month::TEXT, 2, '0')) AS year_month,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_item_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(total_item_revenue)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_order_value
FROM {{ ref('mart_sales') }}
GROUP BY year, month
ORDER BY year, month;

-- Chart: Monthly payment vs revenue reconciliation view
WITH revenue_by_month AS (
    SELECT
        year,
        month,
        SUM(total_item_revenue) AS total_revenue
    FROM {{ ref('mart_sales') }}
    GROUP BY year, month
),
payment_by_month AS (
    SELECT
        year,
        month,
        SUM(total_payment_value) AS total_payment_value
    FROM {{ ref('mart_payment') }}
    GROUP BY year, month
)
SELECT
    COALESCE(r.year, p.year) AS year,
    COALESCE(r.month, p.month) AS month,
    CONCAT(COALESCE(r.year, p.year), '-', LPAD(COALESCE(r.month, p.month)::TEXT, 2, '0')) AS year_month,
    ROUND(COALESCE(r.total_revenue, 0)::NUMERIC, 2) AS total_revenue,
    ROUND(COALESCE(p.total_payment_value, 0)::NUMERIC, 2) AS total_payment_value,
    ROUND((COALESCE(p.total_payment_value, 0) - COALESCE(r.total_revenue, 0))::NUMERIC, 2) AS payment_revenue_gap
FROM revenue_by_month r
FULL OUTER JOIN payment_by_month p
    ON p.year = r.year
   AND p.month = r.month
ORDER BY year, month;

-- Table: KPI summary by year/month
WITH sales AS (
    SELECT
        year,
        month,
        SUM(total_orders) AS total_orders,
        SUM(total_order_items) AS total_items,
        SUM(total_item_revenue) AS total_revenue,
        SUM(total_freight_value) AS total_freight_value
    FROM {{ ref('mart_sales') }}
    GROUP BY year, month
),
logistics AS (
    SELECT
        year,
        month,
        SUM(delivered_orders) AS delivered_orders,
        SUM(late_orders) AS late_orders
    FROM {{ ref('mart_logistics') }}
    GROUP BY year, month
),
reviews AS (
    SELECT
        year,
        month,
        SUM(total_reviews) AS total_reviews,
        SUM(low_review_count) AS low_review_count,
        SUM(avg_review_score * total_reviews) AS weighted_review_score
    FROM {{ ref('mart_customer_satisfaction') }}
    GROUP BY year, month
)
SELECT
    s.year,
    s.month,
    CONCAT(s.year, '-', LPAD(s.month::TEXT, 2, '0')) AS year_month,
    s.total_orders,
    s.total_items,
    ROUND(s.total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND(s.total_revenue::NUMERIC / NULLIF(s.total_orders, 0), 2) AS avg_order_value,
    ROUND(s.total_freight_value::NUMERIC, 2) AS total_freight_value,
    ROUND(l.late_orders::NUMERIC / NULLIF(l.delivered_orders, 0) * 100, 2) AS late_rate_pct,
    ROUND(r.weighted_review_score::NUMERIC / NULLIF(r.total_reviews, 0), 2) AS avg_review_score,
    ROUND(r.low_review_count::NUMERIC / NULLIF(r.total_reviews, 0) * 100, 2) AS low_review_rate_pct
FROM sales s
LEFT JOIN logistics l
    ON l.year = s.year
   AND l.month = s.month
LEFT JOIN reviews r
    ON r.year = s.year
   AND r.month = s.month
ORDER BY s.year, s.month;

-- Chart: Top 10 revenue states for executive regional snapshot
SELECT
    customer_state,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_item_revenue)::NUMERIC, 2) AS total_revenue,
    ROUND(SUM(total_item_revenue)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_order_value
FROM {{ ref('mart_sales') }}
GROUP BY customer_state
ORDER BY total_revenue DESC
LIMIT 10;