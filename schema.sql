-- Sample e-commerce + web schema (SQLite/Postgres-friendly)
-- Adjust types for your target DB.

CREATE TABLE customers (
  customer_id    INTEGER PRIMARY KEY,
  first_name     TEXT,
  last_name      TEXT,
  email          TEXT,
  created_at     DATE
);

CREATE TABLE products (
  product_id     INTEGER PRIMARY KEY,
  category       TEXT,
  subcategory    TEXT,
  price          NUMERIC(10,2)
);

CREATE TABLE orders (
  order_id       INTEGER PRIMARY KEY,
  customer_id    INTEGER REFERENCES customers(customer_id),
  order_date     DATE,
  order_status   TEXT,
  city           TEXT,
  region         TEXT
);

CREATE TABLE order_items (
  order_item_id  INTEGER PRIMARY KEY,
  order_id       INTEGER REFERENCES orders(order_id),
  product_id     INTEGER REFERENCES products(product_id),
  quantity       INTEGER,
  unit_price     NUMERIC(10,2),
  discount       NUMERIC(10,2) DEFAULT 0
);

CREATE TABLE web_sessions (
  session_id     TEXT PRIMARY KEY,
  customer_id    INTEGER,
  started_at     TIMESTAMP,
  source         TEXT,   -- e.g., organic, paid, referral
  medium         TEXT,   -- e.g., cpc, social, email
  campaign       TEXT
);

CREATE TABLE web_events (
  event_id       INTEGER PRIMARY KEY,
  session_id     TEXT REFERENCES web_sessions(session_id),
  event_time     TIMESTAMP,
  event_type     TEXT,   -- e.g., pageview, add_to_cart, purchase
  page           TEXT
);
