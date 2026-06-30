SELECT
    seller_id,
    MAX(seller_state) AS seller_state,
    MAX(seller_city) AS seller_city,

    SUM(total_orders) AS total_orders,
    SUM(total_items) AS total_items,
    SUM(total_revenue) AS total_revenue,
    SUM(gross_merchandise_value) AS gross_merchandise_value,
    SUM(total_freight_value) AS total_freight_value,

    AVG(avg_item_price) AS avg_item_price,
    AVG(avg_freight_value) AS avg_freight_value,
    AVG(avg_review_score) AS avg_review_score,

    SUM(low_review_count) AS low_review_count,
    SUM(late_orders) AS late_orders,

    AVG(low_review_rate_pct) AS low_review_rate_pct,
    AVG(late_rate_pct) AS late_rate_pct,
    100.0 * SUM(total_freight_value) / NULLIF(SUM(gross_merchandise_value), 0) AS freight_to_gmv_pct,
    COUNT(DISTINCT product_category_name) AS category_count,
    COUNT(DISTINCT (year::TEXT || '-' || LPAD(month::TEXT, 2, '0'))) AS active_month_count
FROM mart.mart_seller_performance
WHERE seller_id <> 'Unknown'
GROUP BY seller_id
HAVING SUM(total_orders) >= 5;
