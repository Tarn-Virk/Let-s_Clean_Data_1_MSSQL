/* ============================================================================
   6.1o  Create clean.orders
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Creates the clean schema and clean.orders with real types, NOT NULL where mandatory, primary key, and the date_issue_codes flag column.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : Column list shows DATETIME2(0)/DATE types and the PK.
   ============================================================================ */

USE RawToClean_Lab;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'clean')
    EXEC('CREATE SCHEMA clean');
GO

DROP TABLE IF EXISTS clean.orders;
GO

CREATE TABLE clean.orders (
    order_id                 NVARCHAR(32)   NOT NULL,
    customer_id              NVARCHAR(32)   NOT NULL,
    order_status             NVARCHAR(20)   NOT NULL,
    purchase_ts              DATETIME2(0)   NOT NULL,
    approved_ts              DATETIME2(0)   NULL,
    carrier_ts               DATETIME2(0)   NULL,
    delivered_ts             DATETIME2(0)   NULL,
    estimated_delivery_date  DATE           NOT NULL,
    date_issue_codes         NVARCHAR(100)  NULL,
    CONSTRAINT PK_clean_orders PRIMARY KEY (order_id)
);
GO

SELECT ORDINAL_POSITION, COLUMN_NAME, DATA_TYPE,
       CHARACTER_MAXIMUM_LENGTH, DATETIME_PRECISION, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'clean' AND TABLE_NAME = 'orders'

ORDER BY ORDINAL_POSITION;
GO
