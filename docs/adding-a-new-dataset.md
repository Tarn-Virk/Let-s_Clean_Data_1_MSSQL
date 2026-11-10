# Adding a new dataset (the replication checklist)

Use this for the next Olist table or for any other CSV. Copy `templates/dataset_card_TEMPLATE.md` first and fill it as you go. Tick every box; none is optional.

## A. Acquire and inspect (docs/phase-01, phase-02)
- [ ] Original file kept untouched in `01_raw`
- [ ] Opened in VS Code read-only, never in Excel
- [ ] Delimiter, quote, encoding, BOM, line ending, header on the card
- [ ] Header checks A-G done; column count written
- [ ] Top / middle / bottom sampled; `,,`  `,$`  placeholder counts written
- [ ] Data rows counted outside SQL (CSV parser if text has line breaks)

## B. Bronze
- [ ] 3.3 service account can read the file (`0.3`)
- [ ] 3.4 raw table created from header, header comparison all PASS
- [ ] 3.6 SAMPLE load PASS, 3.7 verified, blank rule written down
- [ ] 3.6 FULL load PASS, file rows = raw rows + rejected rows

## C. Profile (4.1 - 4.7)
- [ ] Null / blank / distinct / lengths read
- [ ] Types detected, date ranges, value frequencies, hidden characters, numeric stats, formats

## D. Validate (5.1 - 5.7, plus your own 5.8)
- [ ] Grain and key declared, then proven (5.2)
- [ ] Mandatory vs conditional columns, allowed values, ordering rules, parent tables decided
- [ ] Every FAIL has a decision and an expected row count in the decision log

## E. Sanitize (6.x), index, gold, health
- [ ] 6.1a map reviewed and overridden, 6.1b executed, silent-loss test all PASS
- [ ] Flags added for rules that keep the row; re-test counts equal expected counts
- [ ] Indexes on keys and date columns
- [ ] Gold grain declared, built from the grain with LEFT JOINs, many-side aggregated first, reconciled
- [ ] Health check rows added for the new table, verdict HEALTHY, run log updated

## What to change per script (cheat list)
| Script | Lines to edit |
|---|---|
| 3.4 | `@project_root`, `@file_path`, `@table`, delimiter, row terminator, code page |
| 3.6 | same plus `@mode`, `@expected_rows` |
| 4.x | `@schema`, `@table` and, where listed, `@col` / `@numeric` / `@rules` |
| 5.x | `@mandatory`, `@key_cols`, `@driver`+`@nullable`, `@rules`, `@date_col`, child/parent names |
| 6.1a / 6.1b | raw and clean names, `@pk_cols`, `@execute` |
| 7.1 | the `@indexes` rows |
| 10.1 | add rows for your tables |

## When the data is not like Olist
| Situation | What to do |
|---|---|
| Delimiter is `;`, tab or `\|` | set `@field_term` (tab = `\t`); keep `FORMAT='CSV'` |
| Encoding is Windows-1252 | `@codepage = N'1252'`; verify accents in 3.7 |
| Header is not in row 1 / has junk lines | `FIRSTROW` = first data row; build the table by hand (3.4 reads line 1) |
| No header at all | create the raw table by hand with `COL1..COLn`, `FIRSTROW = 1` |
| Header has spaces/capitals/duplicates | raw table keeps header names (3.4 quotes them); fix in the clean `target_name` |
| Text with line breaks | `FORMAT='CSV'` is required; count rows with a CSV parser |
| Wider than 4000 characters | raw column `@col_width = N'MAX'` in 3.4 |
| More than one million rows | always SAMPLE first; give the full load time; consider loading in the evening |
| Excel (.xlsx) source | export one sheet to CSV from a *copy*, UTF-8, then follow this checklist; record that the conversion happened |
| Other database engines (MySQL, Postgres, SQLite) | the framework, order of phases and tests still apply; only the load command and some functions change (see the T-SQL list in `cheatsheet.md`) |
