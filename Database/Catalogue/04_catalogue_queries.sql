-- =========================================================
-- BrightBuy Catalogue Queries
-- Author: Kavindu Mihisara
-- =========================================================

USE brightbuy;


-- 1. List active products and their variants.

SELECT
    p.product_id,
    p.sku,
    p.name AS product_name,
    v.variant_id,
    v.variant_name,
    v.colour,
    v.memory_size,
    v.price,
    v.stock_quantity
FROM product p
JOIN variant v
    ON v.product_id = p.product_id
WHERE p.is_active = TRUE
ORDER BY p.name, v.price;


-- 2. Browse products belonging to one category.
-- Replace 4 with the requested category ID.

SELECT DISTINCT
    p.product_id,
    p.sku,
    p.name
FROM product p
JOIN product_category pc
    ON pc.product_id = p.product_id
WHERE pc.category_id = 4
  AND p.is_active = TRUE
ORDER BY p.name;


-- 3. Show categories assigned to one product.

SELECT
    p.product_id,
    p.name AS product_name,
    c.category_id,
    c.name AS category_name
FROM product p
JOIN product_category pc
    ON pc.product_id = p.product_id
JOIN category c
    ON c.category_id = pc.category_id
WHERE p.product_id = 1
ORDER BY c.name;


-- 4. Find products containing a keyword.

SELECT
    product_id,
    sku,
    name,
    description
FROM product
WHERE MATCH(name, description)
      AGAINST('phone' IN NATURAL LANGUAGE MODE)
  AND is_active = TRUE;


-- 5. Find in-stock variants in a price range.

SELECT
    p.product_id,
    p.name,
    v.variant_id,
    v.variant_name,
    v.price,
    v.stock_quantity
FROM product p
JOIN variant v
    ON v.product_id = p.product_id
WHERE p.is_active = TRUE
  AND v.stock_quantity > 0
  AND v.price BETWEEN 100.00 AND 1000.00
ORDER BY v.price;


-- 6. Show zero-stock variants.

SELECT
    p.name,
    v.variant_name,
    v.stock_quantity
FROM product p
JOIN variant v
    ON v.product_id = p.product_id
WHERE v.stock_quantity = 0
ORDER BY p.name;


-- 7. Paginated catalogue example: page 1, 12 rows.

SELECT
    p.product_id,
    p.sku,
    p.name
FROM product p
WHERE p.is_active = TRUE
ORDER BY p.name
LIMIT 12 OFFSET 0;