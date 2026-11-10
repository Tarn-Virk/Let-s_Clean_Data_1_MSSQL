/* ============================================================================
   10.1o  Pipeline health check (Olist)
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Twelve checks: file vs raw vs clean vs gold counts, totals, and orphan tests.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : verdict = PIPELINE HEALTHY.
   ============================================================================ */

USE RawToClean_Lab;
GO

DECLARE @health TABLE (n INT, layer_check NVARCHAR(60), expected DECIMAL(18,2), actual DECIMAL(18,2));

INSERT INTO @health (n, layer_check, expected, actual)
SELECT 1,  'orders: file vs raw',            99441,  (SELECT COUNT(*) FROM raw.orders)
UNION ALL

SELECT 2,  'orders: raw vs clean',           (SELECT COUNT(*) FROM raw.orders),     (SELECT COUNT(*) FROM clean.orders)
UNION ALL

SELECT 3,  'orders: clean vs gold',          (SELECT COUNT(*) FROM clean.orders),   (SELECT COUNT(*) FROM gold.order_summary)
UNION ALL

SELECT 4,  'customers: file vs raw',         99441,  (SELECT COUNT(*) FROM raw.customers)
UNION ALL

SELECT 5,  'customers: raw vs clean',        (SELECT COUNT(*) FROM raw.customers),  (SELECT COUNT(*) FROM clean.customers)
UNION ALL

SELECT 6,  'order_items: file vs raw',       112650, (SELECT COUNT(*) FROM raw.order_items)
UNION ALL

SELECT 7,  'order_items: raw vs clean',      (SELECT COUNT(*) FROM raw.order_items),   (SELECT COUNT(*) FROM clean.order_items)
UNION ALL

SELECT 8,  'order_items: clean vs gold',     (SELECT COUNT(*) FROM clean.order_items), (SELECT SUM(item_count) FROM gold.order_summary)
UNION ALL

SELECT 9,  'total price: clean vs gold',     (SELECT SUM(price) FROM clean.order_items),         (SELECT SUM(item_revenue) FROM gold.order_summary)
UNION ALL

SELECT 10, 'total freight: clean vs gold',   (SELECT SUM(freight_value) FROM clean.order_items), (SELECT SUM(freight_total) FROM gold.order_summary)
UNION ALL

SELECT 11, 'orders with no customer',        0,
           (SELECT COUNT(*) FROM clean.orders AS o
            WHERE NOT EXISTS (SELECT 1 FROM clean.customers AS c WHERE c.customer_id = o.customer_id))
UNION ALL

SELECT 12, 'items with no order',            0,
           (SELECT COUNT(*) FROM clean.order_items AS i
            WHERE NOT EXISTS (SELECT 1 FROM clean.orders AS o WHERE o.order_id = i.order_id));

SELECT layer_check, expected, actual,
       CASE WHEN expected = actual THEN 'PASS' ELSE 'FAIL' END AS result
FROM @health
ORDER BY n;

SELECT COUNT(*)                                              AS checks_run,
       SUM(CASE WHEN expected = actual THEN 1 ELSE 0 END)    AS checks_passed,
       CASE WHEN SUM(CASE WHEN expected <> actual THEN 1 ELSE 0 END) = 0
            THEN 'PIPELINE HEALTHY' ELSE 'PIPELINE HAS FAILURES' END AS verdict,
       SYSDATETIME()                                         AS checked_at
FROM @health;
GO
