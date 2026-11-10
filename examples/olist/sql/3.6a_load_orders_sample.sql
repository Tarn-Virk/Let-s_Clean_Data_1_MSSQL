/* ============================================================================
   3.6a  Load a sample of raw.orders
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : First rows of the orders file into raw.orders with a time-stamped reject file.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : Sample row count matches; no red messages.
   ============================================================================ */

USE RawToClean_Lab;
GO

DECLARE @run_stamp NVARCHAR(20) = FORMAT(SYSDATETIME(), 'yyyyMMdd_HHmmss');

DECLARE @src NVARCHAR(400) =
    N'C:\bsg-playbook\01_raw\archive\olist_orders_dataset.csv';

DECLARE @rejects NVARCHAR(400) =
    N'C:\bsg-playbook\02_working\rejects\orders_sample_' + @run_stamp + N'.txt';

DECLARE @sql NVARCHAR(MAX) = N'

BULK INSERT raw.orders

FROM ''' + @src + N'''

WITH (
    FORMAT          = ''CSV'',
    FIELDQUOTE      = ''"'',
    FIRSTROW        = 2,
    LASTROW         = 1001,
    FIELDTERMINATOR = '','',
    ROWTERMINATOR   = ''0x0a'',
    CODEPAGE        = ''65001'',
    MAXERRORS       = 10,
        ERRORFILE       = ''' + @rejects + N'''

);';

EXEC sys.sp_executesql @sql;
GO
