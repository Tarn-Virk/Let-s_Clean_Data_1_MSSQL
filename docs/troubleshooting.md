# Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Cannot bulk load because the file ... could not be opened. Operating system error code 5 (Access is denied)` | The SQL Server service account cannot read the path | `0.3_check_file_access.sql`, then phase-03 "Permissions" |
| Error code 3 / "path not found" | Typo, wrong folder, or the file is on a mapped drive | Copy the path from Explorer; use a local path or UNC |
| `Cannot create error file` / error file exists | Service account cannot write to `rejects`, or the file name already exists | Grant Modify on `02_working`; scripts 3.5/3.6 already add a time stamp |
| `Bulk load data conversion error (truncation)` and rows rejected | Raw column too narrow | Use script 3.4 (NVARCHAR(4000)); never shrink raw columns |
| `Bulk load: An unexpected end of file was encountered` | Wrong row terminator, or last row has no line break and terminator mismatch | Check LF vs CRLF on the card; try `0x0a` / `\r\n`; confirm the last row loaded |
| Everything lands in the first column | Wrong `FIELDTERMINATOR` | Check delimiter on the card |
| Values wrapped in `"` after loading | Missing `FORMAT='CSV'` / wrong `FIELDQUOTE` | Use script 3.6 (sets both) |
| Accented text shows `?` or `Ã£` | Wrong `CODEPAGE` | UTF-8 = 65001; Windows-1252 = 1252; re-check in 3.7 |
| First column name begins with an odd character (`ï»¿`) | BOM in the file | 3.4 strips it from the header; the data load skips row 1 anyway |
| Header loaded as a data row | `FIRSTROW` 1 instead of 2 | 3.7 part 3 shows `header_rows_loaded`; set `FIRSTROW = 2` |
| `rows_loaded` is one short | Last row without line break, or mismatched terminator | Count outside SQL; check the last line in VS Code |
| `rows_loaded` is much larger/smaller than the editor line count | Text fields contain line breaks | Count with a CSV parser; keep `FORMAT='CSV'` |
| Load stops: `Bulk load failed. The maximum number of errors (10) was exceeded` | More than `MAXERRORS` rejects | Read the reject file; fix the cause; raise `@max_errors` only to finish diagnosing |
| `Invalid object name 'raw.orders'` | Wrong database selected | `USE RawToClean_Lab;` (toolbar dropdown); run `0.2` |
| `Incorrect syntax near 'GO'` | `GO` on the same line as a statement or you highlighted part of the script | `GO` is an SSMS batch separator on its own line; press `Ctrl+A` first |
| `Violation of PRIMARY KEY constraint` while loading clean | Key is not unique in the data | Run 5.2; fix the grain or de-duplicate with a quarantine |
| `Cannot insert NULL into column` while loading clean | A value failed `TRY_CAST` (or was blank) in a NOT NULL column | 6.1b silent-loss grid shows which; fix type/override or relax to NULL and flag |
| `##column_map not found` | New query window / lost connection | Re-run 6.1a (and your UPDATE overrides) in the same window |
| `STRING_AGG`/`FORMAT` not recognised | SQL Server older than 2017 | Upgrade (Express is free) |
| `Cannot perform an aggregate function on an expression containing an aggregate or a subquery` | A subquery sits inside `SUM(...)`/`STRING_AGG(...)` | Compute it in a derived table first (as 6.1b does with `is_pk`) |
| Recursive calendar error in 5.6 | Missing `OPTION (MAXRECURSION 0)` | Keep it (the script has it) |
| Execution seems stuck on 1M rows | Large file | Wait; look at the Messages tab; run SAMPLE first next time |
| A script from the NEW list errors | Those scripts were written for this framework and not run on a live server | Open an issue / fix by reading the header; fall back to the manual example in `examples/olist/sql` |
