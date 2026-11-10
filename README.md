# Bronze-Silver-Gold Playbook for cleaning raw CSV data (SQL Server)

A step-by-step, reusable framework for taking any raw CSV file to a clean, tested, business-ready table in **SQL Server Express + SSMS + VS Code**. Built and tested on the Olist Brazilian e-commerce dataset (9 files), then generalised so the same scripts work on other files by editing a CONFIG block.

```
CSV file  ->  raw (all text, untouched)  ->  clean (typed, flagged, tested)  ->  gold (business-ready)
```

**Three rules.** 1) Raw is never modified. 2) Nothing is dropped silently: flag it or reject it into a file you can count. 3) Every step ends with a reconciliation (PASS/FAIL).

## Quick start
1. Install SQL Server Express (2017 or newer), SSMS, VS Code + the Rainbow CSV extension.
2. Clone or unzip this repo to a short path without spaces, for example `C:\bsg-playbook\`. Put your CSV files in `01_raw\` (Olist: `01_raw\archive\*.csv`).
3. Read `docs/00-framework-overview.md` (5 minutes).
4. Copy `templates/dataset_card_TEMPLATE.md` for your file and follow the run-order table below, top to bottom. Every SQL script starts with a comment block saying what to edit and what a pass looks like.
5. Worked example: `examples/olist/` (exact tested scripts, dataset cards for all 9 files, expected numbers).

## Run order (nothing is skipped)
| Step | Phase | What you do | Run / read | Edit | Pass when |
|---|---|---|---|---|---|
| 1.1-1.4 | Acquire | Download the data, keep the original zip, unzip a copy. Never Excel. | `docs/phase-01-acquire.md` | - | original zip + extracted CSVs in `01_raw` |
| 2.1 | Inspect | Open in VS Code, install Rainbow CSV, turn read-only on. | `docs/phase-02-inspect.md` | - | typing is refused |
| 2.2 | Inspect | Delimiter, quote, encoding, BOM, line ending. | same | dataset card | values on the card |
| 2.3 | Inspect | Header checks A-G (+ width regex). Count columns. | same | dataset card | column count written |
| 2.4 | Inspect | Sample top / middle / bottom; count `,,` `,$` placeholders. | same | dataset card | suspicions listed |
| 2.5 | Inspect | Count data rows outside SQL. | same | dataset card | row count written |
| 3.1 | Bronze | Connect in SSMS; create database. | `sql/0_setup/0.1_create_database.sql` | - | ONLINE |
| 3.2 | Bronze | Create schemas raw, clean, gold. | `sql/0_setup/0.2_create_schemas.sql` | - | 3 schemas listed |
| 3.3 | Bronze | Find service account; test file visibility; grant read if needed. | `sql/0_setup/0.3_check_file_access.sql` | `@file` | File Exists = 1 |
| 3.4 | Bronze | Create raw table from the header. | `sql/3_bronze/3.4_create_raw_table_from_header.sql` | CONFIG | all PASS |
| 3.5 | Bronze | Reject folder + permission; prove the safety net. | `sql/3_bronze/3.5_test_error_handling.sql` (+ `02_working/errortest.csv`) | `@project_root` | 3 rows + 1 reject |
| 3.6 | Bronze | Sample load (`@mode = SAMPLE`). | `sql/3_bronze/3.6_load_raw.sql` | CONFIG | result = PASS |
| 3.7 | Bronze | Verify the sample; record the blank rule. | `sql/3_bronze/3.7_verify_sample.sql` | `@schema`,`@table` | header_rows = 0, stray quotes = 0 |
| 3.8 | Bronze | Full load (`@mode = FULL`) and table check. | `3.6_load_raw.sql`, `3.8_table_ready_check.sql` | `@mode`,`@expected_rows` | rows = step 2.5 count |
| 3.9 | Bronze | Reconcile: file rows = raw rows + rejected rows. | docs/phase-03-bronze.md | - | equal |
| 4.1 | Profile | Nulls, blanks, distinct, lengths. | `sql/4_profile/4.1_profile_table.sql` | `@schema`,`@table` | read |
| 4.2 | Profile | Real type per column. | `4.2_detect_types.sql` | same | read |
| 4.3 | Profile | Date ranges, future dates. | `4.3_date_ranges.sql` | same | read |
| 4.4 | Profile | Value frequency of category columns. | `4.4_value_frequency.sql` | `@col` | read |
| 4.5 | Profile | Padding, control characters, case variants. | `4.5_profile_hidden_characters.sql` | same | read |
| 4.6 | Profile | Numeric statistics. | `4.6_profile_numeric_columns.sql` | `@numeric` | read |
| 4.7 | Profile | Format patterns. | `4.7_format_check.sql` | `@rules` | violations 0 |
| 5.1 | Validate | Mandatory columns not blank. | `sql/5_validate/5.1_mandatory_columns.sql` | `@mandatory` | all PASS |
| 5.2 | Validate | Key unique and never blank. | `5.2_primary_key_uniqueness.sql` | `@key_cols` | PASS |
| 5.3 | Validate | Conditional columns vs driver; list rows. | `5.3_conditional_columns.sql`, `5.3b_list_conditional_rows.sql` | `@driver`,`@nullable` | decision made |
| 5.4 | Validate | Allowed values. | `5.4_allowed_values.sql` | `@rules` | violations 0 |
| 5.5 | Validate | Date A <= date B rules. | `5.5_consistency_dates_in_order.sql` | `@rules` | violations 0 or counted |
| 5.6 | Validate | Monthly volume, gaps. | `5.6_timeliness_monthly_volume.sql` | `@date_col` | no GAP |
| 5.7 | Validate | Foreign keys find their parents. | `5.7_referential_integrity.sql` | child/parent | PASS |
| 5.8 | Validate | Table-specific tests (your own pack). | pattern: `examples/olist/sql/5.8_order_items_tests.sql` | - | failing = 0 |
| 6.1 | Sanitize | Suggest column map; override; generate and build clean table; silent-loss test. | `sql/6_sanitize/6.1a_suggest_column_map.sql` then `6.1b_generate_clean_table_and_load.sql` | CONFIG, `UPDATE ##column_map` | rows equal, all PASS |
| 6.2 | Sanitize | Reason-code flags for rule breakers. | `6.2_reason_code_flags_template.sql`; example `examples/olist/sql/6.2_clean_orders_load.sql` | template | counts = expected |
| 6.3 | Sanitize | Re-test phase 5 on clean. | phase-05 scripts with `@schema='clean'`; example `6.3_clean_orders_retest.sql` | - | FAIL -> PASS |
| 7 | Index | Indexes on join/filter columns. | `sql/7_index/7.1_create_index.sql` | `@indexes` | listed |
| 8 | Gold | Declare grain, build gold, reconcile. | `sql/8_gold/8.1_gold_table_template.sql`; example `examples/olist/sql/8.1_gold_order_summary.sql` | template | all PASS |
| 9 | Export | SSMS Export Data to CSV (UTF-8) in `03_outputs`. | `docs/phase-09-10-export-health.md` | - | rows match |
| 10 | Health | One grid of every reconciliation. | `sql/10_health/10.1_health_check_template.sql`; example `examples/olist/sql/10.1_health_check.sql` | rows | PIPELINE HEALTHY |
| 11 | Repeat | Next table / next dataset. | `docs/adding-a-new-dataset.md` | - | checklist ticked |

