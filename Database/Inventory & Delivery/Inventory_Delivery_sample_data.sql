INSERT INTO city (city_id, name, is_main_city) VALUES
(1, 'Houston', TRUE),
(2, 'Dallas', TRUE),
(3, 'Austin', TRUE),
(4, 'San Antonio', TRUE),
(5, 'Lubbock', FALSE),
(6, 'Waco', FALSE),
(7, 'Amarillo', FALSE);

INSERT INTO warehouse (warehouse_id, name, location) VALUES
(1, 'Texas Central Depot', '100 Industrial Way, Houston, TX'),
(2, 'North Branch Storage', '4500 Tech Blvd, Dallas, TX'),
(3, 'Westside Distribution', '7700 Logistics Dr, Austin, TX');

INSERT INTO variant (variant_id, product_id, warehouse_id, variant_name, colour, memory_size, price, stock_quantity) VALUES
(1, 1, 1, 'iPhone 15 Pro - Black 256GB', 'Titanium Black', '256GB', 1099.00, 50),
(2, 1, 2, 'iPhone 15 Pro - Blue 256GB', 'Titanium Blue', '256GB', 1099.00, 15),
(3, 1, 1, 'iPhone 15 Pro - Black 512GB', 'Titanium Black', '512GB', 1299.00, 0), -- Out of stock for testing
(4, 2, 3, 'Galaxy S24 Ultra - Gray 512GB', 'Titanium Gray', '512GB', 1299.99, 30),
(5, 3, 1, 'Sony WH-1000XM5 - Silver', 'Silver', 'N/A', 348.00, 120);

INSERT INTO delivery (delivery_id, order_id, city_id, delivery_mode, est_delivery_date, delivery_status) VALUES
(1, 101, 1, 'Standard Delivery', '2026-09-10', 'Processing'), -- Main city (5 days)
(2, 102, 5, 'Standard Delivery', '2026-09-12', 'Shipped'),    -- Other city (7 days)
(3, 103, 3, 'Store Pickup', '2026-09-08', 'Ready for Pickup'),
(4, 104, 2, 'Standard Delivery', '2026-09-13', 'Processing'); -- Out of stock penalty example

