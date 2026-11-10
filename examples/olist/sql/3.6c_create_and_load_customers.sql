/* ============================================================================
   3.6c  Create and load raw.customers
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Creates raw.customers (5 text columns) and loads the customers file with the same pattern.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : Row count = 99441.
   ============================================================================ */

USE RawToClean_Lab;
GO

IF OBJECT_ID('raw.customers', 'U') IS NULL

BEGIN
    CREATE TABLE raw.customers (
        customer_id                NVARCHAR(50),
        customer_unique_id         NVARCHAR(50),
        customer_zip_code_prefix   NVARCHAR(50),
        customer_city              NVARCHAR(50),
        customer_state             NVARCHAR(50)
    );
END

GO

TRUNCATE TABLE raw.customers;
GO

DECLARE @run_stamp NVARCHAR(20) = FORMAT(SYSDATETIME(), 'yyyyMMdd_HHmmss');

DECLARE @src NVARCHAR(400) =
    N'C:\bsg-playbook\01_raw\archive\olist_customers_dataset.csv';

DECLARE @rejects NVARCHAR(400) =
    N'C:\bsg-playbook\02_working\rejects\customers_full_' + @run_stamp + N'.txt';

DECLARE @sql NVARCHAR(MAX) = N'

BULK INSERT raw.customers

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
