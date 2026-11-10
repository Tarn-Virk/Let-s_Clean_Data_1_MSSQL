/* ============================================================================
   4.3  Min / max of every date-like column
   Status : TESTED on Olist (build notes). The values in the DECLARE lines are the Olist example - change them for your data.
   What   : Earliest value, latest value and count of future dates for each column that casts to a date.
   Edit   : @schema, @table.
   Pass   : No pass/fail. Dates outside the business reality (year 1900, year 2100) are findings.
   ============================================================================ */

USE RawToClean_Lab;
GO

DECLARE @schema SYSNAME = 'raw';
DECLARE @table  SYSNAME = 'orders';
DECLARE @sql    NVARCHAR(MAX);

SELECT @sql = STRING_AGG(CAST(
      N'SELECT ' + CAST(ORDINAL_POSITION AS NVARCHAR(10)) + N' AS position, '
    + N'''' + COLUMN_NAME + N''' AS column_name, '
    + N'MIN(TRY_CAST(' + QUOTENAME(COLUMN_NAME) + N' AS DATETIME2)) AS earliest, '
    + N'MAX(TRY_CAST(' + QUOTENAME(COLUMN_NAME) + N' AS DATETIME2)) AS latest, '
    + N'SUM(CASE WHEN TRY_CAST(' + QUOTENAME(COLUMN_NAME) + N' AS DATETIME2) > SYSDATETIME() THEN 1 ELSE 0 END) AS future_dates '
    + N'FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
    AS NVARCHAR(MAX)), N' UNION ALL ')
    WITHIN GROUP (ORDER BY ORDINAL_POSITION)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = @table;

SET @sql = N'SELECT * FROM (' + @sql + N') AS t WHERE earliest IS NOT NULL ORDER BY position;';

EXEC sys.sp_executesql @sql;
GO
