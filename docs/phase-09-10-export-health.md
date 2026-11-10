# Phases 9-10 - Export and pipeline health check

## 9. Export gold for a dashboard (Power BI, Excel pivot, anything)
Never write analysis results back over raw files. Export to `03_outputs`.
1. SSMS Object Explorer: right-click the database, Tasks, **Export Data...**
2. Source: SQL Server Native Client / OLE DB for SQL Server, your server, Windows Authentication, database `RawToClean_Lab`.
3. Destination: **Flat File Destination**. File name in `03_outputs\` (for example `gold_order_summary.csv`). Format: Delimited. Code page: **65001 (UTF-8)**. Text qualifier: `"`. Tick "Column names in the first data row".
4. Choose "Copy data from one or more tables or views", select `gold.<table>`. Next, Finish.
5. Check the exported file the way you check any CSV (Phase 2): row count = gold row count, header correct, dates not mangled.
6. Power BI can also connect straight to the SQL Server database and read `gold` (and its indexes make it faster). Handoff checklist: grain stated, window flag explained, flag codes explained, row counts reconciled, refresh instructions.

Note: do not open the exported CSV in Excel and save it (Phase 1 rule). Import it.

## 10. Pipeline health check
Run `sql/10_health/10.1_health_check_template.sql` after editing its rows (worked example: `examples/olist/sql/10.1_health_check.sql`, 12 checks). It prints one grid:
* file vs raw (expected = the count from 2.5)
* raw vs clean
* clean vs gold
* control totals clean vs gold
* orphan checks (expected 0)

and a verdict: **PIPELINE HEALTHY** or **PIPELINE HAS FAILURES**, with a timestamp. Paste the result into `templates/run_log_TEMPLATE.md` after every full reload.

## 11. Replicate
Apply the same loop to the next table: `docs/adding-a-new-dataset.md`.
