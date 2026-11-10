/* ============================================================================
   6.3o  Re-test clean.orders flags against the expected counts
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Expected rows per code (from the step 5 findings) versus actual in clean.orders, and the share of flagged orders.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : Every code PASS: 166, 1359, 61, 23, 14, 2, 8.
   ============================================================================ */

USE RawToClean_Lab;
GO

WITH expected AS (
    SELECT code, expected_rows
    FROM (VALUES
        ('PURCHASE_AFTER_CARRIER',   166),
        ('APPROVED_AFTER_CARRIER',   1359),
        ('APPROVED_AFTER_DELIVERED', 61),
        ('CARRIER_AFTER_DELIVERED',  23),
        ('DELIVERED_NO_APPROVED',    14),
        ('DELIVERED_NO_CARRIER',     2),
        ('DELIVERED_NO_DELIVERY',    8)
    ) AS v (code, expected_rows)
),
actual AS (
    SELECT s.value AS code, COUNT(*) AS actual_rows
    FROM clean.orders AS o
    CROSS APPLY STRING_SPLIT(o.date_issue_codes, ';') AS s
    GROUP BY s.value
)
SELECT COALESCE(e.code, a.code)  AS issue_code,
       e.expected_rows,
       ISNULL(a.actual_rows, 0)  AS actual_rows,
       CASE WHEN e.expected_rows = ISNULL(a.actual_rows, 0)
            THEN 'PASS' ELSE 'FAIL' END AS result
FROM expected AS e
FULL OUTER JOIN actual AS a ON a.code = e.code
ORDER BY e.expected_rows DESC;
GO

SELECT

    COUNT(*)                                                         AS total_rows,
    SUM(CASE WHEN date_issue_codes IS NOT NULL THEN 1 ELSE 0 END)    AS orders_with_a_flag,
    SUM(CASE WHEN date_issue_codes IS NULL     THEN 1 ELSE 0 END)    AS orders_with_no_flag,
    CAST(100.0 * SUM(CASE WHEN date_issue_codes IS NOT NULL THEN 1 ELSE 0 END)
         / COUNT(*) AS DECIMAL(5,2))                                 AS pct_flagged
FROM clean.orders;
GO
