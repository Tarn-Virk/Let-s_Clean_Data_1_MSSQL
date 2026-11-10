/* ============================================================================
   3.6b  Full load of raw.orders
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : TRUNCATE then BULK INSERT the whole orders file; reject file is time-stamped.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : Row count = 99441 (data rows in the file).
   ============================================================================ */

USE RawToClean_Lab;
GO

TRUNCATE TABLE raw.orders;
GO

DECLARE @run_stamp NVARCHAR(20) = FORMAT(SYSDATETIME(), 'yyyyMMdd_HHmmss');

DECLARE @src NVARCHAR(400) =
    N'C:\bsg-playbook\01_raw\archive\olist_orders_dataset.csv';

DECLARE @rejects NVARCHAR(400) =
    N'C:\bsg-playbook\02_working\rejects\orders_full_' + @run_stamp + N'.txt';

DECLARE @sql NVARCHAR(MAX) = N'

BULK INSERT raw.orders

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
