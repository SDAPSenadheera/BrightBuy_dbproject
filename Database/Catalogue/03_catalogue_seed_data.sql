-- =========================================================
-- BrightBuy Catalogue Seed Data
-- Author: Kavindu Mihisara
-- =========================================================

USE brightbuy;

-- Run with a client that stops on errors. Disconnect/ROLLBACK on failure.
START TRANSACTION;

-- ---------------------------------------------------------
-- Top-level categories
-- ---------------------------------------------------------

INSERT INTO category (
    category_id,
    parent_category_id,
    name,
    description
) VALUES
    (1, NULL, 'Electronics', 'Consumer electronic products'),
    (2, NULL, 'Computers', 'Computers and related devices'),
    (3, NULL, 'Toys', 'Toys and recreational products')
AS new
ON DUPLICATE KEY UPDATE
    parent_category_id = new.parent_category_id,
    name = new.name,
    description = new.description,
    is_active = TRUE;


-- ---------------------------------------------------------
-- Child categories
-- ---------------------------------------------------------

INSERT INTO category (
    category_id,
    parent_category_id,
    name,
    description
) VALUES
    (4, 1, 'Mobile Phones', 'Smartphones and mobile phones'),
    (5, 1, 'Audio Devices', 'Headphones, speakers and audio equipment'),
    (6, 1, 'Smart Devices', 'Smart watches and connected devices'),
    (7, 2, 'Laptops', 'Portable computers'),
    (8, 2, 'Computer Accessories', 'Computer accessories and peripherals'),
    (9, 3, 'Educational Toys', 'Learning and educational toys'),
    (10, 3, 'Remote Controlled Toys', 'Remote-controlled toys')
AS new
ON DUPLICATE KEY UPDATE
    parent_category_id = new.parent_category_id,
    name = new.name,
    description = new.description,
    is_active = TRUE;


-- ---------------------------------------------------------
-- Products required by the existing variant seed data
-- in ../Inventory_Delivery_sample_data.sql.
-- ---------------------------------------------------------

INSERT INTO product (
    product_id,
    sku,
    name,
    description,
    image_url
) VALUES
    (
        1,
        'IPHONE-15-PRO',
        'Apple iPhone 15 Pro',
        'Apple smartphone available in 256GB and 512GB variants',
        NULL
    ),
    (
        2,
        'GALAXY-S24-ULTRA',
        'Samsung Galaxy S24 Ultra',
        'Samsung smartphone available in a 512GB variant',
        NULL
    ),
    (
        3,
        'SONY-WH-1000XM5',
        'Sony WH-1000XM5',
        'Wireless noise-cancelling over-ear headphones',
        NULL
    )
AS new
ON DUPLICATE KEY UPDATE
    sku = new.sku,
    name = new.name,
    description = new.description,
    image_url = new.image_url,
    is_active = TRUE;


-- ---------------------------------------------------------
-- Product-category assignments
-- Remove mappings created by the earlier placeholder seed so
-- rerunning this corrected seed does not retain bad categories.
-- ---------------------------------------------------------

DELETE FROM product_category
WHERE (product_id = 2 AND category_id IN (2, 7))
   OR (product_id = 3 AND category_id IN (3, 9));


-- Ignore only duplicate assignments, not invalid data or foreign-key errors.

INSERT INTO product_category (
    product_id,
    category_id
) VALUES
    (1, 4),
    (1, 1),
    (2, 4),
    (2, 1),
    (3, 5),
    (3, 1)
AS new
ON DUPLICATE KEY UPDATE
    category_id = new.category_id;

COMMIT;
