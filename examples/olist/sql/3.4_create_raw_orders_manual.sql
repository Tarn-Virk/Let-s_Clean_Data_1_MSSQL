/* ============================================================================
   3.4m  Create raw.orders by hand (manual alternative to 3.4)
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Creates raw.orders with one text column per header name, lists the columns, counts rows. Use sql/3_bronze/3.4 to generate this for any file.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : The column list matches the header of olist_orders_dataset.csv in the same order; row_count = 0 before the first load.
   ============================================================================ */

USE RawToClean_Lab;
GO

IF OBJECT_ID('raw.orders', 'U') IS NULL

BEGIN
    CREATE TABLE raw.orders (
        order_id                       NVARCHAR(50),
        customer_id                    NVARCHAR(50),
        order_status                   NVARCHAR(50),
        order_purchase_timestamp       NVARCHAR(50),
        order_approved_at              NVARCHAR(50),
        order_delivered_carrier_date   NVARCHAR(50),
        order_delivered_customer_date  NVARCHAR(50),
        order_estimated_delivery_date  NVARCHAR(50)
    );
END

GO


SELECT ORDINAL_POSITION, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'raw' AND TABLE_NAME = 'orders'

ORDER BY ORDINAL_POSITION;
GO


SELECT COUNT(*) AS row_count FROM raw.orders;
GO
