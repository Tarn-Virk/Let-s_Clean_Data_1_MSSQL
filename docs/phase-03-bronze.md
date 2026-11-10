# Phase 3 - Bronze: load the file into `raw` without trusting it

Goal: every row of the file is now in a text-only table, in header order, and the row count matches the number you counted in step 2.5. Nothing is converted, trimmed or fixed here.

## 3.0 Prerequisites (one-time)
* **SQL Server Express 2017 or newer** (the scripts use `STRING_AGG`, `STRING_SPLIT`, `FORMAT='CSV'` for BULK INSERT, `TRY_CAST`, `DROP ... IF EXISTS`; `FORMAT='CSV'` needs 2017+).
* **SQL Server Management Studio (SSMS)** and **VS Code** with the Rainbow CSV extension.
* Windows, with the project folder on a local drive (BULK INSERT cannot read from a mapped network drive without extra setup).

## 3.1 Connect (SSMS)
Start menu, open SQL Server Management Studio. In "Connect to Server":
* Server type: Database Engine
* Server name: your instance, for example `YOURPC\SQLEXPRESS` (or `.\SQLEXPRESS`)
* Authentication: Windows Authentication
* Connect. If you get a certificate error, tick **Trust server certificate** and connect again.

Open a New Query (`Ctrl+N`). Run a script with `F5` (or `Ctrl+A` then `F5`). Results are in the Results tab, warnings in Messages.

## 3.2 Create the database and schemas
| Run | File | Pass |
|---|---|---|
| 1 | `sql/0_setup/0.1_create_database.sql` | one row, `ONLINE` |
| 2 | `sql/0_setup/0.2_create_schemas.sql` | `raw`, `clean`, `gold` listed |

Both are safe to re-run (they check first). To start over completely:
```sql
USE master;
ALTER DATABASE RawToClean_Lab SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE RawToClean_Lab;
```
Look in Object Explorer (refresh with F5) to see the database and its schemas.

## 3.3 Permissions: SQL Server reads the file, not you
BULK INSERT runs as the **SQL Server service account**, which is not your Windows user. If it cannot see the file you get "Access is denied" or "file could not be opened".

1. Run `sql/0_setup/0.3_check_file_access.sql`. The first grid shows the service account (normally `NT Service\MSSQL$SQLEXPRESS`) and its status (Running).
2. Edit `@file` to a CSV path and run the `xp_fileexist` part. Read the result:

| File Exists | Parent Directory Exists | Meaning |
|---|---|---|
| 1 | 1 | PASS. Skip step 3 |
| 0 | 0 | The service account cannot reach the folder (or the path is wrong) |
| 0 | 1 | Folder visible, file name wrong. Recopy the path (Shift + right-click the file, "Copy as path", delete the double quotes) |

3. If it failed, give the service account **read-only** access to the raw folder: right-click `01_raw`, Properties, Security, Edit, Add. Click Locations and pick your computer (not a domain). Type the exact service account from step 1, click Check Names (it underlines). OK. Tick only **Read & execute**, **List folder contents**, **Read**. Apply, OK, OK. Re-run step 2.
   Why read-only: the raw folder is your evidence; SQL Server only needs to read it.
4. Reject folder: SQL Server must also *write* reject files. In `02_working` create a folder `rejects`. Right-click `02_working`, Properties, Security, Edit, Add, same service account, tick **Modify**. Apply. `01_raw` stays read-only; `02_working` is where generated files go.

## 3.4 Create the raw table from the file header
Run `sql/3_bronze/3.4_create_raw_table_from_header.sql` after editing its CONFIG block (`@project_root`, `@file_path`, `@schema`, `@table`, delimiter, row terminator, code page). It reads line 1 of the file, builds a `CREATE TABLE` with one `NVARCHAR(4000)` column per header name in file order, prints the generated code, creates the table if it does not exist, and compares table columns with header positions.
* Pass: every comparison row says PASS, and the column count equals the number from step 2.3.
* Why every column is text and so wide: if a value is longer than its column, BULK INSERT *rejects the row*. Wide text columns mean the raw load can never reject a row for width; types and sizes are decided later, from measurements (Phase 4).
* Why in header order: BULK INSERT maps file fields to table columns by position, not by name.
* This script is NEW and untested on a live server. If it errors, use the manual template `examples/olist/sql/3.4_create_raw_orders_manual.sql`.
* The table must be empty and re-runnable: check with `sql/3_bronze/3.8_table_ready_check.sql` (columns = header count, rows = 0).

## 3.5 Test the safety net before the real load
1. Make sure `02_working\rejects` exists and the service account can write to it (3.3 step 4).
2. This repo already contains `02_working/errortest.csv` (4 rows; row 3 is `3,this_is_too_long`, too long for a 3-character column).
3. Run `sql/3_bronze/3.5_test_error_handling.sql` (edit `@project_root`).

| Check | Expected |
|---|---|
| Rows in the temp table | 3 (ids 1, 2, 4) |
| Rows in the reject file | 1 (id 3) |
| Table + rejects | 4 = rows in the file |
| `*.Error.Txt` next to the reject file | names the `label` column and truncation |

Open the reject files in VS Code, do not edit them. If you see "Access is denied" the service account cannot read the test file (3.3); if you get a "cannot create error file" error it cannot write to `rejects`.
Rule: **BULK INSERT will not overwrite an existing error file.** Scripts 3.5 and 3.6 put a date-time stamp in the file name so re-runs never collide.

## 3.6 Sample load, 3.7 verify, 3.8 full load
All three use `sql/3_bronze/3.6_load_raw.sql`; only `@mode` changes.

1. Edit CONFIG: `@project_root`, `@file_path`, `@schema`, `@table`, `@expected_rows` (from step 2.5), and the format values from the dataset card (`@field_term`, `@row_term`, `@codepage`).
2. `@mode = N'SAMPLE'`, run. It empties the table, loads the first `@sample_rows` rows, and reconciles. Pass: `result = PASS`.
3. Run `sql/3_bronze/3.7_verify_sample.sql`:
   * Part 1 shows 10 rows: check the values sit under the right headers.
   * Part 2 shows, per column, how many blanks were stored as NULL and how many as empty string. **Write the rule down** on the card (`NULL` -> test `IS NULL`; `''` -> test `= ''`; mixed -> test both, as the scripts do).
   * Part 3: `header_rows_loaded` must be 0 (else `FIRSTROW` is wrong), `rows_with_stray_quotes` must be 0 (else the quote settings are wrong).
4. Check the reject folder for new files. Any reject file for a sample is a finding: open it and fix the settings before the full load.
5. Set `@mode = N'FULL'`, run. It truncates the table and loads everything. Pass: `rows_loaded = rows_expected` and `result = PASS`.
6. Re-run `3.8_table_ready_check.sql`: row count = your step 2.5 number.

Why sample first: a wrong delimiter or row terminator on a 1,000,000-row file wastes minutes; on 1,000 rows it fails in a second.
Common settings: `MAXERRORS` is how many rejected rows are tolerated before the whole load is cancelled (default 10; the file is rejected row by row into `ERRORFILE`).

## 3.9 Reconcile (the bronze exit test)
```
rows in the file (step 2.5)  =  rows in the raw table  +  rows in the reject files
```
If the left side does not equal the right side, stop. Do not profile data that is incomplete. Typical causes are in `docs/troubleshooting.md`.

## Done when (per table)
* raw table exists, columns = header, text only
* sample loaded and verified, blank rule written down
* full load PASS, reject folder has no unexplained files
* file rows = raw rows + rejected rows
