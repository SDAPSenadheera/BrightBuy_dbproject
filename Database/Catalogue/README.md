# BrightBuy Catalogue Database Module

## Owner

Kavindu Mihisara

## Purpose

This module implements the product catalogue using raw SQL. It requires MySQL
8.0.19 or later.

## Tables Owned

- `product`
- `category`
- `product_category`

The inventory module currently defines the shared `variant` table. This module
adds its product foreign key and requires `variant.product_id` to be non-null.
Catalogue reads variants; inventory manages stock. Keep one shared definition.

## Naming Contract

The reporting module requires these exact names:

- `product.product_id`
- `product.name`
- `category.category_id`
- `category.name`
- `product_category.product_id`
- `product_category.category_id`

## Execution Order

For a fresh database, run the scripts below from `Database/Catalogue`.
Select `brightbuy` explicitly when executing the inventory scripts, which do
not contain their own `USE` statement. Use a client that stops on the first
error; do not use `--force` or blindly continue after a failed script.

1. `00_create_database.sql`
2. `01_catalogue_tables.sql`
3. `02_catalogue_indexes.sql`
4. `03_catalogue_seed_data.sql`
5. `../Inventory_Delivery_DDL.sql`
6. `../Inventory_Delivery_sample_data.sql`
7. `05_variant_integration.sql`
8. `04_catalogue_queries.sql`
9. `07_catalogue_tests.sql`

`06_catalogue_procedures.sql` is currently empty and is reserved for the next
database milestone. Once implemented, run it before queries and tests that
depend on those procedures.

Example using the MySQL CLI (replace the username if needed):

```sh
mysql -u root -p < 00_create_database.sql &&
for script in 01_catalogue_tables.sql 02_catalogue_indexes.sql \
    03_catalogue_seed_data.sql ../Inventory_Delivery_DDL.sql \
    ../Inventory_Delivery_sample_data.sql 05_variant_integration.sql \
    04_catalogue_queries.sql 07_catalogue_tests.sql; do
    mysql -u root -p brightbuy < "$script" || break
done
```

`01` and `02` are one-time setup scripts, not migrations for existing tables.
Do not drop an existing database to apply them. The inventory DDL and sample
data are also one-time scripts. Catalogue seed (`03`) and integration (`05`)
can be rerun after successful setup. The seed reserves category IDs 1–10 and
product IDs 1–3 for these fixtures; run it against the agreed development data,
not arbitrary existing catalogue records. It restores these fixtures to active
and removes the four incorrect mappings from the original placeholder seed.

The seed uses a transaction; after any error, roll it back or disconnect before
continuing. Integration uses DDL, which commits independently: it is not an
atomic migration. Run it while catalogue/inventory writes are paused. It checks
all existing variants, reuses a supporting index, rejects incompatible foreign
keys, sets `product_id` to `NOT NULL`, and creates the agreed foreign key.
If integration fails, correct the reported issue and rerun `05`; its helper
procedure is removed on success or replaced on the next run.

## Business Rules

- SKU is unique at product level.
- Price and stock belong to variants.
- Products may belong to multiple categories.
- Categories support a two-level hierarchy.
- Products referenced by variants cannot be physically deleted.
- Inactive products are hidden using `is_active`.
- Every final product must have at least one category and variant.

## Current Progress

- [x] Database initialization
- [x] Catalogue tables
- [x] Catalogue indexes
- [ ] Forty products
- [x] Ten categories seeded
- [x] Correct mappings for the three initial products
- [ ] Mappings for the full forty-product catalogue
- [x] Variant foreign key and non-null product reference
- [ ] Catalogue queries
- [ ] Catalogue procedures
- [ ] Catalogue tests
- [ ] Integration verification

## Milestone 1 validation

`tests/test_foundation.sql` runs entirely in MySQL; no Python is required.
Complete the setup sequence above on a **disposable test database** first.
The test script uses the existing `brightbuy` database and requires the initial
three-product fixtures. Unlike the old runner, it does not create a database
or execute the setup files automatically. Never run it on a shared or production
database. Use a dedicated connection without pending work.

```sh
mysql --socket=/path/to/disposable/mysql.sock -u root -p < tests/test_foundation.sql
```

You can also open and execute the complete file in MySQL Workbench, connected
to that test instance. Each assertion prints `PASS`; an unexpected result
raises an error beginning with `FAIL`. The script rolls back test row changes
on success or failure and removes its helper procedures on success. If it
fails, stop and inspect the error; helpers are replaced on the next run.
Auto-increment gaps and helper-routine DDL are not rolled back.

The SQL suite checks fixture counts/mappings, foreign-key metadata and actions,
self-parenting, hierarchy depth, invalid references, duplicate SKUs/assignments,
null variant products, delete restrictions, cascading product ID updates, valid
reparenting and full-text search. Setup, rerun, mapping-repair and pre-integration
failure checks are documented separately in [tests/README.md](tests/README.md).
MySQL 8.0.19+ is the intended syntax target; execution on the team's exact
MySQL 8 version remains to be verified.

Replacement SQL suite validated on 2026-09-19 against the isolated MySQL
9.7.1 instance (`lower_case_table_names=1`): **23 assertions passed**. The
additional manual integration failure scenarios were previously validated
during milestone 1; they are now supplied as SQL instructions instead of a
Python runner.

This checkpoint covers three products, ten categories and five existing
inventory variants. It does not complete the forty-product dataset, catalogue
procedures, backend APIs, or frontend pages. Tests use sequential hierarchy
edits; concurrent category reparenting is not covered by this milestone.

## Known External Issues

The inventory DDL creates lowercase `warehouse` and `city` tables but references
uppercase `WAREHOUSE` and `CITY`. On servers with `lower_case_table_names=0`
(commonly Linux), that script can fail. The test instance used case-insensitive
table names. Coordinate a casing correction with the inventory owner before
deploying to a case-sensitive server; do not change server settings on an
existing database to work around it. No inventory file was edited here.

The reporting queries contain typographical and alias errors. Those files are
owned by the reporting member and are not modified by this module.

The reporting access log depends on an `employee` table that has not yet been
created.
