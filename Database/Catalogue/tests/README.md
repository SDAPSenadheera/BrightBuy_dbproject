# Catalogue SQL tests

Use a disposable MySQL instance only. These tests are for the milestone-1
fixtures: three products, ten categories and five inventory variants. No Python
or application backend is required. Do not change the team's shared database.

## Automated foundation assertions

Follow the parent README's setup order, then execute `test_foundation.sql` in
MySQL Workbench, or from `Database/Catalogue` using the MySQL CLI:

```sh
mysql --socket=/path/to/disposable/mysql.sock -u root -p < tests/test_foundation.sql
```

Expect a `PASS` result for each check and a final count. `FAIL` or another SQL
error means the suite did not pass. It rolls back row changes even on failure.
The file creates and removes test-only stored procedures; those are unrelated
to the future catalogue business procedures in `06_catalogue_procedures.sql`.

## Seed and integration reruns

After a successful fresh setup, execute `03_catalogue_seed_data.sql` twice and
`05_variant_integration.sql` twice, then run `tests/test_foundation.sql` again.
It must still pass, with three products, ten categories, five variants and six
assignments, one variant-product foreign key and one supporting index.

To check repair of the previous placeholder mappings, first run:

```sql
USE brightbuy;
INSERT INTO product_category (product_id, category_id)
VALUES (2,2), (2,7), (3,3), (3,9), (1,6);
```

Execute `03_catalogue_seed_data.sql`, then check:

```sql
SELECT product_id, category_id
FROM product_category ORDER BY product_id, category_id;
-- Expect: (1,1), (1,4), (1,6), (2,1), (2,4), (3,1), (3,5).
-- The unrelated (1,6) mapping must survive; the four old mappings must disappear.

DELETE FROM product_category WHERE product_id=1 AND category_id=6;
```

The DELETE removes only the extra fixture added above. Run the automated suite
again after removing it.

## Pre-integration failure checks

On a separate fresh disposable instance, run setup through the inventory seed
(steps 1–6 in the parent README). Do NOT run `05_variant_integration.sql` yet.
Run each case below separately and inspect the expected error before proceeding.

1. Insert a null product reference:

   ```sql
   USE brightbuy;
   INSERT INTO variant (variant_id, product_id) VALUES (99999, NULL);
   ```

   Execute `05_variant_integration.sql`. Expect an error containing
   `orphaned or NULL product_id values exist`. Then inspect:

   ```sql
   SELECT COUNT(*) AS product_index_entries
   FROM information_schema.statistics
   WHERE table_schema='brightbuy' AND table_name='variant' AND column_name='product_id';
   -- Expect 0: integration must stop before creating the index.
   DELETE FROM variant WHERE variant_id=99999;
   ```

2. Repeat case 1 with `(99999, 99999)` instead of `(99999, NULL)`.
   Expect the same error and zero index entries; remove variant 99999 afterward.

3. Create an incompatible foreign key:

   ```sql
   ALTER TABLE variant ADD CONSTRAINT test_wrong_fk
       FOREIGN KEY (product_id) REFERENCES product(product_id) ON DELETE CASCADE;
   ```

   Execute `05_variant_integration.sql`. Expect an error containing
   `conflicting product foreign key`. Then inspect and remove the test constraint:

   ```sql
   SELECT is_nullable FROM information_schema.columns
   WHERE table_schema='brightbuy' AND table_name='variant' AND column_name='product_id';
   -- Expect YES: integration must not modify the column after detecting conflict.
   ALTER TABLE variant DROP FOREIGN KEY test_wrong_fk, DROP INDEX test_wrong_fk;
   ```

Finally, execute `05_variant_integration.sql` successfully twice, then run
`tests/test_foundation.sql`. No inventory source files need to be modified.