Notes on numbering: steps 3.1-3.3 match the original build notes; the SQL for them lives in `sql/0_setup/`. Script `3.6` handles both sample and full loads.

## Repository map
```
README.md
docs/                   00 overview, phase-01 ... phase-09-10, adding-a-new-dataset, cheatsheet, glossary, troubleshooting
sql/0_setup/            database, schemas, service-account / file-access check
sql/3_bronze/           raw table from header, error-handling test, loader, sample verification, table check
sql/4_profile/          profiling (7 scripts)
sql/5_validate/         validation tests (completeness, uniqueness, validity, consistency, timeliness, referential integrity)
sql/6_sanitize/         column-map suggester, clean-table generator, reason-code flag template
sql/7_index/  sql/8_gold/  sql/10_health/
examples/olist/         worked example: sql/ (verbatim tested scripts), dataset_cards.md
templates/              dataset card, decision log, run log
01_raw/  02_working/  03_outputs/   data folders (contents are git-ignored)
```

## What is tested and what is not
* **Tested on the Olist build (SQL Server Express):** everything in `examples/olist/sql/`, and the framework scripts `0.1-0.3`, `3.7` part 2, `4.1-4.7`, `5.1`, `5.3`, `5.3b`, `5.5`, `5.6`, `5.7` (they are the same code with the Olist values as CONFIG examples).
* **NEW in this framework, not run on a live server** (checked for quote/bracket balance and parsed statically, but treat as drafts and read the output): `3.4` header-to-table generator, `3.5` and `3.6` (the dynamic path wrappers around the tested BULK INSERT), `3.7` parts 1 and 3, `3.8`, `5.2`, `5.4`, `6.1a`, `6.1b`, `7.1`, and the templates `6.2`, `8.1`, `10.1`. Each has a "Status" line in its header. If one errors, the manual Olist equivalent in `examples/olist/sql/` shows the intended result.
* Only 3 of the 9 Olist tables (orders, customers, order_items) were taken all the way to gold in the original build. The other 6 have dataset cards (`examples/olist/dataset_cards.md`) and are done by following `docs/adding-a-new-dataset.md`.

## Using it on GitHub
Data files are git-ignored (see `.gitignore`); only scripts, docs and templates are committed. Check the licence of your dataset before publishing any data. No licence file is included: add one (for example MIT) if you want others to reuse the repo.

## Where to look when something breaks
`docs/troubleshooting.md`, then `docs/cheatsheet.md`, then `docs/glossary.md`.
