# Phases 7-8 - Index and Gold

## 7. Index the clean tables
Run `sql/7_index/7.1_create_index.sql` after editing its CONFIG rows (schema, table, index name, key columns). Index the columns used in joins (foreign keys) and filters (dates). The primary key already indexes the key. Pass: the final grid lists your indexes.

## 8. Gold: the business-ready table
1. **State the business question** in plain English ("late-delivery rate and revenue by customer state, per month").
2. **Declare the grain** in one sentence: "one row = one order". That is the primary key of the gold table.
3. Build from the template `sql/8_gold/8.1_gold_table_template.sql`, worked example `examples/olist/sql/8.1_gold_order_summary.sql`.

Rules that prevent wrong totals:
* **Start from the grain table and LEFT JOIN** everything else, so no grain row is lost (an order with no items still appears, with 0 items).
* **Aggregate the many-side table to the grain first** (derived table `GROUP BY order_id`), then join. Joining first multiplies rows (fan-out) and inflates sums.
* **Do not hide flagged rows.** Carry the flag columns through and compute measures with the flag in mind (Olist: `days_late` is computed only for delivered orders whose dates are not flagged `AFTER_DELIVERED`).
* **Reporting window as a column**, not a filter: `in_reporting_window BIT`. Analysts decide to filter or not.

4. **Reconcile gold to clean** (must all PASS): grain row count, sum of item counts, total of each money column, count inside the reporting window.
5. Query a small summary and sanity-check it against what you know.

## Done when
Gold rows = clean grain rows, every measure total ties to clean, and the grain is the primary key.
