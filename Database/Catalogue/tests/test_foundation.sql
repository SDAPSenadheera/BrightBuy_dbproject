-- Catalogue foundation regression tests (MySQL 8.0.19+).
-- Run AFTER the README setup sequence on a disposable test database only.
-- Requires the milestone-1 fixtures: 3 products, 10 categories, 5 variants.
-- Outputs PASS per assertion; unexpected results raise SQLSTATE 45000.
-- Test row changes are rolled back on success and on failure. DDL for these
-- helper routines commits independently; AUTO_INCREMENT gaps may remain.
-- Use a dedicated connection, with no pending application transaction.

USE brightbuy;

DROP PROCEDURE IF EXISTS catalogue_test_assert;
DROP PROCEDURE IF EXISTS catalogue_test_reject;
DROP PROCEDURE IF EXISTS catalogue_test_foundation;

DELIMITER $$

CREATE PROCEDURE catalogue_test_assert(IN condition_ok BOOLEAN, IN test_name VARCHAR(100))
BEGIN
    DECLARE failure_message VARCHAR(128);
    IF condition_ok IS NULL OR condition_ok = FALSE THEN
        SET failure_message = CONCAT('FAIL: ', test_name);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = failure_message;
    END IF;
    SET @catalogue_test_passed = @catalogue_test_passed + 1;
    SELECT CONCAT('PASS: ', test_name) AS result;
END$$

-- Catch only the statement being tested, then assert outside its handler.
-- Both error number and message are checked for custom hierarchy errors.
CREATE PROCEDURE catalogue_test_reject(
    IN statement_text TEXT,
    IN expected_errno INT,
    IN expected_message VARCHAR(128),
    IN test_name VARCHAR(100)
)
BEGIN
    DECLARE actual_errno INT DEFAULT 0;
    DECLARE actual_message TEXT DEFAULT '';
    SET @catalogue_test_sql = statement_text;
    PREPARE catalogue_test_statement FROM @catalogue_test_sql;
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
            GET DIAGNOSTICS CONDITION 1
                actual_errno = MYSQL_ERRNO, actual_message = MESSAGE_TEXT;
        EXECUTE catalogue_test_statement;
    END;
    DEALLOCATE PREPARE catalogue_test_statement;
    CALL catalogue_test_assert(
        actual_errno = expected_errno
        AND (expected_message IS NULL OR actual_message = expected_message), test_name
    );
END$$

