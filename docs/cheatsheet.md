# Cheat sheet

## BULK INSERT options used by the framework
| Option | Meaning | Typical value |
|---|---|---|
| `FORMAT = 'CSV'` | RFC-4180 CSV: quoted fields, delimiters and line breaks inside quotes | always |
| `FIELDQUOTE = '"'` | quote character | `"` |
| `FIRSTROW = 2` | skip header | 2 |
| `LASTROW = n` | stop after row n (sample loads; row 1 is the header, so n = sample + 1) | |
| `FIELDTERMINATOR` | delimiter | `,` `;` `\t` `\|` |
| `ROWTERMINATOR` | line end | `0x0a` (LF), `\r\n` (CRLF) |
| `CODEPAGE` | encoding | `65001` UTF-8, `1252` Windows-1252 |
| `MAXERRORS = n` | rejected rows tolerated | 10 |
| `ERRORFILE = 'path'` | where rejects go; must not exist yet; a `.Error.Txt` appears beside it | |

## T-SQL building blocks (all used in the scripts)
| Need | Syntax |
|---|---|
| Safe name | `QUOTENAME(@name)` |
| Run built SQL | `EXEC sys.sp_executesql @sql;` (with parameters: `, N'@v NVARCHAR(100)', @v = @x`) |
| Columns of a table | `INFORMATION_SCHEMA.COLUMNS` (`TABLE_SCHEMA`, `TABLE_NAME`, `COLUMN_NAME`, `ORDINAL_POSITION`) |
| Join rows into a string | `STRING_AGG(CAST(expr AS NVARCHAR(MAX)), N', ') WITHIN GROUP (ORDER BY pos)` |
| Split a list | `STRING_SPLIT(@list, ',')` (column `value`) |
| Blank to NULL | `NULLIF(LTRIM(RTRIM(x)), '')` |
| Safe conversion | `TRY_CAST(x AS DATETIME2(0))` |
| Exact (case-sensitive) compare | `x COLLATE Latin1_General_BIN2 = y` |
| Bad-pattern search | `x COLLATE Latin1_General_BIN2 LIKE '%[^0-9]%'` |
| Reason codes | `NULLIF(CONCAT_WS(';', CASE WHEN rule THEN 'CODE' END, ...), '')` |
| Median | `PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY x) OVER ()` |
| Calendar | recursive CTE + `OPTION (MAXRECURSION 0)` |
| Orphan test | `WHERE NOT EXISTS (SELECT 1 FROM parent p WHERE p.k = c.k)` |
| Month start | `DATEFROMPARTS(YEAR(d), MONTH(d), 1)` |
| Re-runnable | `DROP TABLE IF EXISTS`, `IF OBJECT_ID(...) IS NULL`, `TRUNCATE TABLE` |
| Who is SQL Server | `SELECT servicename, service_account FROM sys.dm_server_services;` |
| Can SQL Server see the file | `EXEC master.sys.xp_fileexist 'C:\path\file.csv';` |

## SSMS / VS Code keys
| Key | Does |
|---|---|
| `Ctrl+N` (SSMS) | new query |
| `Ctrl+A`, `F5` | select all, execute (F5 runs only the highlighted text if you have highlighted something) |
| `Ctrl+Shift+P` (VS Code) | command palette (Toggle Active Editor Read-only in Session, Sort Lines Ascending) |
| `Ctrl+F` / `Ctrl+H` | find / replace; `Alt+R` regex, `Alt+C` case |
| `Ctrl+G` | go to line |
| `Ctrl+Home` / `Ctrl+End` | first / last line |
| `Alt+Z` | word wrap |

## The golden checks
```
file rows = raw rows + rejected rows
raw rows  = clean rows
clean grain rows = gold rows
clean totals = gold totals
orphans = 0
```
