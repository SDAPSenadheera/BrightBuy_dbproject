USE brightbuy;


-- Test 1: Confirm products and categories exist.

SELECT COUNT(*) AS product_count
FROM product;

SELECT COUNT(*) AS category_count
FROM category;

SELECT COUNT(*) AS variant_count FROM variant;
SELECT COUNT(*) AS assignment_count FROM product_category;
-- Milestone-2 fixture counts: 40 products, 10 categories, 48 variants, 80 assignments.


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


-- Test 6: Every product needs at least one variant. Expected: zero rows.
SELECT p.product_id, p.name
FROM product p
WHERE NOT EXISTS (SELECT 1 FROM variant v WHERE v.product_id = p.product_id);

-- Test 7: Every child category has products. Expected: zero rows.
SELECT c.category_id, c.name
FROM category c
WHERE c.parent_category_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM product_category pc WHERE pc.category_id = c.category_id);

-- Test 8: Sample visibility states. Expected: 39 active, 1 inactive.
SELECT is_active, COUNT(*) AS product_count FROM product GROUP BY is_active;
