-- 05_aggregation_pivot.sql — conditional sums, group-wise top-N, pivot-like tricks

-- 1) Conditional aggregation by channel
SELECT
  ws.source,
  SUM(CASE WHEN we.event_type = 'pageview' THEN 1 ELSE 0 END) AS pageviews,
  SUM(CASE WHEN we.event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS adds,
  SUM(CASE WHEN we.event_type = 'purchase' THEN 1 ELSE 0 END) AS purchases
FROM web_sessions ws
JOIN web_events we ON we.session_id = ws.session_id
GROUP BY ws.source
ORDER BY purchases DESC;

-- 2) Top 3 products by revenue per category
WITH prod_rev AS (
  SELECT
    p.category,
    p.product_id,
    SUM(oi.quantity * oi.unit_price - oi.discount) AS revenue
  FROM order_items oi
  JOIN products p ON p.product_id = oi.product_id
  GROUP BY p.category, p.product_id
),
ranked AS (
  SELECT
    category, product_id, revenue,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) AS rnk
  FROM prod_rev
)
SELECT *
FROM ranked
WHERE rnk <= 3
ORDER BY category, revenue DESC;

-- 3) Pivot-like: monthly revenue columns (Postgres example)
-- For SQLite/MySQL, emulate with conditional sums.
SELECT
  DATE_TRUNC('year', o.order_date) AS yr,
  SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 1 THEN oi.quantity*oi.unit_price-oi.discount END) AS jan_rev,
  SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 2 THEN oi.quantity*oi.unit_price-oi.discount END) AS feb_rev,
  SUM(CASE WHEN EXTRACT(MONTH FROM o.order_date) = 3 THEN oi.quantity*oi.unit_price-oi.discount END) AS mar_rev
  -- add more months as needed
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY DATE_TRUNC('year', o.order_date)
ORDER BY yr;
