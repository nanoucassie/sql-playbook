-- case_studies/sales_cohort_retention.sql
/*
Business question
-----------------
What does customer retention look like over time? For each cohort of customers
(by first order month), calculate the share active in subsequent months.

Deliverables
------------
1) A cohort table: rows = cohort month, columns = months since first order,
   values = retention rate (% of cohort with any order in that month).
*/

WITH first_order AS (
  SELECT
    customer_id,
    DATE_TRUNC('month', MIN(order_date)) AS cohort_month
  FROM orders
  GROUP BY customer_id
),
activity AS (
  SELECT DISTINCT
    o.customer_id,
    DATE_TRUNC('month', o.order_date) AS active_month
  FROM orders o
),
joined AS (
  SELECT
    f.customer_id,
    f.cohort_month,
    a.active_month,
    (EXTRACT(YEAR FROM a.active_month)*12 + EXTRACT(MONTH FROM a.active_month)) -
    (EXTRACT(YEAR FROM f.cohort_month)*12 + EXTRACT(MONTH FROM f.cohort_month)) AS month_number
  FROM first_order f
  JOIN activity a ON a.customer_id = f.customer_id
  WHERE a.active_month >= f.cohort_month
),
cohort_sizes AS (
  SELECT cohort_month, COUNT(DISTINCT customer_id) AS cohort_size
  FROM first_order
  GROUP BY cohort_month
),
retention AS (
  SELECT
    cohort_month,
    month_number,
    COUNT(DISTINCT customer_id) AS active_customers
  FROM joined
  GROUP BY cohort_month, month_number
)
SELECT
  r.cohort_month,
  r.month_number,
  ROUND(100.0 * r.active_customers / NULLIF(c.cohort_size, 0), 2) AS retention_pct
FROM retention r
JOIN cohort_sizes c USING (cohort_month)
ORDER BY r.cohort_month, r.month_number;
