-- 1. CREATE SALES_ANALYTICS TABLE

DROP TABLE IF EXISTS Sales_Analytics;

CREATE TABLE Sales_Analytics (
    order_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    city VARCHAR(50),
    order_date DATE,
    amount DECIMAL(10,2),
    quantity INT,
    status VARCHAR(20)
);


-- 2. INSERT 10,000 RECORDS

SET SESSION cte_max_recursion_depth = 11000;

INSERT INTO Sales_Analytics
(
    order_id,
    customer_id,
    product_id,
    city,
    order_date,
    amount,
    quantity,
    status
)
WITH RECURSIVE numbers AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1
    FROM numbers
    WHERE n < 10000
)
SELECT
    n,
    MOD(n, 1000) + 1,
    MOD(n, 100) + 1,

    CASE MOD(n, 4)
        WHEN 0 THEN 'Delhi'
        WHEN 1 THEN 'Mumbai'
        WHEN 2 THEN 'Pune'
        ELSE 'Jaipur'
    END,

    DATE_ADD('2025-01-01', INTERVAL MOD(n, 365) DAY),

    100 + MOD(n * 17, 5000),

    MOD(n, 10) + 1,

    CASE MOD(n, 3)
        WHEN 0 THEN 'Completed'
        WHEN 1 THEN 'Pending'
        ELSE 'Cancelled'
    END

FROM numbers;


-- VERIFY TOTAL RECORDS

SELECT COUNT(*) AS total_records
FROM Sales_Analytics;


-- 3. QUERY 1: DATE FILTERING

-- BEFORE OPTIMIZATION

EXPLAIN
SELECT *
FROM Sales_Analytics
WHERE YEAR(order_date) = 2025;


-- CREATE INDEX ON ORDER_DATE

CREATE INDEX idx_order_date
ON Sales_Analytics(order_date);


-- AFTER OPTIMIZATION

EXPLAIN
SELECT *
FROM Sales_Analytics
WHERE order_date >= '2025-01-01'
AND order_date < '2026-01-01';


-- 4. QUERY 2: CITY FILTERING

-- BEFORE OPTIMIZATION

EXPLAIN
SELECT *
FROM Sales_Analytics
WHERE LOWER(city) = 'delhi';


-- CREATE INDEX ON CITY

CREATE INDEX idx_city
ON Sales_Analytics(city);


-- AFTER OPTIMIZATION

EXPLAIN
SELECT *
FROM Sales_Analytics
WHERE city = 'Delhi';


-- 5. QUERY 3: STATUS AND DATE FILTERING

-- BEFORE OPTIMIZATION

EXPLAIN
SELECT *
FROM Sales_Analytics
WHERE status = 'Completed'
AND order_date >= '2025-06-01';


-- CREATE COMPOSITE INDEX

CREATE INDEX idx_status_date
ON Sales_Analytics(status, order_date);


-- AFTER OPTIMIZATION

EXPLAIN
SELECT *
FROM Sales_Analytics
WHERE status = 'Completed'
AND order_date >= '2025-06-01';


-- 6. QUERY 4: CUSTOMER SALES ANALYSIS

-- BEFORE OPTIMIZATION
-- Using a correlated subquery

EXPLAIN
SELECT DISTINCT s.customer_id
FROM Sales_Analytics s
WHERE (
    SELECT SUM(s2.amount)
    FROM Sales_Analytics s2
    WHERE s2.customer_id = s.customer_id
) > 30000;


-- CREATE COMPOSITE INDEX

CREATE INDEX idx_customer_amount
ON Sales_Analytics(customer_id, amount);


-- AFTER OPTIMIZATION
-- Using GROUP BY and HAVING

EXPLAIN
SELECT customer_id
FROM Sales_Analytics
GROUP BY customer_id
HAVING SUM(amount) > 30000;


-- 7. QUERY 5: TOP 10 HIGHEST SALES

-- BEFORE OPTIMIZATION

SELECT order_id, amount
FROM Sales_Analytics
ORDER BY amount DESC
LIMIT 10;


-- CREATE INDEX ON AMOUNT

CREATE INDEX idx_amount
ON Sales_Analytics(amount);


-- AFTER OPTIMIZATION

EXPLAIN
SELECT order_id, amount
FROM Sales_Analytics
ORDER BY amount DESC
LIMIT 10;


-- 8. MEASURE EXECUTION TIME

SET @start_time = NOW(6);

SELECT *
FROM Sales_Analytics
WHERE order_date >= '2025-01-01'
AND order_date < '2026-01-01';

SELECT
    TIMESTAMPDIFF(
        MICROSECOND,
        @start_time,
        NOW(6)
    ) / 1000 AS execution_time_ms;


-- 9. COMPARE EXECUTION PLANS

-- DATE FILTERING

EXPLAIN
SELECT *
FROM Sales_Analytics
WHERE YEAR(order_date) = 2025;


EXPLAIN
SELECT *
FROM Sales_Analytics
WHERE order_date >= '2025-01-01'
AND order_date < '2026-01-01';


-- CITY FILTERING

EXPLAIN
SELECT *
FROM Sales_Analytics
WHERE LOWER(city) = 'delhi';


EXPLAIN
SELECT *
FROM Sales_Analytics
WHERE city = 'Delhi';
