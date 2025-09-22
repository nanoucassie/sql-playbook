-- 03_window_functions.sql — ranking, LAG/LEAD, rolling windows, percentiles

-- 1) Rank customers by monthly revenue within region
WITH cust_month AS (
  SELECT
    o.region,
    o.customer_id,
    DATE_TRUNC('month', o.order_date) AS month,
    SUM(oi.quantity * oi.unit_price - oi.discount) AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY o.region, o.customer_id, DATE_TRUNC('month', o.order_date)
)
SELECT
  region, customer_id, month, revenue,
  ROW_NUMBER() OVER (PARTITION BY region, month ORDER BY revenue DESC) AS rnk
FROM cust_month
ORDER BY region, month, rnk;

-- 2) Month-over-month revenue change per region
WITH region_month AS (
  SELECT
    o.region,
    DATE_TRUNC('month', o.order_date) AS month,
    SUM(oi.quantity * oi.unit_price - oi.discount) AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY o.region, DATE_TRUNC('month', o.order_date)
)
SELECT
  region, month, revenue,
  LAG(revenue) OVER (PARTITION BY region ORDER BY month) AS prev_rev,
  (revenue - LAG(revenue) OVER (PARTITION BY region ORDER BY month)) AS mom_abs,
  ROUND(100.0 * (revenue - LAG(revenue) OVER (PARTITION BY region ORDER BY month)) 
        / NULLIF(LAG(revenue) OVER (PARTITION BY region ORDER BY month), 0), 2) AS mom_pct
FROM region_month
ORDER BY region, month;

-- 3) Rolling 3-month revenue per category
WITH cat_month AS (
  SELECT
    p.category,
    DATE_TRUNC('month', o.order_date) AS month,
    SUM(oi.quantity * oi.unit_price - oi.discount) AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  GROUP BY p.category, DATE_TRUNC('month', o.order_date)
)
SELECT
  category, month, revenue,
  SUM(revenue) OVER (PARTITION BY category ORDER BY month
                     ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3m_rev
FROM cat_month
ORDER BY category, month;

-- 4) Percentile basket: 90th percentile order values by region
WITH order_values AS (
  SELECT
    o.region,
    o.order_id,
    SUM(oi.quantity * oi.unit_price - oi.discount) AS order_value
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY o.region, o.order_id
)
SELECT DISTINCT
  region,
  PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY order_value) 
    OVER (PARTITION BY region) AS p90_order_value
FROM order_values
ORDER BY region;
