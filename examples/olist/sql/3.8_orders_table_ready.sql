/* ============================================================================
   3.8o  Orders table ready check
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Column count and row count of raw.orders.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : column_count = 8; row_count = 99441 after the full load.
   ============================================================================ */

USE RawToClean_Lab;
GO

SELECT
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = 'raw' AND TABLE_NAME = 'orders') AS column_count,
    (SELECT COUNT(*) FROM raw.orders)                      AS row_count;
GO
