/* ============================================================================
   5.8  Order_items test pack
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Duplicate (order_id, order_item_id), items without an order, bad dates, more than 2 decimals; then orders without items by status.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : The four tests PASS. The second grid is information: orders legitimately without items (for example canceled or unavailable).
   ============================================================================ */

USE RawToClean_Lab;
GO

SELECT test, failing,
       CASE WHEN failing = 0 THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
    SELECT 1 AS n, 'duplicate (order_id, order_item_id) pairs' AS test, COUNT(*) AS failing
    FROM (SELECT order_id, order_item_id
          FROM raw.order_items
          GROUP BY order_id, order_item_id
          HAVING COUNT(*) > 1) AS d
    UNION ALL
    SELECT 2, 'items whose order does not exist', COUNT(*)
    FROM raw.order_items AS i
    WHERE NOT EXISTS (SELECT 1 FROM raw.orders AS o WHERE o.order_id = i.order_id)
    UNION ALL
    SELECT 3, 'shipping_limit_date that is not a date', COUNT(*)
    FROM raw.order_items
    WHERE TRY_CAST(shipping_limit_date AS DATETIME2) IS NULL
    UNION ALL
    SELECT 4, 'price or freight with more than 2 decimals', COUNT(*)
    FROM raw.order_items
    WHERE TRY_CAST(price AS DECIMAL(18,4))         <> TRY_CAST(price AS DECIMAL(18,2))
       OR TRY_CAST(freight_value AS DECIMAL(18,4)) <> TRY_CAST(freight_value AS DECIMAL(18,2))
) AS t
ORDER BY n;
GO

SELECT o.order_status, COUNT(*) AS orders_without_items
FROM raw.orders AS o
WHERE NOT EXISTS (SELECT 1 FROM raw.order_items AS i WHERE i.order_id = o.order_id)
GROUP BY o.order_status
ORDER BY orders_without_items DESC;
GO
