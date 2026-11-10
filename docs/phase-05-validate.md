# Phase 5 - Validate: decide what is wrong

Goal: turn the Phase 4 measurements into explicit pass/fail tests. Each test has an expected result you can state *before* running it. Run tests against `raw` first; after Phase 6 run them again against `clean`.

## First decide, in writing (dataset card section 5-7)
* **Grain and key:** "one row = one ____". Which column(s) make it unique?
* **Mandatory columns:** never blank.
* **Conditional columns:** blank is allowed only when another column explains it (delivery date may be blank unless status is `delivered`).
* **Allowed values** for category columns (from 4.4).
* **Ordering rules** between date columns (purchase <= approval <= carrier <= delivery).
* **Parent tables** for every foreign key.

## The tests

| Step | Dimension | Script | Edit | Pass |
|---|---|---|---|---|
| 5.1 | Completeness | `sql/5_validate/5.1_mandatory_columns.sql` | `@mandatory` (comma list) | `missing_count = 0` for each |
| 5.2 | Uniqueness | `5.2_primary_key_uniqueness.sql` (NEW) | `@key_cols` (one or several) | `duplicate_key_groups = 0`, `rows_with_blank_key_part = 0`, `total_rows = distinct_keys` |
| 5.3 | Completeness (conditional) | `5.3_conditional_columns.sql` then `5.3b_list_conditional_rows.sql` | `@driver`, `@nullable`, `@driver_value` | read the grid: NULLs per status; 5.3b lists the exact rows for the status that should never be NULL |
| 5.4 | Validity (domain) | `5.4_allowed_values.sql` (NEW) | the `@rules` rows (column + allowed list) | `violations = 0` |
| 5.4b | Validity (format) | `sql/4_profile/4.7_format_check.sql` | `@rules` | `violations = 0` |
| 5.5 | Consistency | `5.5_consistency_dates_in_order.sql` | `@rules` (earlier column, later column) | `violations = 0` |
| 5.6 | Timeliness | `5.6_timeliness_monthly_volume.sql` | `@date_col` | no `GAP` inside the period you report on; look at thin first/last months |
| 5.7 | Referential integrity | `5.7_referential_integrity.sql` | child table/key, parent table/key | `orphan_child_rows = 0`, `duplicated_parent_keys = 0` |
| 5.8 | Table-specific tests | write your own pack in the same shape as `examples/olist/sql/5.8_order_items_tests.sql` | | each row `failing = 0` |

Accuracy (range, placeholder dates, negative or absurd amounts) is covered by 4.3 and 4.6; turn what you saw there into a numbered test in your 5.8 pack.

## Interpreting a FAIL (do not "fix" yet)
For each FAIL write one decision on the decision log (`templates/decision_log_TEMPLATE.md`):

| Situation | Typical decision |
|---|---|
| Rule broken but the row is still usable (dates out of order) | **Flag** with a reason code in clean. Keep the row |
| Required value missing but the row is otherwise real | Flag; decide NULL vs default per column |
| Key duplicated | Find out why first. Decide: keep one row by a deterministic rule, or the grain is wrong |
| Value not parseable as its type | Keep the raw text in raw; clean gets NULL **and** the silent-loss test (6.1b) must account for it; or flag |
| Orphan child row | Keep and flag, or quarantine; never delete silently |
| Not an error after all (NULL delivery date on a cancelled order) | Write down why, no action |

Write the **expected count per rule** now (for example `CARRIER_AFTER_DELIVERED` = 23). Phase 6 is only finished when the flag counts in clean equal these numbers.

## Done when
Every test has a result and every FAIL has a decision with its expected row count.
