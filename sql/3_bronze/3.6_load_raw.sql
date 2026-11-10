/* ============================================================================
   3.6  Load the CSV into the raw table  (SAMPLE first, then FULL)
   Status : Same BULK INSERT settings that ran on Olist. The config wrapper and the
            reconciliation grid are NEW in this framework.
   What   : Empties the raw table, then BULK INSERTs the file. Rejected rows go to
            02_working\rejects with a date-time stamp in the file name, so a re-run
            never hits "error file already exists".
   Run    : 1) @mode = N'SAMPLE'  -> checks the settings on the first @sample_rows rows
            2) step 3.7 checks what landed
            3) @mode = N'FULL'    -> loads everything and reconciles to the file count
   Edit   : the CONFIG block only.
   Pass   : result = PASS (rows_loaded = rows_expected) and no red text in Messages.
   ============================================================================ */
USE RawToClean_Lab;
GO

/* ---------- CONFIG ---------- */
DECLARE @project_root  NVARCHAR(300) = N'C:\bsg-playbook\';                         -- folder that holds 01_raw, 02_working, 03_outputs (keep the trailing \)
DECLARE @file_path     NVARCHAR(300) = N'01_raw\archive\olist_orders_dataset.csv';  -- CSV path, relative to @project_root
DECLARE @schema        SYSNAME       = N'raw';
DECLARE @table         SYSNAME       = N'orders';
DECLARE @mode          NVARCHAR(10)  = N'SAMPLE';   -- SAMPLE = first @sample_rows data rows, FULL = whole file
DECLARE @sample_rows   INT           = 1000;
DECLARE @expected_rows INT           = 99441;       -- data rows counted outside SQL in step 2.5 (used in FULL mode)
DECLARE @field_term    NVARCHAR(10)  = N',';        -- from step 2.2 (tab = \t)
DECLARE @row_term      NVARCHAR(10)  = N'0x0a';     -- LF = 0x0a, CRLF = \r\n
DECLARE @codepage      NVARCHAR(10)  = N'65001';    -- 65001 = UTF-8
DECLARE @max_errors    INT           = 10;          -- rejected rows tolerated before the load is cancelled
/* ---------- END CONFIG ---------- */

DECLARE @run_stamp NVARCHAR(20)  = FORMAT(SYSDATETIME(), 'yyyyMMdd_HHmmss');
DECLARE @src       NVARCHAR(600) = @project_root + @file_path;
DECLARE @rejects   NVARCHAR(600) = @project_root + N'02_working\rejects\' + @table + N'_' + LOWER(@mode) + N'_' + @run_stamp + N'.txt';
DECLARE @tbl       NVARCHAR(300) = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
DECLARE @expected  INT           = CASE WHEN @mode = N'FULL' THEN @expected_rows ELSE @sample_rows END;
DECLARE @sql       NVARCHAR(MAX);
DECLARE @loaded    INT;

-- empty the table first, so every run ends with the same result
SET @sql = N'TRUNCATE TABLE ' + @tbl + N';';
EXEC sys.sp_executesql @sql;

-- the load (row 1 is the header, so FIRSTROW = 2; LASTROW = sample rows + 1 in SAMPLE mode)
SET @sql = N'BULK INSERT ' + @tbl + N' FROM ''' + @src + N''' WITH ('
         + N'FORMAT = ''CSV'', FIELDQUOTE = ''"'', FIRSTROW = 2, '
         + CASE WHEN @mode = N'SAMPLE' THEN N'LASTROW = ' + CAST(@sample_rows + 1 AS NVARCHAR(20)) + N', ' ELSE N'' END
         + N'FIELDTERMINATOR = ''' + @field_term + N''', ROWTERMINATOR = ''' + @row_term + N''', '
         + N'CODEPAGE = ''' + @codepage + N''', MAXERRORS = ' + CAST(@max_errors AS NVARCHAR(10)) + N', '
         + N'ERRORFILE = ''' + @rejects + N''');';
EXEC sys.sp_executesql @sql;

-- reconcile: rows in the table must equal the rows expected
SET @sql = N'SELECT @n = COUNT(*) FROM ' + @tbl + N';';
EXEC sys.sp_executesql @sql, N'@n INT OUTPUT', @n = @loaded OUTPUT;

SELECT @mode     AS mode,
       @expected AS rows_expected,
       @loaded   AS rows_loaded,
       CASE WHEN @loaded = @expected THEN 'PASS' ELSE 'FAIL' END AS result,
       @rejects  AS reject_file_if_any;
GO
