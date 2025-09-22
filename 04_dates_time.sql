-- 04_dates_time.sql — date truncation, bins, working days, month calendars

-- 1) Daily to monthly bins
SELECT
  DATE_TRUNC('month', o.order_date) AS month,
  COUNT(DISTINCT o.order_id) AS orders,
  SUM(oi.quantity * oi.unit_price - oi.discount) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY month;

-- 2) First order date per customer
SELECT
  customer_id,
  MIN(order_date) AS first_order_date
FROM orders
GROUP BY customer_id;

-- 3) Active customers by month (had at least one order this month)
WITH cust_month AS (
  SELECT DISTINCT
    customer_id,
    DATE_TRUNC('month', order_date) AS month
  FROM orders
)
SELECT month, COUNT(*) AS active_customers
FROM cust_month
GROUP BY month
ORDER BY month;
