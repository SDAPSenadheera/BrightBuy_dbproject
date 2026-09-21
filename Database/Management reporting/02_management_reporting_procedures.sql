-- inserting values to sales_summary table

INSERT INTO sales_summary(variant_id, summary_date, units_sold, total_revenue, order_count)
SELECT
	oi.variant_id,
	DATE(o.order_date) AS summary_date,
	SUM(oi.quantity) AS units_sold,
	SUM(oi.quantity*oi.unit_price) AS total_revenue,
	COUNT(DISTINCT o.order_id)
FROM order_item oi
JOIN orders o ON o.order_id = oi.order_id
WHERE DATE(o.order_date) = CURDATE()-INTERVAL 1 DAY AND o.order_status NOT IN ('Cancelled')
GROUP BY oi.variant_id, DATE(o.order_date)
ON DUPLICATE KEY UPDATE
	units_sold = VALUES(units_sold),
	total_revenue = VALUES(total_revenue),
	order_count = VALUES(order_count);

-- Inserting values to report_access_log table

INSERT INTO report_access_log(employee_id, report_name)
VALUES (:employee_id, 'quarterly_sales_report');

-- Quarterly sales report

SELECT 
	QUARTER(ss.summary_date) AS quarter,
	SUM(ss.order_count) AS order_count,
	SUM(ss.total_revenue) AS total_revenue
FROM sales_summary ss
WHERE YEAR(ss.summary_date) = :year
GROUP BY QUARTER(ss.summary_date)
ORDER BY quarter;

-- Top selling products report

SELECT 
	p.product_id,
	p.name,
	SUM(ss.units_sold) AS units_sold,
	SUM(ss.total_revenue) AS revenue
FROM sales_summary ss
JOIN variant v ON v.variant_id = ss.variant_id
JOIN product p ON p.product_id = v.product_id
WHERE ss.summary_date BETWEEN :start_date AND :end_date
GROUP BY p.product_id, p.name
ORDER BY units_sold DESC
LIMIT :top_n;

-- Category-wise total number of orders

SELECT 
	c.category_id,
	c.name,
	COUNT(DISTINCT o.order_id) AS total_orders
FROM order_item oi
JOIN orders o ON o.order_id = oi.order_id
JOIN variant v ON v.variant_id = oi.variant_id
JOIN product_category pc ON pc.product_id = v.product_id
JOIN category c ON c.category_id = pc.category_id
WHERE o.order_status NOT IN ('Cancelled')
GROUP BY c.category_id, c.name
ORDER BY total_orders DESC;

-- Delivery time estimatess for upcoming orders

SELECT
	o.order_id, 
	cu.first_name, 
	cu.last_name,
	d.delivery_mode,
	ci.name AS destination_city,
	d.est_delivery_date,
	d.delivery_status
FROM delivery d
JOIN orders o ON o.order_id = d.order_id
JOIN customer cu ON cu.customer_id = o.customer_id
JOIN city ci ON ci.city_id = d.city_id
WHERE d.delivery_status NOT IN ('Delivered','Cancelled')
ORDER BY d.est_delivery_date;

-- Customer-wise order summary with payment status

SELECT
	cu.customer_id,
	cu.first_name,
	cu.last_name,
	SUM(o.total_amount) AS lifetime_spend,
	GROUP_CONCAT(DISTINCT p.payment_status) AS payment statuses
FROM customer cu
JOIN orders o ON o.customer_id = cu.customer_id
LEFT JOIN payment p ON p.order_id = o.order_id
GROUP BY cu.customer_id, cu.first_name, cu.last_name
ORDER BY lifetime_spend DESC;