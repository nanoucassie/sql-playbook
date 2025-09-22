-- case_studies/marketing_funnel.sql
/*
Business question
-----------------
Marketing wants a funnel view by source: sessions → add_to_cart → purchase,
with conversion rates and drop-offs. They also need a weekly trend.

Deliverables
------------
1) Aggregated funnel by source with CVR between each stage.
2) Weekly purchases by source to spot seasonality.

Solution
--------
*/
-- 1) Funnel by source
WITH events AS (
  SELECT
    ws.source,
    we.session_id,
    MAX(CASE WHEN we.event_type = 'pageview' THEN 1 ELSE 0 END) AS had_session,
    MAX(CASE WHEN we.event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS had_add,
    MAX(CASE WHEN we.event_type = 'purchase' THEN 1 ELSE 0 END) AS had_purchase
  FROM web_sessions ws
  JOIN web_events we ON we.session_id = ws.session_id
  GROUP BY ws.source, we.session_id
),
agg AS (
  SELECT
    source,
    SUM(had_session)  AS sessions,
    SUM(had_add)      AS adds,
    SUM(had_purchase) AS purchases
  FROM events
  GROUP BY source
)
SELECT
  source,
  sessions,
  adds,
  purchases,
  ROUND(100.0 * adds / NULLIF(sessions, 0), 2) AS session_to_add_cvr_pct,
  ROUND(100.0 * purchases / NULLIF(adds, 0), 2) AS add_to_purchase_cvr_pct,
  ROUND(100.0 * purchases / NULLIF(sessions, 0), 2) AS session_to_purchase_cvr_pct
FROM agg
ORDER BY purchases DESC;

-- 2) Weekly purchases by source
SELECT
  ws.source,
  DATE_TRUNC('week', we.event_time) AS week,
  COUNT(*) AS purchases
FROM web_events we
JOIN web_sessions ws ON ws.session_id = we.session_id
WHERE we.event_type = 'purchase'
GROUP BY ws.source, DATE_TRUNC('week', we.event_time)
ORDER BY week, purchases DESC;
