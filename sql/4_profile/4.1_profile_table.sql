/* ============================================================================
   4.1  Profile every column of a raw table
   Status : TESTED on Olist (build notes). The values in the DECLARE lines are the Olist example - change them for your data.
   What   : One row per column: rows, NULL count, empty-string count, distinct values, min/max length.
   Edit   : @schema, @table.
   Pass   : No pass/fail. Read it: unexpected blanks, a column with 1 distinct value, lengths near the cap.
   ============================================================================ */

USE RawToClean_Lab;
GO

DECLARE @schema SYSNAME = 'raw';
DECLARE @table  SYSNAME = 'orders';
DECLARE @sql    NVARCHAR(MAX);

SELECT @sql = STRING_AGG(CAST(
      N'SELECT ' + CAST(ORDINAL_POSITION AS NVARCHAR(10)) + N' AS position, '
    + N'''' + COLUMN_NAME + N''' AS column_name, '
    + N'COUNT(*) AS total_rows, '
    + N'SUM(CASE WHEN ' + QUOTENAME(COLUMN_NAME) + N' IS NULL THEN 1 ELSE 0 END) AS null_count, '
    + N'CAST(100.0 * SUM(CASE WHEN ' + QUOTENAME(COLUMN_NAME) + N' IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS null_pct, '
    + N'SUM(CASE WHEN LTRIM(RTRIM(' + QUOTENAME(COLUMN_NAME) + N')) = '''' THEN 1 ELSE 0 END) AS blank_count, '
    + N'COUNT(DISTINCT ' + QUOTENAME(COLUMN_NAME) + N') AS distinct_count, '
    + N'MIN(LEN(' + QUOTENAME(COLUMN_NAME) + N')) AS min_len, '
    + N'MAX(LEN(' + QUOTENAME(COLUMN_NAME) + N')) AS max_len '
    + N'FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
    AS NVARCHAR(MAX)), N' UNION ALL ')
    WITHIN GROUP (ORDER BY ORDINAL_POSITION)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = @table;

SET @sql = @sql + N' ORDER BY position;';

EXEC sys.sp_executesql @sql;
GO
