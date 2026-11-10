# Phase 6 - Sanitize: build the clean layer

Goal: `clean.<table>` has real types, trimmed text, blanks as NULL, guard-rails (NOT NULL, primary key), and reason-code flags. Same number of rows as raw. Everything is rebuilt from raw by script; raw is never touched.

## 6.1 Choose the column map and build the table
1. **6.1a** `sql/6_sanitize/6.1a_suggest_column_map.sql` (set `@raw_schema`, `@raw_table`). It scans the table and fills the global temp table `##column_map` (target name, type, NULL/NOT NULL, blank count, max length, evidence kind). Read every row of the grid and agree with it.
2. **Override** where your Phase 4/5 knowledge says otherwise, in the same query window, e.g.:
```sql
UPDATE ##column_map SET target_type = 'DECIMAL(10,2)' WHERE column_name = 'price';
UPDATE ##column_map SET target_name = 'purchase_ts'  WHERE column_name = 'order_purchase_timestamp';
UPDATE ##column_map SET nullability = 'NOT NULL'      WHERE column_name = 'order_id';
```
   This is the **rename map**: `column_name` (raw) -> `target_name` (clean). Keep the grid in the dataset card.
3. **6.1b** `6.1b_generate_clean_table_and_load.sql` (set raw/clean names, `@pk_cols` = key from 5.2 using clean names, `@execute = 0`). It prints the generated `CREATE TABLE`, the typed `INSERT ... SELECT` (trim, blank to NULL, `TRY_CAST`) and a silent-loss test. Read them.
4. Set `@execute = 1` and run. It rebuilds the clean table and reconciles: `rows_raw = rows_clean`, and for every column non-blank values in raw must equal non-NULL values in clean. A `FAIL` names the column: a value did not convert. Fix the type, or add a cleaning rule, and re-run. Nothing may disappear silently.
   Note: `##column_map` is a *global temp table*: it lives only as long as your SSMS connection. Run 6.1a and 6.1b in the same window; if you close it, re-run 6.1a (and your overrides).

## 6.2 Add reason-code flags for rows that break a rule
Use `sql/6_sanitize/6.2_reason_code_flags_template.sql` and the finished example `examples/olist/sql/6.2_clean_orders_load.sql`:
1. Add a column `<issue_codes> NVARCHAR(200) NULL` to the clean table.
2. Put each Phase 5 rule in a `CASE WHEN <rule broken> THEN '<CODE>' END` inside `CONCAT_WS(';', ...)` wrapped by `NULLIF(..., '')`, so a clean row has NULL and a broken row has `CODE_A;CODE_B`.
3. Re-load. Do not `DELETE` rows.

## 6.3 Other cleaning (only what the profile justified)
| Need | Technique |
|---|---|
| Trim, case | `LTRIM(RTRIM(x))`, `LOWER`/`UPPER` (decided per column and logged) |
| Spelling variants | map table or `CASE`; log every merge |
| Duplicates | `ROW_NUMBER() OVER (PARTITION BY <key> ORDER BY <deterministic column>)`, keep 1, and **write the dropped rows to a quarantine table** with a reason code (technique from the playbook; this repo has no ready script for it, so write it in the 5.8/6.x style) |
| Dates | `TRY_CAST(... AS DATETIME2(0))` or `DATE`; timezone only if the source says it differs |
| NULL strategy | per column: leave NULL, default, impute, or add a flag column. Decision from Phase 5 |
| Hidden characters | `REPLACE(x, CHAR(9), ' ')` etc., only if 4.5 found them |

## 6.4 Re-test (the exit test)
1. Re-run the Phase 5 tests with `@schema = 'clean'` where they apply (uniqueness 5.2, referential integrity 5.7, ordering/consistency rules rewritten for typed columns).
2. Compare flag counts with the expected counts: see `examples/olist/sql/6.3_clean_orders_retest.sql` (expected 166 / 1359 / 61 / 23 / 14 / 2 / 8, all PASS).
3. `rows_raw = rows_clean` and no silent loss.

## Done when
Every FAIL from Phase 5 has become PASS or an explained flag whose count matches the expected number, and clean row count equals raw row count.
