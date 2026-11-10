/* ============================================================================
   4.2  Detect what data type each column really holds
   Status : TESTED on Olist (build notes). The values in the DECLARE lines are the Olist example - change them for your data.
   What   : Counts how many non-blank values cast cleanly to INT, DECIMAL and DATETIME2, per column.
   Edit   : @schema, @table.
   Pass   : No pass/fail. A column where castable = non-blank is a candidate for that type; anything less shows how many values break it.
   ============================================================================ */

USE RawToClean_Lab;
GO

DECLARE @schema SYSNAME = 'raw';
DECLARE @table  SYSNAME = 'orders';
DECLARE @sql    NVARCHAR(MAX);

SELECT @sql = STRING_AGG(CAST(
      N'SELECT ' + CAST(ORDINAL_POSITION AS NVARCHAR(10)) + N' AS position, '
    + N'''' + COLUMN_NAME + N''' AS column_name, '
    + N'SUM(CASE WHEN LTRIM(RTRIM(' + QUOTENAME(COLUMN_NAME) + N')) <> '''' THEN 1 ELSE 0 END) AS filled_values, '
    + N'SUM(CASE WHEN LTRIM(RTRIM(' + QUOTENAME(COLUMN_NAME) + N')) <> '''' AND TRY_CAST(' + QUOTENAME(COLUMN_NAME) + N' AS INT) IS NOT NULL THEN 1 ELSE 0 END) AS int_ok, '
    + N'SUM(CASE WHEN LTRIM(RTRIM(' + QUOTENAME(COLUMN_NAME) + N')) <> '''' AND TRY_CAST(' + QUOTENAME(COLUMN_NAME) + N' AS DECIMAL(18,4)) IS NOT NULL THEN 1 ELSE 0 END) AS decimal_ok, '
    + N'SUM(CASE WHEN LTRIM(RTRIM(' + QUOTENAME(COLUMN_NAME) + N')) <> '''' AND TRY_CAST(' + QUOTENAME(COLUMN_NAME) + N' AS DATETIME2) IS NOT NULL THEN 1 ELSE 0 END) AS date_ok '
    + N'FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
    AS NVARCHAR(MAX)), N' UNION ALL ')
    WITHIN GROUP (ORDER BY ORDINAL_POSITION)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = @table;

SET @sql = @sql + N' ORDER BY position;';

EXEC sys.sp_executesql @sql;
GO
