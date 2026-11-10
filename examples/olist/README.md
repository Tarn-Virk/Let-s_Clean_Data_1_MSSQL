# Olist worked example

* `dataset_cards.md` - format, keys and findings for all 9 files (measured on the files).
* `sql/` - the exact scripts that ran in the original build, with only the folder path changed to `C:\bsg-playbook\`. They are hard-coded to Olist table names; the generic versions are in the top-level `sql/` folder.

## Replay order (orders, customers, order_items)
| # | Script | What it does |
|---|---|---|
| 1 | `sql/0_setup/0.1_create_database.sql`, `0.2_create_schemas.sql`, `0.3_check_file_access.sql` (framework folder) | database, schemas, file access |
| 2 | `sql/3.4_create_raw_orders_manual.sql` | raw.orders by hand |
| 3 | `sql/3.5_error_test_tested.sql` | prove the reject-file safety net |
| 4 | `sql/3.6a_load_orders_sample.sql`, then `sql/3.7a_check_sample_landed.sql` | sample load and check |
| 5 | `sql/3.6b_load_orders_full.sql`, then `sql/3.8_orders_table_ready.sql` | full load: 99,441 rows |
| 6 | `sql/3.6c_create_and_load_customers.sql`, `sql/3.6d_create_and_load_order_items.sql` | the other two tables: 99,441 and 112,650 rows |
| 7 | framework `sql/4_profile/*` and `sql/5_validate/*` with the Olist CONFIG values, plus `sql/4.1c_profile_customers.sql` | profile and validate |
| 8 | `sql/5.8_order_items_tests.sql` | order_items tests |
| 9 | `sql/6.1_clean_orders_ddl.sql`, `6.2_clean_orders_load.sql`, `6.3_clean_orders_retest.sql`, `6.4_clean_customers.sql`, `6.5_clean_order_items.sql` | clean layer |
| 10 | `sql/7.1_indexes.sql` | indexes |
| 11 | `sql/8.1_gold_order_summary.sql` | gold, one row per order |
| 12 | `sql/10.1_health_check.sql` | 12 checks, expect **PIPELINE HEALTHY** |

(All names in rows 2-12 are in `examples/olist/sql/`.)
