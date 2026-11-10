/* ============================================================================
   10.1  Pipeline health check: every layer ties to the layer before it
   Status : TEMPLATE pattern (tested version: examples/olist/sql/10.1_health_check.sql).
            Edit the rows to match your tables, then it is runnable.
   What   : One grid, one row per reconciliation: expected vs actual, PASS/FAIL,
            and a final verdict. Run it after every full reload.
   Rows   : file vs raw (expected = data-row count from step 2.5),
            raw vs clean, clean vs gold, key totals clean vs gold,
            and orphan checks that must equal 0.
   Pass   : verdict = PIPELINE HEALTHY.
   ============================================================================ */
USE RawToClean_Lab;
GO

DECLARE @health TABLE (n INT, layer_check NVARCHAR(60), expected DECIMAL(18,2), actual DECIMAL(18,2));

INSERT INTO @health (n, layer_check, expected, actual)
SELECT 1, 'orders: file vs raw',   99441,                           (SELECT COUNT(*) FROM raw.orders)   -- 99441 = rows counted in step 2.5
UNION ALL
SELECT 2, 'orders: raw vs clean',  (SELECT COUNT(*) FROM raw.orders),   (SELECT COUNT(*) FROM clean.orders)
UNION ALL
SELECT 3, 'orders: clean vs gold', (SELECT COUNT(*) FROM clean.orders), (SELECT COUNT(*) FROM gold.order_summary)
UNION ALL
SELECT 4, 'orders with no customer', 0,
          (SELECT COUNT(*) FROM clean.orders AS o
           WHERE NOT EXISTS (SELECT 1 FROM clean.customers AS c WHERE c.customer_id = o.customer_id));
-- add one block per table / total / orphan test of YOUR pipeline

SELECT layer_check, expected, actual,
       CASE WHEN expected = actual THEN 'PASS' ELSE 'FAIL' END AS result
FROM @health
ORDER BY n;

SELECT COUNT(*)                                           AS checks_run,
       SUM(CASE WHEN expected = actual THEN 1 ELSE 0 END) AS checks_passed,
       CASE WHEN SUM(CASE WHEN expected <> actual THEN 1 ELSE 0 END) = 0
            THEN 'PIPELINE HEALTHY' ELSE 'PIPELINE HAS FAILURES' END AS verdict,
       SYSDATETIME()                                      AS checked_at
FROM @health;
GO
