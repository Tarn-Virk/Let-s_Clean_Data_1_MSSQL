/* ============================================================================
   3.7a  Check the sample landed correctly (orders)
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Row count, header-row-loaded test, stray-quote test, order_status frequency, then the first 10 rows of raw.orders.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : header_rows_loaded = 0 and values sit under the right headers.
   ============================================================================ */

USE RawToClean_Lab;
GO

SELECT COUNT(*) AS rows_loaded FROM raw.orders;

SELECT COUNT(*) AS header_rows_loaded
FROM raw.orders
WHERE order_id = 'order_id';

SELECT COUNT(*) AS rows_with_stray_quotes
FROM raw.orders
WHERE CONCAT(order_id, customer_id, order_status, order_purchase_timestamp,
             order_approved_at, order_delivered_carrier_date,
             order_delivered_customer_date, order_estimated_delivery_date) LIKE '%"%';

SELECT order_status, COUNT(*) AS n
FROM raw.orders
GROUP BY order_status
ORDER BY n DESC;
GO


SELECT TOP (10) * FROM raw.orders;
GO
