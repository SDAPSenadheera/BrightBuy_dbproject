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
8. `05b_catalogue_variant_seed.sql`
9. `06_catalogue_procedures.sql`
10. `04_catalogue_queries.sql`
11. `07_catalogue_tests.sql`

The procedure installer (`06`) runs before the example calls in `04`, despite
their numeric filenames. It can be reinstalled without changing catalogue data;
it replaces one view and three routines. Install while application calls are paused.

Example using the MySQL CLI (replace the username if needed):

```sh
mysql -u root -p < 00_create_database.sql &&
for script in 01_catalogue_tables.sql 02_catalogue_indexes.sql \
    03_catalogue_seed_data.sql ../Inventory_Delivery_DDL.sql \
    ../Inventory_Delivery_sample_data.sql 05_variant_integration.sql \
    05b_catalogue_variant_seed.sql 06_catalogue_procedures.sql \
    04_catalogue_queries.sql 07_catalogue_tests.sql; do
    mysql -u root -p brightbuy < "$script" || break
done
```

`01` and `02` are one-time setup scripts, not migrations for existing tables.
Do not drop an existing database to apply them. The inventory DDL and sample
data are also one-time scripts. Catalogue seed (`03`) and integration (`05`)
can be rerun after successful setup. The seed reserves category IDs 1–10 and
product IDs 1–40 for these fixtures; run it against the agreed development data,
not arbitrary existing catalogue records. It restores products 1–39 to active,
keeps product 40 inactive and removes the four incorrect mappings from the
original placeholder seed.

The seed uses a transaction; after any error, roll it back or disconnect before
continuing. Integration uses DDL, which commits independently: it is not an
atomic migration. Run it while catalogue/inventory writes are paused. It checks
all existing variants, reuses a supporting index, rejects incompatible foreign
keys, sets `product_id` to `NOT NULL`, and creates the agreed foreign key.
If integration fails, correct the reported issue and rerun `05`; its helper
procedure is removed on success or replaced on the next run.

## Milestone 2 dataset and upgrade

The dataset contains **40 products, 10 categories, 80 category assignments and
48 variants**. Each product belongs to one child category and its root category.
All seven child categories contain products. The three original products and
five inventory variants keep their IDs and values. Products 4–40 are fictional
BrightBuy sample products; prices are demonstration values, not market quotes.

`05b_catalogue_variant_seed.sql` adds 43 variants for the 37 new products after
the inventory module has created its tables and warehouse data. It does not
create another variant table or modify inventory-owned files. Its reserved
variant IDs are **1004–1040, 1104, 1114, 1119, 1125, 1131 and 1136**; coordinate
that range with the inventory owner before merging shared sample data. It
reuses warehouses 1–3. Conflicting IDs or missing product/warehouse dependencies
raise an error and roll back all inserts. Existing matching variants retain
their price and stock on reruns; changing fixture values in the file will not
overwrite inventory updates.

For an existing milestone-1 development database, run only:

```sh
mysql -u root -p brightbuy < 03_catalogue_seed_data.sql &&
mysql -u root -p brightbuy < 05b_catalogue_variant_seed.sql &&
mysql -u root -p brightbuy < tests/test_foundation.sql
```

This assumes the milestone-1 schema and integration already succeeded. Do not
rerun catalogue or inventory table creation against that existing database.

Seven products offer multiple variant choices. Three variants have zero stock,
and product 40 is inactive, providing sample cases for the later frontend.
Product image URLs remain NULL until the frontend/image milestone. Fixtures
restore catalogue descriptions and activation flags on rerun, so use these
seed scripts for development/demo data only, with application writes paused.

## Milestone 3 procedures and queries

`06_catalogue_procedures.sql` installs three read-only procedures:

- `sp_catalogue_categories`: visible categories and distinct active product counts.
- `sp_catalogue_search`: keyword/category/price/stock filters, five sort modes,
  one product per result, and page metadata with deterministic ordering.
- `sp_catalogue_product_detail`: active product information, visible categories,
  and ordered variants including out-of-stock choices.

Each procedure returns a JSON value through an OUT parameter. This gives the
future Spring Boot catalogue API one documented response to consume and allows
SQL-only tests to inspect the actual results. Their common
`catalogue_public_variants` view excludes inactive products and invalid inventory
price/stock rows. No routine writes rows, starts/commits transactions, or handles
checkout. See [PROCEDURES.md](PROCEDURES.md) for signatures, defaults, response
fields, error states and category/price/search semantics.

To upgrade an existing milestone-2 development database, install `06` and run
the two test suites. Do not recreate tables or rerun inventory seeds:

```sh
mysql -u root -p brightbuy < 06_catalogue_procedures.sql &&
mysql -u root -p brightbuy < tests/test_procedures.sql &&
mysql -u root -p brightbuy < tests/test_foundation.sql
```

`04_catalogue_queries.sql` retains the seven illustrative SQL queries, improves
their visibility checks and sorting, and adds four runnable procedure examples.

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
- [x] Forty products
- [x] Ten categories seeded
- [x] Correct mappings for the three initial products
- [x] Mappings for the full forty-product catalogue
- [x] At least one variant per product; 43 additional catalogue fixtures
- [x] Variant foreign key and non-null product reference
- [x] Catalogue read queries
- [x] Catalogue read procedures (categories, search and product detail)
- [x] Catalogue SQL tests
- [ ] Verification on the team's exact MySQL version
- [ ] Backend/frontend integration verification

## Database validation

`tests/test_foundation.sql` runs entirely in MySQL; no Python is required.
Complete the setup sequence above on a **disposable test database** first.
The test script uses the existing `brightbuy` database and requires the complete
milestone-2 fixtures with their initial prices and stock. It does not create a database
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

Milestone 1 originally passed 23 SQL assertions. Milestone 2 extends the suite
to **32 assertions**, adding full dataset coverage, matching child/root mappings,
activation states, inventory fixture preservation, valid price/stock values,
out-of-stock fixtures and multiple variant choices. Additional rerun and
collision checks are described in `tests/README.md`.

Validated on 2026-09-19 using isolated MySQL **9.7.1** instances with
`lower_case_table_names=1`: all 32 assertions passed for both an upgrade from
milestone 1 and a fresh installation. Seed reruns, preservation of changed
variant price/stock, and rejection of a conflicting variant ID without partial
inserts also passed. Inventory SQL files were executed unchanged.

The read procedures are implemented in milestone 3. Milestone 4 adds Spring Boot
APIs for categories, product search and product details; setup and HTTP contracts
are documented in [Backend/CATALOGUE_API.md](../../Backend/CATALOGUE_API.md).
Frontend pages remain for the next milestone. Tests use sequential hierarchy edits;
concurrent category reparenting is not covered by this milestone.

Milestone 3 validation on isolated MySQL **9.7.1**: **65 procedure assertions
and 32 foundation assertions passed** (97 total), as did reinstalling `06` and
executing all eleven examples in `04`. Procedure tests rolled back their row
changes; the foundation suite confirmed the original fixtures afterward.

Milestone 4 backend validation: **67 tests passed**, including four live
HTTP-to-MySQL tests against the isolated MySQL 9.7.1 fixtures using a restricted
database account. The Spring Boot application packaged successfully. See the
backend guide above for the required database profile and test setup.

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
