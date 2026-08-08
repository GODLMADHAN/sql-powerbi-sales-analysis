-- ============================================================
-- SALES ANALYTICS PROJECT - Analytical SQL Queries
-- Database: sales_project (MySQL)
-- Run sales_project.sql first to create schema + data.
-- ============================================================

USE sales_project;

-- ------------------------------------------------------------
-- 1. Total revenue, orders, and average order value (KPIs)
-- ------------------------------------------------------------
SELECT
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)),2) AS total_revenue,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount))
          / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('Cancelled','Returned');

-- ------------------------------------------------------------
-- 2. Monthly revenue trend
-- ------------------------------------------------------------
SELECT
    DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue,
    COUNT(DISTINCT o.order_id) AS orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('Cancelled','Returned')
GROUP BY order_month
ORDER BY order_month;

-- ------------------------------------------------------------
-- 3. Month-over-month revenue growth (window function)
-- ------------------------------------------------------------
WITH monthly AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m') AS order_month,
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('Cancelled','Returned')
    GROUP BY order_month
)
SELECT
    order_month,
    ROUND(revenue, 2) AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY order_month), 2) AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY order_month))
        / LAG(revenue) OVER (ORDER BY order_month) * 100, 1
    ) AS pct_growth
FROM monthly
ORDER BY order_month;

-- ------------------------------------------------------------
-- 4. Top 10 products by revenue
-- ------------------------------------------------------------
SELECT
    p.product_name,
    p.category,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status NOT IN ('Cancelled','Returned')
GROUP BY p.product_id, p.product_name, p.category
ORDER BY revenue DESC
LIMIT 10;

-- ------------------------------------------------------------
-- 5. Revenue and margin by category
-- ------------------------------------------------------------
SELECT
    p.category,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue,
    ROUND(SUM(oi.quantity * p.cost), 2) AS total_cost,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) - SUM(oi.quantity * p.cost), 2) AS gross_profit,
    ROUND(
        (SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) - SUM(oi.quantity * p.cost))
        / SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) * 100, 1
    ) AS margin_pct
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status NOT IN ('Cancelled','Returned')
GROUP BY p.category
ORDER BY revenue DESC;

-- ------------------------------------------------------------
-- 6. Top 10 customers by lifetime spend, with rank
-- ------------------------------------------------------------
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.region,
    c.segment,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS lifetime_spend,
    RANK() OVER (ORDER BY SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) DESC) AS spend_rank
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('Cancelled','Returned')
GROUP BY c.customer_id, customer_name, c.region, c.segment
ORDER BY lifetime_spend DESC
LIMIT 10;

-- ------------------------------------------------------------
-- 7. Revenue by region and segment
-- ------------------------------------------------------------
SELECT
    c.region,
    c.segment,
    COUNT(DISTINCT o.order_id) AS orders,
    ROUND(SUM(oi.quantity * oi.unit_price * (1 - oi.discount)), 2) AS revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status NOT IN ('Cancelled','Returned')
GROUP BY c.region, c.segment
ORDER BY c.region, revenue DESC;

-- ------------------------------------------------------------
-- 8. Repeat vs one-time customers (retention view)
-- ------------------------------------------------------------
WITH order_counts AS (
    SELECT customer_id, COUNT(*) AS num_orders
    FROM orders
    WHERE status NOT IN ('Cancelled','Returned')
    GROUP BY customer_id
)
SELECT
    CASE WHEN num_orders = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
    COUNT(*) AS num_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_customers
FROM order_counts
GROUP BY customer_type;

-- ------------------------------------------------------------
-- 9. Order status breakdown (cancellations/returns rate)
-- ------------------------------------------------------------
SELECT
    status,
    COUNT(*) AS num_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_total
FROM orders
GROUP BY status
ORDER BY num_orders DESC;

-- ------------------------------------------------------------
-- 10. A reusable VIEW for Power BI to import directly
--     (flattened fact table: one row per order line, revenue calculated)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_sales_fact AS
SELECT
    oi.order_item_id,
    o.order_id,
    o.order_date,
    o.status,
    o.payment_method,
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.region,
    c.state,
    c.city,
    c.segment,
    p.product_id,
    p.product_name,
    p.category,
    oi.quantity,
    oi.unit_price,
    oi.discount,
    p.cost,
    ROUND(oi.quantity * oi.unit_price * (1 - oi.discount), 2) AS line_revenue,
    ROUND(oi.quantity * p.cost, 2) AS line_cost,
    ROUND(oi.quantity * oi.unit_price * (1 - oi.discount) - oi.quantity * p.cost, 2) AS line_profit
FROM order_items oi
JOIN orders o     ON oi.order_id = o.order_id
JOIN customers c  ON o.customer_id = c.customer_id
JOIN products p   ON oi.product_id = p.product_id;



-- In Power BI: connect to MySQL, import (or DirectQuery) this single view.
-- It's already a clean flat table -> easiest way to build your star schema
-- (or split it back into fact/dim tables inside Power BI's model view).
