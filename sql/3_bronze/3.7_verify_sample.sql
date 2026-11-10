/* ============================================================================
   3.7  Verify the sample before the full load
   Status : Part 2 TESTED on Olist (build notes). Parts 1 and 3 are generic rewrites
            of the tested orders-only checks (NEW - not yet run).
   What   : 1) eyeball 10 rows  2) how blanks were stored (NULL or empty string)
            3) header row loaded as data? stray quote characters left in values?
   Edit   : @schema and @table in each part.
   Pass   : values sit under the right headers; header_rows_loaded = 0;
            rows_with_stray_quotes = 0. Record the blank rule from part 2:
            NULL -> test IS NULL | empty string -> test = '' | mixed -> test both.
   ============================================================================ */
USE RawToClean_Lab;
GO

-- PART 1: eyeball. No ORDER BY, so these 10 rows are arbitrary (fine for eyeballing).
DECLARE @schema SYSNAME = N'raw';
DECLARE @table  SYSNAME = N'orders';
DECLARE @sql    NVARCHAR(MAX) = N'SELECT TOP (10) * FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N';';
EXEC sys.sp_executesql @sql;
GO

-- PART 2: how were blanks stored? (tested)
DECLARE @schema SYSNAME = 'raw';
DECLARE @table  SYSNAME = 'orders';
DECLARE @sql    NVARCHAR(MAX);

SELECT @sql = STRING_AGG(CAST(
      N'SELECT ''' + COLUMN_NAME + N''' AS column_name, '
    + N'COUNT(*) AS total_rows, '
    + N'SUM(CASE WHEN ' + QUOTENAME(COLUMN_NAME) + N' IS NULL THEN 1 ELSE 0 END) AS null_count, '
    + N'SUM(CASE WHEN ' + QUOTENAME(COLUMN_NAME) + N' = '''' THEN 1 ELSE 0 END) AS empty_string_count '
    + N'FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
    AS NVARCHAR(MAX)), N' UNION ALL ')
    WITHIN GROUP (ORDER BY ORDINAL_POSITION)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = @table;

EXEC sys.sp_executesql @sql;
GO


-- PART 3: header loaded as data? stray quotes? (generic)
DECLARE @schema SYSNAME = N'raw';
DECLARE @table  SYSNAME = N'orders';
DECLARE @tbl    NVARCHAR(300) = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
DECLARE @cols   NVARCHAR(MAX);
DECLARE @first  SYSNAME;
DECLARE @sql    NVARCHAR(MAX);

SELECT @cols  = STRING_AGG(CAST(QUOTENAME(COLUMN_NAME) AS NVARCHAR(MAX)), N', ') WITHIN GROUP (ORDER BY ORDINAL_POSITION),
       @first = MIN(CASE WHEN ORDINAL_POSITION = 1 THEN COLUMN_NAME END)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = @table;

SET @sql = N'SELECT COUNT(*) AS rows_loaded, '
         + N'SUM(CASE WHEN ' + QUOTENAME(@first) + N' = N''' + REPLACE(@first, '''', '''''') + N''' THEN 1 ELSE 0 END) AS header_rows_loaded, '
         + N'SUM(CASE WHEN CONCAT(' + @cols + N', N'''') LIKE N''%"%'' THEN 1 ELSE 0 END) AS rows_with_stray_quotes '
         + N'FROM ' + @tbl + N';';
EXEC sys.sp_executesql @sql;
GO
