# Glossary

| Term | Meaning |
|---|---|
| Bronze / Silver / Gold | Raw copy / typed and checked copy / business-ready tables. Here the schemas `raw`, `clean`, `gold` |
| Grain | What one row of a table represents ("one row = one order"). It is the key |
| Idempotent | Safe to run twice: second run changes nothing or gives the same result |
| BULK INSERT | T-SQL command that loads a file into a table, reading the file as the SQL Server service account |
| FORMAT = 'CSV' | BULK INSERT mode that understands quoted fields, including delimiters and line breaks inside quotes (SQL Server 2017+) |
| FIELDTERMINATOR / ROWTERMINATOR | Characters that end a field / a row. `0x0a` = LF, `\r\n` = CRLF |
| CODEPAGE 65001 | UTF-8 |
| BOM | Byte-order mark: invisible 3 bytes at the start of some UTF-8 files; can end up glued to the first column name |
| LF / CRLF | Line-ending styles (Unix / Windows) |
| MAXERRORS / ERRORFILE | How many rejected rows to tolerate / where to write them |
| Reject file | Text file with the rows BULK INSERT could not load, plus a `.Error.Txt` explaining why |
| Service account | The Windows identity SQL Server runs as; it needs permission on the file, not you |
| Profile / Validate / Sanitize | Measure / judge / fix |
| Reason code | Short label stored on a row that broke a rule, e.g. `CARRIER_AFTER_DELIVERED` |
| Quarantine | A table or file holding removed rows together with the reason; the alternative to silent deletion |
| TRY_CAST | Converts or returns NULL instead of an error. Danger: a bad value silently becomes NULL, hence the silent-loss test (6.1b) |
| NULLIF(x, '') | Turns an empty string into NULL |
| Collation / BIN2 | Rules for comparing text. `COLLATE Latin1_General_BIN2` compares exact characters (case and accents matter) |
| Dynamic SQL / sp_executesql | SQL built as a string and executed; lets one script work on any table or column list |
| QUOTENAME | Wraps a name in `[ ]` safely so odd names do not break the SQL |
| STRING_AGG / STRING_SPLIT | Join rows into one string / split a comma list into rows |
| Orphan | A child row whose parent key does not exist |
| Fan-out | Joining one-to-many before aggregating, which multiplies rows and inflates sums |
| Reconciliation | Comparing a number to the same number one layer earlier (PASS/FAIL) |
| Control total | A sum used for reconciliation (total price, total freight) |
| Global temp table (`##x`) | Temp table visible while your connection stays open |
