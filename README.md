# SQL Playbook — Lyna Zitouche

A practical, interview-ready collection of SQL patterns and case studies.

## What's inside
- `src/` — focused patterns (joins, CTEs, window functions, dates, aggregations)
- `case_studies/` — end-to-end problems with business framing and solutions
- `data/` — sample schema you can run on SQLite/Postgres/MySQL
- `reports/` — (optional) screenshots or short notes

## How to use
1) Load the sample schema from `data/schema.sql` into your DB (SQLite/Postgres/MySQL with minor tweaks).
2) Copy queries from `src/` and adapt table names as needed.
3) Tackle `case_studies/` without peeking; then compare with the solution queries.

## Skills covered
- Joins (inner/left/semi/anti), many-to-many bridges
- CTEs (layered transformations), subqueries
- Window functions (ROW_NUMBER, LAG/LEAD, percentiles, rolling windows)
- Date logic (truncation, bins, month-over-month)
- Aggregations, conditional sums, pivot-like patterns
- Practical tasks: funnels, cohorts, retention, top-N by group, revenue attribution

## License
MIT — free to use for learning and portfolio.
