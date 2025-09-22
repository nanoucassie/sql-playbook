-- 02_ctes.sql — layered CTE transformations

-- Monthly revenue per customer with a 2-step CTE
WITH line_revenue AS (
  SELECT
    o.order_id,
    o.customer_id,
    DATE_TRUNC('month', o.order_date) AS month,
    (oi.quantity * oi.unit_price - oi.discount) AS line_rev
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
),
cust_month AS (
  SELECT
    customer_id,
    month,
    SUM(line_rev) AS revenue
  FROM line_revenue
  GROUP BY customer_id, month
)
SELECT *
FROM cust_month
ORDER BY customer_id, month;

-- Top-N categories per region using CTE + window function
WITH cat_rev AS (
  SELECT
    o.region,
    p.category,
    SUM(oi.quantity * oi.unit_price - oi.discount) AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  GROUP BY o.region, p.category
),
ranked AS (
  SELECT
    region, category, revenue,
    ROW_NUMBER() OVER (PARTITION BY region ORDER BY revenue DESC) AS rnk
  FROM cat_rev
)
SELECT region, category, revenue
FROM ranked
WHERE rnk <= 3
ORDER BY region, revenue DESC;
