-- Duplicate primary-key detection (run against every loaded table)  كشف التكرارات    
SELECT order_item_id, COUNT(*) AS occurrences
FROM dbo.order_item
GROUP BY order_item_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*) AS occurrences
FROM dbo.orders
GROUP BY order_id
HAVING COUNT(*) > 1;
----------------------------------------------------------------------------------------------------------
-- Numeric range validation  استعالمات التحقق قواعد رقمية / زمنية
SELECT order_item_id, order_item_quantity, discount_amount, discount_rate
FROM dbo.order_item
WHERE order_item_quantity <= 0
OR discount_amount < 0
OR discount_rate < 0 OR discount_rate > 1;

-- Date sequence validation
SELECT order_id, order_date, shipping_date
FROM dbo.orders
WHERE shipping_date < order_date;

-- Recomputed sales consistency check
SELECT oi.order_item_id, oi.sales, (oi.unit_price_at_sale * oi.order_item_quantity) AS expected_sales
FROM dbo.order_item oi
WHERE ABS(oi.sales - (oi.unit_price_at_sale * oi.order_item_quantity)) > 0.01;
--------------------------------------------------------------------------------------------------------------
-- Referential integrity: orphan detection across all 15 relationships   فحوصات سالمة الترابط المرجعي
SELECT oi.order_item_id, oi.product_id
FROM dbo.order_item oi
LEFT JOIN dbo.product p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT o.order_id, o.customer_id
FROM dbo.orders o
LEFT JOIN dbo.customer c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT o.order_id, o.destination_id
FROM dbo.orders o
LEFT JOIN dbo.shipping_destination d ON o.destination_id = d.destination_id
WHERE d.destination_id IS NULL;

SELECT c.customer_id, c.customer_address_id
FROM dbo.customer c
LEFT JOIN dbo.customer_address a ON c.customer_address_id = a.customer_address_id
WHERE a.customer_address_id IS NULL;

SELECT p.product_id, p.category_id
FROM dbo.product p
LEFT JOIN dbo.category cat ON p.category_id = cat.category_id
WHERE cat.category_id IS NULL;

SELECT cat.category_id, cat.department_id
FROM dbo.category cat
LEFT JOIN dbo.department d ON cat.department_id = d.department_id
WHERE d.department_id IS NULL;
--------------------------------------------------------------------------------------------------------------
-- Lookup validation: confirm every FK value is a member of its lookup domain   التحقق من جداول البحث (Lookup)
SELECT DISTINCT o.shipping_mode_id
FROM dbo.orders o
LEFT JOIN dbo.shipping_mode sm ON o.shipping_mode_id = sm. shipping_mode_id
WHERE sm.shipping_mode_id IS NULL;

SELECT DISTINCT o.order_status_id
FROM dbo.orders o
LEFT JOIN dbo.order_status os ON o.order_status_id = os.order_status_id
WHERE os.order_status_id IS NULL;

SELECT DISTINCT o.delivery_status_id
FROM dbo.orders o
LEFT JOIN dbo.delivery_status ds ON o.delivery_status_id = ds.delivery_status_id
WHERE ds.delivery_status_id IS NULL;

SELECT DISTINCT c.customer_segment_id
FROM dbo.customer c
LEFT JOIN dbo.customer_segment cs ON c.customer_segment_id = cs.customer_segment_id
WHERE cs.customer_segment_id IS NULL;

-- Duplicate lookup-value detection (same real value, two rows)
SELECT order_country_name, COUNT(*) AS row_count
FROM dbo.order_country
GROUP BY order_country_name
HAVING COUNT(*) >1;
---------------------------------------------------------------------------------------------------------------
-- Quality-assurance queries: business rule spot-checks   استعالمات ضمان الجودة
-- 1) Every order_item must reference an order that exists
SELECT COUNT(*) AS orphan_order_items
FROM dbo.order_item oi
LEFT JOIN dbo. orders o ON oi.order_id = o.order_id
WHERE o. order_id IS NULL;

-- 2) No customer should have more than 1 row per (fname, lname, address) after dedupe
SELECT customer_fname, customer_lname, customer_address_id, COUNT(*) AS cnt
FROM dbo.customer
GROUP BY customer_fname, customer_lname, customer_address_id
HAVING COUNT(*) > 1;

-- 3) Aggregate sanity check: total sales and profit within expected clean-baseline range
SELECT SUM(sales) AS total_sales, SUM(profit_amount) AS total_profit
FROM dbo.order_item;
--------------------------------------------------------------------------------------------------------------
--Final validation suite - run once, immediately before Star Schema load   استعالمات التحقق النهائي
DECLARE @errors INT = 0;

IF EXISTS (SELECT 1 FROM dbo.order_item GROUP BY order_item_id HAVING COUNT(*) > 1) SET @errors += 1;
IF EXISTS (SELECT 1 FROM dbo.orders GROUP BY order_id HAVING COUNT(*) > 1) SET @errors += 1;
IF EXISTS (SELECT 1 FROM dbo.order_item WHERE order_item_quantity <= 0) SET @errors += 1;
IF EXISTS (SELECT 1 FROM dbo.order_item WHERE discount_rate < 0 OR discount_rate > 1) SET @errors += 1;
IF EXISTS (SELECT 1 FROM dbo.orders WHERE shipping_date < order_date) SET @errors += 1;
IF EXISTS (SELECT 1 FROM dbo.order_item oi LEFT JOIN dbo. product p ON oi.product_id = p.product_id WHERE p.product_id IS NULL) SET @errors
+= 1;
IF EXISTS (SELECT 1 FROM dbo.orders o LEFT JOIN dbo.customer c ON o.customer_id = c.customer_id WHERE c.customer_id IS NULL) SET @errors +=
1;

SELECT CASE WHEN @errors = 0 THEN 'PASS - Ready for Star Schema load' ELSE CAST(@errors AS VARCHAR) + ' CHECK(S) FAILED' END AS
FinalValidationResult;
------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys. schemas WHERE name = 'rpt')
EXEC('CREATE SCHEMA rpt');

GO