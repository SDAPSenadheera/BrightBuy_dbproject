# Isolated MySQL 8 catalogue validation

## Recorded result — 2026-09-26

Tested repository commit `eed1131` using the official `mysql:8.0` image,
resolved to MySQL Community Server **8.0.46**, Linux ARM64:

```text
mysql@sha256:7dcddc01f13bab2f15cde676d44d01f61fc9f99fe7785e86196dfc07d358ae2b
```

- Fresh catalogue-only setup: **32 foundation + 65 procedure assertions passed**.
- Repeated `03`, `05`, `05b` and `06` twice: all **97 assertions passed again**.
- `04_catalogue_queries.sql` and `07_catalogue_tests.sql` executed without errors.
- Final counts: 40 products, 10 categories, 80 assignments, 48 variants.
- The prerequisite diagnostic executed successfully and correctly reported
  missing `orders`/`delivery` tables and columns as `BLOCK`.
- No catalogue SQL fixes or teammate-file edits were needed.

This is **not full-project installation verification**. Only the city,
warehouse and variant INSERT statements from the shared seed were used; its
delivery INSERT was deliberately excluded. No replacement checkout/auth tables
were invented. The inventory DDL was executed unchanged using
`lower_case_table_names=1`, set when this new test instance was initialized.
The inventory owner's uppercase `WAREHOUSE` reference remains unresolved for
case-sensitive servers. This run does not verify `lower_case_table_names=0`,
every MySQL 8 release, the team's still-unconfirmed exact version, or HTTP/UI
integration. Manual collision and pre-integration failure scenarios from the
test README were not rerun in this milestone.

## Existing container

Container name: `brightbuy-catalogue-mysql8`.

It has its own newly created Docker-managed anonymous data volume, no repository
mounts, no published ports and `--network none`. The host's Homebrew MySQL and
existing databases are not used. It is limited to 1 GiB RAM and two CPUs.
The test root account has an empty password; keep this disposable container
network-isolated and never reuse these settings for shared/production data.

Open its SQL prompt:

```sh
docker exec -it brightbuy-catalogue-mysql8 mysql --protocol=socket -u root brightbuy
```

Stop it when not testing, then start it again when needed. These commands retain
the test data; the container has no automatic restart policy:

```sh
docker stop brightbuy-catalogue-mysql8
docker start brightbuy-catalogue-mysql8
```

## Reproduce on a new container only

Run from the repository root with Docker Desktop running. Do not run the
creation/setup steps against the already-populated container. Docker will
reject creation if the name already exists; do not delete an existing container
just to run this recipe.

```sh
docker run --detach --name brightbuy-catalogue-mysql8 \
  --network none --memory 1g --cpus 2 \
  --label com.brightbuy.purpose=catalogue-mysql8-test \
  --env MYSQL_ALLOW_EMPTY_PASSWORD=yes \
  mysql@sha256:7dcddc01f13bab2f15cde676d44d01f61fc9f99fe7785e86196dfc07d358ae2b \
  --lower-case-table-names=1 --mysqlx=OFF
```

Initialization takes time. Before proceeding, retry this read-only check until
it succeeds and reports the expected version and case mode:

```sh
docker exec brightbuy-catalogue-mysql8 mysql --protocol=socket -u root \
  -e 'SELECT VERSION(), @@lower_case_table_names;'
```

For this **catalogue-only harness**, load the shared inventory DDL unchanged and
stream only the seed prefix preceding `INSERT INTO delivery`. This extraction
matches the shared file at the tested commit; inspect the file if it changes.
The source file is not edited. This is not a substitute for the complete shared
seed or its checkout prerequisites in a full-project installation.

```sh
(
set -e
set -o pipefail
for script in 00_create_database.sql 01_catalogue_tables.sql \
    02_catalogue_indexes.sql 03_catalogue_seed_data.sql; do
  docker exec -i brightbuy-catalogue-mysql8 mysql --protocol=socket -u root \
    < "Database/Catalogue/$script"
done
docker exec -i brightbuy-catalogue-mysql8 mysql --protocol=socket -u root brightbuy \
  < 'Database/Inventory & Delivery/Inventory_Delivery_DDL.sql'
sed '/^INSERT INTO delivery /,$d' \
  'Database/Inventory & Delivery/Inventory_Delivery_sample_data.sql' \
  | docker exec -i brightbuy-catalogue-mysql8 mysql --protocol=socket -u root brightbuy
for script in 05_variant_integration.sql 05b_catalogue_variant_seed.sql \
    06_catalogue_procedures.sql tests/test_foundation.sql tests/test_procedures.sql; do
  docker exec -i brightbuy-catalogue-mysql8 mysql --protocol=socket -u root \
    < "Database/Catalogue/$script"
done
)
```

Expect final summaries of 32 and 65 passing assertions. Stop on any SQL error;
do not use `--force`. Tests roll back row changes, but helper-routine DDL and
auto-increment gaps are not rolled back. Use this disposable instance only.

## Repeatability check on the prepared container

The following intentionally reruns catalogue seeds against these disposable
fixtures, then reruns both suites and the examples. It does not rerun the
one-time table creation or shared inventory seeds.

```sh
(
set -e
for round in 1 2; do
  for script in 03_catalogue_seed_data.sql 05_variant_integration.sql \
      05b_catalogue_variant_seed.sql 06_catalogue_procedures.sql; do
    docker exec -i brightbuy-catalogue-mysql8 mysql --protocol=socket -u root \
      < "Database/Catalogue/$script"
  done
done
for script in tests/test_foundation.sql tests/test_procedures.sql \
    tests/check_setup_prerequisites.sql 04_catalogue_queries.sql 07_catalogue_tests.sql; do
  docker exec -i brightbuy-catalogue-mysql8 mysql --protocol=socket -u root \
    < "Database/Catalogue/$script"
done
)
```

The diagnostic's missing-checkout `BLOCK` rows are expected in this limited
harness. They still mean that full-project setup is not ready; a successful
client exit code is not an all-clear from the diagnostic.
