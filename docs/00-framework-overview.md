# The framework in one page

## The three rules (never break these)
1. **Raw is never modified.** Raw files stay as downloaded; the raw tables are all text and untouched. Everything you fix, you fix in a later layer.
2. **Nothing is dropped silently.** A bad row is either loaded and *flagged with a reason code*, or rejected into a *reject file* that you can count. There is no third option.
3. **Every step ends with a reconciliation.** A number from this layer is compared with a number from the previous layer, and the result is PASS or FAIL.

## The layers

| Layer | Schema | What is in it | Types | Who may change it |
|---|---|---|---|---|
| Bronze | `raw` | Exactly what the file said. One text column per header name | all NVARCHAR | nobody (only reloaded from the file) |
| Silver | `clean` | Same rows, real types, trimmed text, blanks as NULL, guard-rails (NOT NULL, keys), reason-code flags | DATE, INT, DECIMAL ... | rebuilt from raw by script, any time |
| Gold | `gold` | Business-ready table(s) with a declared grain, reconciled to silver | as needed | rebuilt from silver by script, any time |

## The loop for every table
```
inspect the FILE  ->  load RAW  ->  PROFILE (measure)  ->  VALIDATE (judge)  ->  SANITIZE into CLEAN (fix/flag)
   ->  re-run the validation on clean  ->  index  ->  build GOLD  ->  health check
```
* **Profile measures** (how many blanks, what types, what ranges).
* **Validate judges** (is a NULL an error? A NULL delivery date is fine on a cancelled order and an error on a delivered one).
* **Sanitize fixes** in the clean layer and the same tests are run again: every FAIL has to become PASS or become an explained flag.

## The seven quality dimensions (Phase 5)
| Dimension | Question | Script |
|---|---|---|
| Completeness | Are required values present? | 5.1, 5.3 |
| Uniqueness | Is the key really unique? | 5.2 |
| Validity | Do values have the right type, format, allowed set? | 4.2, 4.7, 5.4 |
| Accuracy | Do values match reality (range, placeholder dates)? | 4.3, 4.6 |
| Consistency | Do columns agree with each other (start before end)? | 5.5 |
| Timeliness | Is the period complete, no gaps, no future dates? | 5.6 |
| Referential integrity | Does every foreign key find its parent? | 5.7 |

## Repository map
```
README.md                 start here: the run-order table
docs/                     one document per phase + glossary, troubleshooting, cheat sheet
sql/                      reusable scripts, numbered in run order, CONFIG block at the top of each
examples/olist/           the worked example: the exact scripts that ran, dataset cards, expected results
templates/                dataset card, decision log, run log
01_raw/  02_working/  03_outputs/   your data folders (ignored by Git, placeholders only)
```

## How to read a script header
Every script starts with a comment block: **Status** (TESTED on Olist or NEW/untested), **What**, **Edit** (the only lines to change), **Pass** (what a good result looks like). Read it before pressing F5.
