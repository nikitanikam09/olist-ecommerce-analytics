-- =====================================================
-- Olist E-commerce Analytics: SQL Analysis (MySQL)
-- Database: olist
-- Tables: olist_customers_dataset, olist_orders_dataset,
--         olist_order_items_dataset, olist_order_reviews_dataset
-- Note: dates are stored as VARCHAR, so we use SUBSTRING / '' checks
-- Tip: select ONE query at a time, then press Ctrl + Enter
-- =====================================================

USE olist;

-- -----------------------------------------------------
-- 01. Monthly orders trend
-- -----------------------------------------------------
SELECT SUBSTRING(order_purchase_timestamp, 1, 7) AS month,
       COUNT(*) AS orders
FROM olist_orders_dataset
GROUP BY month
ORDER BY month;

-- -----------------------------------------------------
-- 02. Order status-wise count
-- -----------------------------------------------------
SELECT order_status, COUNT(*) AS total_orders
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY total_orders DESC;

-- -----------------------------------------------------
-- 03. Total revenue (product + freight)
-- -----------------------------------------------------
SELECT ROUND(SUM(price), 2) AS product_revenue,
       ROUND(SUM(freight_value), 2) AS freight_revenue,
       ROUND(SUM(price + freight_value), 2) AS total_revenue
FROM olist_order_items_dataset;

-- -----------------------------------------------------
-- 04. Top 10 states by revenue
-- -----------------------------------------------------
SELECT c.customer_state,
       ROUND(SUM(oi.price), 2) AS revenue
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
GROUP BY c.customer_state
ORDER BY revenue DESC
LIMIT 10;

-- -----------------------------------------------------
-- 05. Monthly revenue
-- -----------------------------------------------------
SELECT SUBSTRING(o.order_purchase_timestamp, 1, 7) AS month,
       ROUND(SUM(oi.price), 2) AS revenue
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

-- -----------------------------------------------------
-- 06. Average Order Value (AOV)
-- -----------------------------------------------------
SELECT ROUND(SUM(oi.price) / COUNT(DISTINCT oi.order_id), 2) AS avg_order_value
FROM olist_order_items_dataset oi;

-- -----------------------------------------------------
-- 07. Average delivery time (days)
-- -----------------------------------------------------
SELECT ROUND(AVG(DATEDIFF(order_delivered_customer_date,
                          order_purchase_timestamp)), 1) AS avg_delivery_days
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date <> '';

-- -----------------------------------------------------
-- 08. Late delivery %
-- -----------------------------------------------------
SELECT ROUND(100 * SUM(order_delivered_customer_date > order_estimated_delivery_date)
             / COUNT(*), 2) AS late_delivery_pct
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date <> '';

-- -----------------------------------------------------
-- 09. Repeat customers %
-- -----------------------------------------------------
SELECT ROUND(100 * SUM(order_count > 1) / COUNT(*), 2) AS repeat_customer_pct
FROM (
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS order_count
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
) t;

-- -----------------------------------------------------
-- 10. Top 10 customers by spend
-- -----------------------------------------------------
SELECT c.customer_unique_id,
       COUNT(DISTINCT o.order_id) AS total_orders,
       ROUND(SUM(oi.price), 2) AS total_spent
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;

-- -----------------------------------------------------
-- 11. Month-over-month revenue growth (CTE + LAG)
-- -----------------------------------------------------
WITH monthly AS (
    SELECT SUBSTRING(o.order_purchase_timestamp, 1, 7) AS month,
           SUM(oi.price) AS revenue
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
    GROUP BY month
)
SELECT month,
       ROUND(revenue, 2) AS revenue,
       ROUND(LAG(revenue) OVER (ORDER BY month), 2) AS prev_month_revenue,
       ROUND(100 * (revenue - LAG(revenue) OVER (ORDER BY month))
             / LAG(revenue) OVER (ORDER BY month), 2) AS mom_growth_pct
FROM monthly
ORDER BY month;

-- -----------------------------------------------------
-- 12. Delivery delay vs review score (KEY INSIGHT)
-- Result: On Time = 4.29, Late = 2.57
-- -----------------------------------------------------
SELECT CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN 'Late' ELSE 'On Time' END AS delivery_status,
       COUNT(*) AS orders,
       ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM olist_orders_dataset o
JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date <> ''
GROUP BY delivery_status;

-- -----------------------------------------------------
-- 13. Late delivery % by state
-- Result: AL ~23.9%, MA ~19.7% (north-east worst)
-- -----------------------------------------------------
SELECT c.customer_state,
       COUNT(*) AS delivered_orders,
       ROUND(100 * SUM(o.order_delivered_customer_date > o.order_estimated_delivery_date)
             / COUNT(*), 2) AS late_pct
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date <> ''
GROUP BY c.customer_state
ORDER BY late_pct DESC;
