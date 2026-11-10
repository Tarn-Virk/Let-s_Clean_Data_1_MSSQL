# Phase 2 - Inspect each file before loading it

Goal: learn the file's *format* (so BULK INSERT is configured right) and its *shape* (so you can prove the load is complete). Everything here happens in VS Code, read-only. Fill one dataset card per file.

## 2.1 Open the file safely
1. Install VS Code. Press `Ctrl+Shift+X`, search **Rainbow CSV**, Install (one-time). It only colours columns on screen; it never changes the file.
2. `File > Open File...`, choose the CSV.
3. Turn on read-only: `Ctrl+Shift+P`, type **Toggle Active Editor Read-only in Session**, Enter. One stray keystroke plus `Ctrl+S` would otherwise change your raw evidence.
4. `Alt+Z` toggles word wrap; use whichever is easier to read.
5. Confirm: opens without errors; top row looks like column names; every row has the same number of coloured columns; typing a character is refused; the status bar shows encoding and line ending (read them in 2.2).

## 2.2 Confirm delimiter, quote character, encoding, line ending
Read these from the file and the status bar and write them on the card. They map one-to-one to load options:

| Property | How to see it | BULK INSERT option |
|---|---|---|
| Delimiter (comma, semicolon, tab, pipe) | Rainbow CSV colours / the raw text | `FIELDTERMINATOR` |
| Quote character (usually `"`) | text fields wrapped in quotes | `FORMAT='CSV'`, `FIELDQUOTE='"'` |
| Encoding (UTF-8, UTF-8 with BOM, Windows-1252) | status bar, bottom right | `CODEPAGE` (`65001` = UTF-8) |
| Line ending (LF or CRLF) | status bar shows LF or CRLF | `ROWTERMINATOR` (`0x0a` for LF, `\r\n` for CRLF) |
| Header | row 1 | `FIRSTROW = 2` |

Also check: does the file start with a BOM (status bar says "UTF-8 with BOM")? Do any quoted text fields contain line breaks (reviews, comments, addresses)? If yes, only `FORMAT='CSV'` loads them correctly, and the editor's line count will be bigger than the real row count.
If the status bar says Windows-1252 or you see `?`/`Ã£` in names: do not guess. Open the file with the right encoding (`Reopen with Encoding`) and use the matching `CODEPAGE` (for example `1252`).

## 2.3 Header checks (teaching step: do it on every new file, it takes two minutes)
Work in a scratch copy of the header, never in the raw file.
* **A. Copy the header:** click in the file, `Ctrl+Home`, `Ctrl+C` (copies the whole line when nothing is selected), `Ctrl+N` for a new untitled file, `Ctrl+V`.
* **B. One name per line:** `Ctrl+H`, switch regex on (`Alt+R`), Find `,` Replace `\n`, `Ctrl+Alt+Enter`. Then Find `"`, Replace empty, replace all.
* **C. Count the columns:** `Ctrl+End`; the line number in the status bar is the column count. **Write it on the card.**
* **D. Naming and order:** same style (snake_case), same language, and the order reads like a story (purchased, approved, shipped, delivered).
* **E. Trouble characters:** `Ctrl+F`, regex on, case-sensitive on (`Alt+C`), search `[^a-z0-9_\n]`. Zero hits means only lowercase letters, digits, underscores. Any hit (space, hyphen, accent, capital, symbol) is a finding.
* **F. Duplicate names:** `Ctrl+A`, `Ctrl+Shift+P`, **Sort Lines Ascending**; identical names now sit next to each other.
* **G. Reserved words:** compare with `order, date, group, user, key, table, index`. Only an exact match is a problem (`order` needs `[order]` in T-SQL; `order_id` is fine).
* **Bonus - consistent width:** in the raw file, `Ctrl+F`, regex on, search `^(?!([^,]*,){7}[^,]*$).+$` (replace `7` by columns minus 1). "No results" means every row has the same number of commas. This only works for files without quoted commas/line breaks; for others trust the loader's reject file instead.

## 2.4 Sample the body rows
Headers say what columns *should* hold; rows show what they *do* hold. Look at three places: top (`Ctrl+Home`, rows 2-20), middle (`Ctrl+G`, a line about halfway, 20 rows), bottom (`Ctrl+End`, last 20 rows; also shows a file cut off mid-row).
Look for: blank values, placeholder text (NULL, N/A, unknown, -), inconsistent case or spelling, leading/trailing spaces, dates that break the pattern of their neighbours, IDs that change length, sorted or random order.
Count suspicions with Find (regex on, typing in Find never edits the file):
* `,,` blank values in the middle of a row (approximate: consecutive blanks overlap)
* `,$` rows ending in a blank last column
* `^,` rows starting with a blank first column
* `NULL|N/A|n/a|unknown` (case-insensitive) placeholder text

These are *suspicions*. Phase 4 proves them with SQL.

## 2.5 Count the data rows OUTSIDE SQL
`Ctrl+End` and read the line number in the status bar:
```
last line number            e.g. 99,443
minus header line             - 1
minus empty last line         - 1   (only if the file ends with a line break)
= data rows                   99,441
```
This is the number the database must reproduce. **Write it on the card** (and into `@expected_rows` in script 3.6).
Careful: if text fields contain line breaks (Olist reviews), physical lines are more than rows. Count with a CSV parser instead, for example:
```
python -c "import csv,sys; print(sum(1 for _ in csv.reader(open(sys.argv[1], encoding='utf-8-sig', newline='')))-1)" file.csv
```

## Done when (per file)
Delimiter, quote, encoding, BOM, line ending, header column count, data row count, and a list of suspicions are on the card. Example for Olist orders: comma / quotes present / UTF-8 no BOM / LF / header row 1 with 8 columns / 99,441 rows.
