-- Analysis group: Payment Analysis
-- Objective: analyze payment value, payment method mix, installment behavior,
-- and regional differences in payment behavior.

-- KPI: Payment value by payment type
SELECT
    payment_type,
    SUM(total_orders) AS total_orders,
    SUM(total_payment_records) AS total_payment_records,
    ROUND(SUM(total_payment_value)::NUMERIC, 2) AS total_payment_value,
    ROUND(SUM(total_payment_value)::NUMERIC / NULLIF(SUM(total_payment_records), 0), 2) AS avg_payment_value,
    ROUND(SUM(avg_installments * total_payment_records)::NUMERIC / NULLIF(SUM(total_payment_records), 0), 2) AS avg_installments
FROM {{ ref('mart_payment') }}
GROUP BY payment_type
ORDER BY total_payment_value DESC;

-- Chart: Payment type share by value and order count
WITH payment_type_summary AS (
    SELECT
        payment_type,
        SUM(total_orders) AS total_orders,
        SUM(total_payment_value) AS total_payment_value
    FROM {{ ref('mart_payment') }}
    GROUP BY payment_type
)
SELECT
    payment_type,
    total_orders,
    ROUND(total_orders::NUMERIC / NULLIF(SUM(total_orders) OVER (), 0) * 100, 2) AS order_share_pct,
    ROUND(total_payment_value::NUMERIC, 2) AS total_payment_value,
    ROUND(total_payment_value::NUMERIC / NULLIF(SUM(total_payment_value) OVER (), 0) * 100, 2) AS payment_value_share_pct
FROM payment_type_summary
ORDER BY total_payment_value DESC;

-- Chart: Payment value by month
SELECT
    year,
    month,
    CONCAT(year, '-', LPAD(month::TEXT, 2, '0')) AS year_month,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_payment_value)::NUMERIC, 2) AS total_payment_value,
    ROUND(SUM(total_payment_value)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_payment_per_order
FROM {{ ref('mart_payment') }}
GROUP BY year, month
ORDER BY year, month;

-- Chart: Payment type trend by month
SELECT
    year,
    month,
    CONCAT(year, '-', LPAD(month::TEXT, 2, '0')) AS year_month,
    payment_type,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_payment_value)::NUMERIC, 2) AS total_payment_value
FROM {{ ref('mart_payment') }}
GROUP BY year, month, payment_type
ORDER BY year, month, total_payment_value DESC;

-- Insight: Installment behavior by payment type
SELECT
    payment_type,
    SUM(total_orders) AS total_orders,
    SUM(single_payment_orders) AS single_payment_orders,
    SUM(installment_orders) AS installment_orders,
    ROUND(SUM(installment_orders)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS installment_order_rate_pct,
    ROUND(SUM(avg_installments * total_payment_records)::NUMERIC / NULLIF(SUM(total_payment_records), 0), 2) AS avg_installments,
    MAX(max_installments) AS max_installments
FROM {{ ref('mart_payment') }}
GROUP BY payment_type
ORDER BY installment_order_rate_pct DESC, total_orders DESC;

-- Ranking: Installment rate by state
SELECT
    customer_state,
    SUM(total_orders) AS total_orders,
    SUM(installment_orders) AS installment_orders,
    ROUND(SUM(installment_orders)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS installment_order_rate_pct,
    ROUND(SUM(total_payment_value)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_payment_per_order
FROM {{ ref('mart_payment') }}
GROUP BY customer_state
HAVING SUM(total_orders) >= 100
ORDER BY installment_order_rate_pct DESC, total_orders DESC;

-- Ranking: States with highest payment value
SELECT
    customer_state,
    SUM(total_orders) AS total_orders,
    SUM(total_customers) AS total_customers,
    ROUND(SUM(total_payment_value)::NUMERIC, 2) AS total_payment_value,
    ROUND(SUM(total_payment_value)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_payment_per_order
FROM {{ ref('mart_payment') }}
GROUP BY customer_state
ORDER BY total_payment_value DESC
LIMIT 20;

-- Comparison: Installment vs non-installment orders
SELECT
    CASE
        WHEN payment_type = 'credit_card' THEN 'Credit card'
        ELSE 'Other payment types'
    END AS payment_group,
    SUM(total_orders) AS total_orders,
    SUM(single_payment_orders) AS single_payment_orders,
    SUM(installment_orders) AS installment_orders,
    ROUND(SUM(installment_orders)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS installment_order_rate_pct,
    ROUND(SUM(total_payment_value)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_payment_per_order
FROM {{ ref('mart_payment') }}
GROUP BY
    CASE
        WHEN payment_type = 'credit_card' THEN 'Credit card'
        ELSE 'Other payment types'
    END
ORDER BY total_orders DESC;

-- Insight: Payment behavior differs by region and method
SELECT
    customer_state,
    payment_type,
    SUM(total_orders) AS total_orders,
    ROUND(SUM(total_payment_value)::NUMERIC, 2) AS total_payment_value,
    ROUND(SUM(total_payment_value)::NUMERIC / NULLIF(SUM(total_orders), 0), 2) AS avg_payment_per_order,
    ROUND(SUM(installment_orders)::NUMERIC / NULLIF(SUM(total_orders), 0) * 100, 2) AS installment_order_rate_pct
FROM {{ ref('mart_payment') }}
GROUP BY customer_state, payment_type
HAVING SUM(total_orders) >= 50
ORDER BY customer_state, total_payment_value DESC;