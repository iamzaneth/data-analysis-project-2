-- Analysis group: Logistics Analysis
-- Objective: analyze delivery performance, late delivery risk, delay duration,
-- and operational bottlenecks by month, state, and order status.

-- KPI: Overall late delivery rate
SELECT
    SUM(total_orders) AS total_orders,
    SUM(delivered_orders) AS delivered_orders,
    SUM(late_orders) AS late_orders,
    ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) * 100, 2) AS late_rate_pct,
    ROUND(SUM(avg_delivery_days * delivered_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0), 2) AS avg_delivery_days
FROM {{ ref('mart_logistics') }};

-- Chart: Late delivery rate by month
SELECT
    year,
    month,
    CONCAT(year, '-', LPAD(month::TEXT, 2, '0')) AS year_month,
    SUM(delivered_orders) AS delivered_orders,
    SUM(late_orders) AS late_orders,
    ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) * 100, 2) AS late_rate_pct
FROM {{ ref('mart_logistics') }}
GROUP BY year, month
ORDER BY year, month;

-- Chart: Delivered orders vs late orders by month
SELECT
    year,
    month,
    CONCAT(year, '-', LPAD(month::TEXT, 2, '0')) AS year_month,
    SUM(delivered_orders) AS delivered_orders,
    SUM(late_orders) AS late_orders,
    SUM(delivered_orders) - SUM(late_orders) AS on_time_delivered_orders
FROM {{ ref('mart_logistics') }}
GROUP BY year, month
ORDER BY year, month;

-- Ranking: Late delivery rate by state
SELECT
    customer_state,
    SUM(delivered_orders) AS delivered_orders,
    SUM(late_orders) AS late_orders,
    ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) * 100, 2) AS late_rate_pct,
    ROUND(SUM(avg_delivery_days * delivered_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0), 2) AS avg_delivery_days
FROM {{ ref('mart_logistics') }}
GROUP BY customer_state
HAVING SUM(delivered_orders) >= 100
ORDER BY late_rate_pct DESC, delivered_orders DESC;

-- Chart: Average delivery days by month
SELECT
    year,
    month,
    CONCAT(year, '-', LPAD(month::TEXT, 2, '0')) AS year_month,
    SUM(delivered_orders) AS delivered_orders,
    ROUND(SUM(avg_delivery_days * delivered_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0), 2) AS avg_delivery_days,
    ROUND(SUM(avg_estimated_delivery_days * delivered_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0), 2) AS avg_estimated_delivery_days,
    ROUND(SUM(avg_delay_days * delivered_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0), 2) AS avg_delay_days
FROM {{ ref('mart_logistics') }}
GROUP BY year, month
ORDER BY year, month;

-- Ranking: Average delay days by state
SELECT
    customer_state,
    SUM(delivered_orders) AS delivered_orders,
    SUM(late_orders) AS late_orders,
    ROUND(SUM(avg_delay_days * delivered_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0), 2) AS avg_delay_days,
    ROUND(MAX(max_delay_days), 2) AS max_delay_days
FROM {{ ref('mart_logistics') }}
GROUP BY customer_state
HAVING SUM(delivered_orders) >= 100
ORDER BY avg_delay_days DESC, late_orders DESC;

-- Chart: Order status distribution
SELECT
    order_status,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_orders)::NUMERIC / NULLIF(SUM(SUM(total_orders)) OVER (), 0) * 100, 2) AS order_status_share_pct
FROM {{ ref('mart_logistics') }}
GROUP BY order_status
ORDER BY total_orders DESC;

-- Insight: High revenue states with poor delivery performance
WITH revenue_state AS (
    SELECT
        customer_state,
        SUM(total_item_revenue) AS total_revenue,
        SUM(total_orders) AS sales_orders
    FROM {{ ref('mart_sales') }}
    GROUP BY customer_state
),
logistics_state AS (
    SELECT
        customer_state,
        SUM(delivered_orders) AS delivered_orders,
        SUM(late_orders) AS late_orders,
        ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) * 100, 2) AS late_rate_pct,
        ROUND(SUM(avg_delivery_days * delivered_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0), 2) AS avg_delivery_days
    FROM {{ ref('mart_logistics') }}
    GROUP BY customer_state
)
SELECT
    r.customer_state,
    ROUND(r.total_revenue::NUMERIC, 2) AS total_revenue,
    r.sales_orders,
    l.delivered_orders,
    l.late_orders,
    l.late_rate_pct,
    l.avg_delivery_days
FROM revenue_state r
JOIN logistics_state l
    ON l.customer_state = r.customer_state
WHERE r.total_revenue >= 100000
ORDER BY l.late_rate_pct DESC, r.total_revenue DESC;

-- Ranking: Top cities with late delivery risk from geolocation mart
SELECT
    customer_state,
    customer_city,
    SUM(total_orders) AS total_orders,
    SUM(delivered_orders) AS delivered_orders,
    SUM(late_orders) AS late_orders,
    ROUND(SUM(late_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0) * 100, 2) AS late_rate_pct,
    ROUND(SUM(avg_delivery_days * delivered_orders)::NUMERIC / NULLIF(SUM(delivered_orders), 0), 2) AS avg_delivery_days
FROM {{ ref('mart_geolocation') }}
GROUP BY customer_state, customer_city
HAVING SUM(delivered_orders) >= 50
ORDER BY late_rate_pct DESC, delivered_orders DESC
LIMIT 30;