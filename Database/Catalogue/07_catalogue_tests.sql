USE brightbuy;


-- Test 1: Confirm products and categories exist.

SELECT COUNT(*) AS product_count
FROM product;

SELECT COUNT(*) AS category_count
FROM category;


-- Test 2: Check for products without a category.

SELECT
    p.product_id,
    p.name
FROM product p
LEFT JOIN product_category pc
    ON pc.product_id = p.product_id
WHERE pc.product_id IS NULL;


-- Expected result for the final database: zero rows.


-- Test 3: Check for orphaned variants.

SELECT
    v.variant_id,
    v.product_id
FROM variant v
LEFT JOIN product p
    ON p.product_id = v.product_id
WHERE p.product_id IS NULL;


-- Expected result: zero rows.


-- Test 4: Check for duplicate SKUs.

SELECT
    sku,
    COUNT(*) AS occurrence_count
FROM product
GROUP BY sku
HAVING COUNT(*) > 1;


-- Expected result: zero rows.


-- Test 5: Check product-category assignments.

SELECT
    p.name AS product_name,
    c.name AS category_name
FROM product_category pc
JOIN product p
    ON p.product_id = pc.product_id
JOIN category c
    ON c.category_id = pc.category_id
ORDER BY p.name, c.name;