CREATE PROCEDURE catalogue_test_foundation()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET @catalogue_test_passed = 0;
    START TRANSACTION;

    CALL catalogue_test_assert(
        (SELECT COUNT(*) FROM product) = 3
        AND (SELECT COUNT(*) FROM category) = 10
        AND (SELECT COUNT(*) FROM variant) = 5, 'milestone-1 fixture counts');

    CALL catalogue_test_assert(
        (SELECT GROUP_CONCAT(CONCAT(product_id, ':', category_id)
                ORDER BY product_id, category_id) FROM product_category)
        = '1:1,1:4,2:1,2:4,3:1,3:5', 'correct product-category mappings');

    CALL catalogue_test_assert(
        (SELECT COUNT(*) FROM information_schema.key_column_usage
         WHERE constraint_schema = DATABASE() AND table_name = 'variant'
           AND column_name = 'product_id' AND referenced_table_schema = DATABASE()
           AND referenced_table_name = 'product' AND referenced_column_name = 'product_id') = 1,
        'one variant-product foreign key');

    CALL catalogue_test_assert(
        (SELECT COUNT(*) FROM information_schema.referential_constraints
         WHERE constraint_schema = DATABASE() AND table_name = 'variant'
           AND constraint_name = 'fk_variant_product'
           AND update_rule = 'CASCADE' AND delete_rule = 'RESTRICT') = 1,
        'foreign-key update/delete actions');

    CALL catalogue_test_assert(
        (SELECT COUNT(*) FROM information_schema.statistics
         WHERE table_schema = DATABASE() AND table_name = 'variant'
           AND column_name = 'product_id' AND seq_in_index = 1) = 1,
        'one supporting variant-product index');

    CALL catalogue_test_assert(
        (SELECT COUNT(*) FROM information_schema.routines
         WHERE routine_schema = DATABASE()
           AND routine_name = 'apply_variant_product_integration') = 0,
        'integration helper removed');

    CALL catalogue_test_reject(
        'INSERT INTO category(category_id,parent_category_id,name) VALUES(101,101,''Self parent'')',
        1644, 'A category cannot be its own parent', 'self-parent insert');
    CALL catalogue_test_reject(
        'UPDATE category SET parent_category_id=category_id WHERE category_id=4',
        1644, 'A category cannot be its own parent', 'self-parent update');
    CALL catalogue_test_reject(
        'INSERT INTO category(parent_category_id,name) VALUES(4,''Grandchild'')',
        1644, 'Category hierarchy is limited to two levels', 'grandchild insert');
    CALL catalogue_test_reject(
        'UPDATE category SET parent_category_id=4 WHERE category_id=5',
        1644, 'Category hierarchy is limited to two levels', 'grandchild update');
    CALL catalogue_test_reject(
        'UPDATE category SET parent_category_id=2 WHERE category_id=1',
        1644, 'A category with children cannot become a child category', 'root with children cannot become child');
    CALL catalogue_test_reject(
        'INSERT INTO category(parent_category_id,name) VALUES(99999,''Missing'')',
        1452, NULL, 'missing parent');
    CALL catalogue_test_reject(
        'INSERT INTO product(sku,name) VALUES(''IPHONE-15-PRO'',''Duplicate'')',
        1062, NULL, 'duplicate SKU');
    CALL catalogue_test_reject(
        'INSERT INTO product_category(product_id,category_id) VALUES(1,4)',
        1062, NULL, 'duplicate category assignment');
    CALL catalogue_test_reject(
        'INSERT INTO variant(variant_id,product_id) VALUES(99999,99999)',
        1452, NULL, 'orphan variant insert');
    CALL catalogue_test_reject(
        'INSERT INTO variant(variant_id,product_id) VALUES(99999,NULL)',
        1048, NULL, 'null variant insert');
    CALL catalogue_test_reject(
        'DELETE FROM product WHERE product_id=1',
        1451, NULL, 'referenced product deletion');
    CALL catalogue_test_reject(
        'DELETE FROM category WHERE category_id=4',
        1451, NULL, 'assigned category deletion');

    SAVEPOINT before_cascade;
    UPDATE product SET product_id = 101 WHERE product_id = 1;
    CALL catalogue_test_assert(
        (SELECT COUNT(*) FROM variant WHERE product_id = 101) = 3
        AND (SELECT COUNT(*) FROM product_category WHERE product_id = 101) = 2,
        'product ID updates cascade');
    ROLLBACK TO SAVEPOINT before_cascade;

    UPDATE category SET parent_category_id = 2 WHERE category_id = 5;
    CALL catalogue_test_assert(
        (SELECT parent_category_id FROM category WHERE category_id = 5) = 2, 'valid reparenting');

    CALL catalogue_test_assert(
        (SELECT COUNT(*) FROM product WHERE MATCH(name, description) AGAINST('headphones')) = 1,
        'full-text index works');
    CALL catalogue_test_assert(
        (SELECT COUNT(*) FROM product p WHERE NOT EXISTS
            (SELECT 1 FROM product_category pc WHERE pc.product_id = p.product_id)
         OR NOT EXISTS (SELECT 1 FROM variant v WHERE v.product_id = p.product_id)) = 0,
        'every seeded product has a category and variant');
    CALL catalogue_test_assert(
        (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE()
         AND ((table_name = 'category' AND column_name = 'parent_category_id')
           OR (table_name = 'product_category' AND column_name = 'category_id'))
         AND seq_in_index = 1) = 2, 'no redundant catalogue FK indexes');

    ROLLBACK;
    SELECT CONCAT('PASS: ', @catalogue_test_passed, ' foundation assertions; test row changes rolled back.') AS summary;
END$$

DELIMITER ;

CALL catalogue_test_foundation();

DROP PROCEDURE catalogue_test_foundation;
DROP PROCEDURE catalogue_test_reject;
DROP PROCEDURE catalogue_test_assert;
SET @catalogue_test_sql = NULL;
SET @catalogue_test_passed = NULL;
