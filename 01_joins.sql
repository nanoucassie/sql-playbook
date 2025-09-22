-- 01_joins.sql — core join patterns

-- 1) Basic customer revenue by region (inner joins)
SELECT
  o.region,
  c.customer_id,
  SUM(oi.quantity * oi.unit_price - oi.discount) AS revenue
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.region, c.customer_id
ORDER BY o.region, revenue DESC;

-- 2) LEFT JOIN with null-handling: customers with/without orders
SELECT
  c.customer_id,
  COUNT(DISTINCT o.order_id) AS orders_count,
  COALESCE(SUM(oi.quantity * oi.unit_price - oi.discount), 0) AS revenue
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_id
ORDER BY revenue DESC;

-- 3) Semi-join: customers who purchased in 'Technology' category
SELECT DISTINCT c.customer_id
FROM customers c
WHERE EXISTS (
  SELECT 1
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  WHERE o.customer_id = c.customer_id
    AND p.category = 'Technology'
);

-- 4) Anti-join: customers who have NEVER ordered
SELECT c.customer_id
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- 5) Bridge pattern: top categories per city
SELECT
  o.city,
  p.category,
  SUM(oi.quantity * oi.unit_price - oi.discount) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY o.city, p.category
QUALIFY ROW_NUMBER() OVER (PARTITION BY o.city ORDER BY revenue DESC) <= 3;
-- For Postgres without QUALIFY, wrap in a subquery and filter by row_number alias.
