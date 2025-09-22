-- 06_advanced_patterns.sql — advanced interview patterns
-- Works on Postgres; adapt functions for other dialects where noted.

/* 1) Gaps & Islands (contiguous order dates per customer)
   Goal: group consecutive days into "islands" and summarize each streak.
*/
WITH d AS (
  SELECT
    o.customer_id,
    o.order_id,
    o.order_date::date AS dte
  FROM orders o
),
marked AS (
  SELECT
    customer_id,
    dte,
    -- Start a new island when the gap is more than 1 day
    dte - (ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY dte))::int AS grp
  FROM d
  GROUP BY customer_id, dte
)
SELECT
  customer_id,
  MIN(dte) AS island_start,
  MAX(dte) AS island_end,
  COUNT(*)  AS days_in_island
FROM marked
GROUP BY customer_id, grp
ORDER BY customer_id, island_start;

/* 2) Latest record per key (great for SCD style "current" rows)
   Return each customer's most recent order with revenue.
*/
WITH order_value AS (
  SELECT
    o.customer_id,
    o.order_id,
    o.order_date,
    SUM(oi.quantity * oi.unit_price - oi.discount) AS revenue,
    ROW_NUMBER() OVER (PARTITION BY o.customer_id ORDER BY o.order_date DESC, o.order_id DESC) AS rnk
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY o.customer_id, o.order_id, o.order_date
)
SELECT customer_id, order_id, order_date, revenue
FROM order_value
WHERE rnk = 1
ORDER BY customer_id;

/* 3) Greatest-N-per-group with ties (top sellers per category, keeping ties)
*/
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
    DENSE_RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rnk
  FROM prod_rev
)
SELECT category, product_id, revenue
FROM ranked
WHERE rnk <= 3
ORDER BY category, revenue DESC;

/* 4) Deduplicate: keep the latest by (customer_id, email)
*/
WITH dedup AS (
  SELECT
    c.*,
    ROW_NUMBER() OVER (
      PARTITION BY LOWER(c.email)
      ORDER BY c.created_at DESC, c.customer_id DESC
    ) AS rnk
  FROM customers c
)
SELECT *
FROM dedup
WHERE rnk = 1;

/* 5) Change detection (SCD Type 2-like diff) using lead() to detect changes
   Detect price changes per product over time from a hypothetical price history table.
*/
-- Example table:
-- CREATE TABLE product_price_history(product_id int, valid_from date, price numeric);
WITH hist AS (
  SELECT
    product_id,
    valid_from,
    price,
    LEAD(price) OVER (PARTITION BY product_id ORDER BY valid_from) AS next_price,
    LEAD(valid_from) OVER (PARTITION BY product_id ORDER BY valid_from) AS next_from
  FROM product_price_history
)
SELECT
  product_id,
  valid_from AS price_start,
  COALESCE(next_from - INTERVAL '1 day', CURRENT_DATE) AS price_end,
  price
FROM hist
ORDER BY product_id, price_start;

/* 6) UNPIVOT (normalize wide monthly revenue columns into rows) — Postgres style
   If you created monthly columns (jan_rev, feb_rev, ...), bring them back to (month, revenue).
*/
-- Example wide table "yearly_rev(yr, jan_rev, feb_rev, mar_rev)"
SELECT
  yr,
  key AS month_name,
  value::numeric AS revenue
FROM yearly_rev
CROSS JOIN LATERAL (
  VALUES
    ('jan', jan_rev),
    ('feb', feb_rev),
    ('mar', mar_rev)
) AS u(key, value)
ORDER BY yr, month_name;

/* 7) Percentile by group without window percentile (fallback) — using NTILE
   Approximate 90th percentile of order value per region.
*/
WITH order_values AS (
  SELECT
    o.region,
    o.order_id,
    SUM(oi.quantity * oi.unit_price - oi.discount) AS order_value
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY o.region, o.order_id
),
buckets AS (
  SELECT
    region, order_id, order_value,
    NTILE(10) OVER (PARTITION BY region ORDER BY order_value) AS decile
  FROM order_values
)
SELECT region, MIN(order_value) AS approx_p90
FROM buckets
WHERE decile = 10
GROUP BY region
ORDER BY region;

/* 8) Sessions with first/last event timestamps and duration
*/
WITH evt AS (
  SELECT
    we.session_id,
    MIN(we.event_time) AS first_ts,
    MAX(we.event_time) AS last_ts
  FROM web_events we
  GROUP BY we.session_id
)
SELECT
  e.session_id,
  e.first_ts,
  e.last_ts,
  EXTRACT(EPOCH FROM (e.last_ts - e.first_ts)) AS duration_seconds
FROM evt e
ORDER BY duration_seconds DESC;
