-- =========================================================
-- BrightBuy Catalogue Queries
-- Author: Kavindu Mihisara
-- Install 06_catalogue_procedures.sql BEFORE running these examples.
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
ORDER BY p.name, p.product_id, v.price, v.variant_id;


-- 2. Browse products belonging to one category.
-- Replace 4 with the requested category ID.

SELECT DISTINCT
    p.product_id,
    p.sku,
    p.name
FROM product p
JOIN product_category pc
    ON pc.product_id = p.product_id
JOIN category c ON c.category_id = pc.category_id
LEFT JOIN category parent ON parent.category_id = c.parent_category_id
WHERE pc.category_id = 4
  AND p.is_active = TRUE
  AND c.is_active = TRUE
  AND (c.parent_category_id IS NULL OR parent.is_active = TRUE)
ORDER BY p.name, p.product_id;


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
  AND p.is_active = TRUE
  AND c.is_active = TRUE
  AND (c.parent_category_id IS NULL OR EXISTS (
      SELECT 1 FROM category parent
      WHERE parent.category_id = c.parent_category_id AND parent.is_active = TRUE
  ))
ORDER BY c.name, c.category_id;


-- 4. Find products containing a keyword.

SELECT
    product_id,
    sku,
    name,
    description
FROM product
WHERE (MATCH(name, description) AGAINST('phone' IN NATURAL LANGUAGE MODE)
       OR LOCATE('phone', name) > 0
       OR LOCATE('phone', COALESCE(description, '')) > 0
       OR LOCATE('phone', sku) > 0)
  AND is_active = TRUE
ORDER BY name, product_id;


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
ORDER BY v.price, p.product_id, v.variant_id;


-- 6. Show zero-stock variants.

SELECT
    p.name,
    v.variant_name,
    v.stock_quantity
FROM product p
JOIN variant v
    ON v.product_id = p.product_id
WHERE v.stock_quantity = 0
  AND p.is_active = TRUE
ORDER BY p.name, p.product_id, v.variant_id;


-- 7. Paginated catalogue example: page 1, 12 rows.

SELECT
    p.product_id,
    p.sku,
    p.name
FROM product p
WHERE p.is_active = TRUE
ORDER BY p.name, p.product_id
LIMIT 12 OFFSET 0;


-- 8. Storefront categories with distinct active product counts.
CALL sp_catalogue_categories(@categories);
SELECT JSON_PRETTY(@categories) AS categories;

-- 9. Full catalogue, page 1. The result includes total_products/total_pages.
-- Parameters: keyword, category, min_price, max_price, in_stock_only,
--             sort, page, page_size, OUT result.
CALL sp_catalogue_search(NULL, NULL, NULL, NULL, 0, 'name_asc', 1, 12, @products);
SELECT JSON_PRETTY(@products) AS product_page;

-- 10. In-stock phones matching the price range, lowest matching price first.
-- A root category also includes active child-category assignments.
CALL sp_catalogue_search('phone', 4, 100.00, 1000.00, 1, 'price_asc', 1, 12, @products);
SELECT JSON_PRETTY(@products) AS filtered_product_page;

-- 11. Product detail with all valid variants (including zero-stock choices).
-- Unknown/inactive IDs raise SQLSTATE 45004; invalid input raises 45000.
CALL sp_catalogue_product_detail(1, @product_detail);
SELECT JSON_PRETTY(@product_detail) AS product_detail;
