# Phase 4 - Profile: measure what is really in the raw table

Goal: facts, not opinions. Phase 4 *measures*; Phase 5 *judges*. A NULL is only an error if Phase 5 says so.
Every script here reads `raw.<table>`; edit `@schema`/`@table` (and the listed extras) at the top and run it. Write each result on the dataset card.

| Step | Script | Question | What to write down |
|---|---|---|---|
| 4.1 | `sql/4_profile/4.1_profile_table.sql` | How big is each column, how empty? | null count and %, blank (spaces only) count, distinct count, min/max length. Distinct = rows -> candidate key. Distinct small -> category column. Max length -> real width for clean |
| 4.2 | `4.2_detect_types.sql` | What type is each column *really*? | for each column: filled values vs how many cast to INT / DECIMAL / DATETIME2. All filled values cast -> candidate type. Fewer -> the gap is a data problem to chase |
| 4.3 | `4.3_date_ranges.sql` | Are dates inside business reality? | earliest, latest, future-date count per date column. Year 1900/2100/placeholders are findings |
| 4.4 | `4.4_value_frequency.sql` (set `@col`) | Which values exist in a category column? | every distinct value with count and %: spelling variants (`Delivered` vs `delivered`), placeholders, rare values. Compared with a binary collation so case is not hidden |
| 4.5 | `4.5_profile_hidden_characters.sql` | Invisible damage? | padded (leading/trailing spaces), control characters (tab, line feed, carriage return) inside values, case variants |
| 4.6 | `4.6_profile_numeric_columns.sql` (set `@numeric`) | Do the numbers make sense? | not-numeric count, min, max, average, standard deviation, p01/p25/median/p75/p99, zero and negative counts |
| 4.7 | `4.7_format_check.sql` | Do text codes follow their pattern? | e.g. zip digits only, state capital letters only, city lowercase letters/space/apostrophe/hyphen. Each rule = column + a *bad* pattern + meaning; violations should be 0 |

## Reading the results
* **Blank rule.** From step 3.7: NULL, empty string, or both. All later tests must test both (the scripts do `IS NULL OR LTRIM(RTRIM(x)) = ''`).
* **Type detection.** A column whose values all cast cleanly is a type candidate; ids with leading zeros (zip codes) must stay text even though they cast to INT (script 6.1a protects names ending `_id`, `_code`, containing `zip` or `prefix`, and values starting with `0`).
* **Medians and p99** against the maximum expose outliers that min/max alone hide.
* **Widths.** Clean text columns are sized from the measured maximum length plus headroom, never from guesses.

## Done when
For every column you can answer: how empty is it, what type is it, what range, what values, any hidden characters, any format breaks. Those answers are in the dataset card and drive Phase 5 and 6.
