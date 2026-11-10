/* ============================================================================
   3.6d  Create and load raw.order_items
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Creates raw.order_items (7 text columns) and loads the order_items file.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : Row count = 112650.
   ============================================================================ */

USE RawToClean_Lab;
GO

IF OBJECT_ID('raw.order_items', 'U') IS NULL

BEGIN
    CREATE TABLE raw.order_items (
        order_id             NVARCHAR(50),
        order_item_id        NVARCHAR(50),
        product_id           NVARCHAR(50),
        seller_id            NVARCHAR(50),
        shipping_limit_date  NVARCHAR(50),
        price                NVARCHAR(50),
        freight_value        NVARCHAR(50)
    );
END

GO

TRUNCATE TABLE raw.order_items;
GO

DECLARE @run_stamp NVARCHAR(20) = FORMAT(SYSDATETIME(), 'yyyyMMdd_HHmmss');

DECLARE @src NVARCHAR(400) =
    N'C:\bsg-playbook\01_raw\archive\olist_order_items_dataset.csv';

DECLARE @rejects NVARCHAR(400) =
    N'C:\bsg-playbook\02_working\rejects\order_items_full_' + @run_stamp + N'.txt';

DECLARE @sql NVARCHAR(MAX) = N'

BULK INSERT raw.order_items

FROM ''' + @src + N'''

WITH (

    FORMAT          = ''CSV'',
    FIELDQUOTE      = ''"'',
    FIRSTROW        = 2,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR   = ''0x0a'',
    CODEPAGE        = ''65001'',
    MAXERRORS       = 10,
        ERRORFILE       = ''' + @rejects + N'''

);';

EXEC sys.sp_executesql @sql;
GO
