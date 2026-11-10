/* ============================================================================
   8.1  Gold table template: one declared grain, built from clean, reconciled
   Status : TEMPLATE (worked, tested version: examples/olist/sql/8.1_gold_order_summary.sql).
            NOT runnable as-is: replace every <angle-bracket> part.
   Rules  : 1) Declare the grain in one sentence ("one row per <thing>") and make it the PRIMARY KEY.
            2) Start FROM the grain table and LEFT JOIN everything else, so no row of the grain is lost.
            3) Aggregate every many-side table to the grain BEFORE joining (derived table with GROUP BY),
               otherwise rows multiply (fan-out) and totals are wrong.
            4) Keep flag columns from clean; do not silently filter. Put reporting rules in explicit
               bit columns (for example in_reporting_window) so the analyst chooses.
            5) Reconcile gold to clean: row count, and each SUM, must tie out exactly.
   Pass   : every reconciliation row shows PASS.
   ============================================================================ */
USE RawToClean_Lab;
GO

/*
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold') EXEC('CREATE SCHEMA gold');
GO

DROP TABLE IF EXISTS gold.<table>;
GO

CREATE TABLE gold.<table> (
    <grain_key>        NVARCHAR(32)  NOT NULL,      -- the grain
    <dimension_col>    NVARCHAR(50)  NOT NULL,
    <measure_count>    INT           NOT NULL,
    <measure_amount>   DECIMAL(12,2) NOT NULL,
    <flag_col>         BIT           NOT NULL,
    <issue_codes>      NVARCHAR(200) NULL,
    CONSTRAINT PK_gold_<table> PRIMARY KEY (<grain_key>)
);
GO

INSERT INTO gold.<table> (...)
SELECT g.<grain_key>, d.<dimension_col>,
       ISNULL(m.<n>, 0), ISNULL(m.<amount>, 0),
       CASE WHEN g.<ts> >= '<window_start>' AND g.<ts> < '<window_end>' THEN 1 ELSE 0 END,
       g.<issue_codes>
FROM clean.<grain_table> AS g
LEFT JOIN clean.<dimension_table> AS d ON d.<key> = g.<fk>
LEFT JOIN (
    SELECT <grain_key>, COUNT(*) AS <n>, SUM(<amount>) AS <amount>
    FROM clean.<many_side_table>
    GROUP BY <grain_key>
) AS m ON m.<grain_key> = g.<grain_key>;
GO

SELECT test, gold_value, clean_value,
       CASE WHEN gold_value = clean_value THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
    SELECT 1 AS n, 'rows' AS test,
           (SELECT COUNT(*) FROM gold.<table>) AS gold_value,
           (SELECT COUNT(*) FROM clean.<grain_table>) AS clean_value
    UNION ALL
    SELECT 2, 'total <amount>',
           (SELECT SUM(<measure_amount>) FROM gold.<table>),
           (SELECT SUM(<amount>) FROM clean.<many_side_table>)
) AS t ORDER BY n;
GO
*/
