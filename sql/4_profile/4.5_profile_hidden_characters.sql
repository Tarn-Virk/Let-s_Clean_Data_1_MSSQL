/* ============================================================================
   4.5  Profile v3: leading/trailing spaces, control characters, quotes
   Status : TESTED on Olist (build notes). The values in the DECLARE lines are the Olist example - change them for your data.
   What   : Per column: null / blank / padded (leading or trailing space) counts, control characters (tab, line-feed, carriage-return) inside values, distinct values, case variants, min/max length.
   Edit   : @schema, @table.
   Pass   : No pass/fail. Any non-zero count needs a decision in the clean step (TRIM, REPLACE, or flag).
   ============================================================================ */

USE RawToClean_Lab;
GO

DECLARE @schema SYSNAME = 'raw';
DECLARE @table  SYSNAME = 'order_items';
DECLARE @sql    NVARCHAR(MAX);

SELECT @sql = STRING_AGG(CAST(
      N'SELECT ' + CAST(ORDINAL_POSITION AS NVARCHAR(10)) + N' AS position, '
    + N'''' + COLUMN_NAME + N''' AS column_name, '
    + N'COUNT(*) AS total_rows, '
    + N'SUM(CASE WHEN ' + QUOTENAME(COLUMN_NAME) + N' IS NULL THEN 1 ELSE 0 END) AS null_count, '
    + N'CAST(100.0 * SUM(CASE WHEN ' + QUOTENAME(COLUMN_NAME) + N' IS NULL THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS null_pct, '
    + N'SUM(CASE WHEN LTRIM(RTRIM(' + QUOTENAME(COLUMN_NAME) + N')) = '''' THEN 1 ELSE 0 END) AS blank_count, '
    + N'SUM(CASE WHEN DATALENGTH(' + QUOTENAME(COLUMN_NAME) + N') <> DATALENGTH(LTRIM(RTRIM(' + QUOTENAME(COLUMN_NAME) + N'))) THEN 1 ELSE 0 END) AS padded_count, '
    + N'SUM(CASE WHEN CHARINDEX(CHAR(9), ' + QUOTENAME(COLUMN_NAME) + N') > 0 '
    + N'OR CHARINDEX(CHAR(10), ' + QUOTENAME(COLUMN_NAME) + N') > 0 '
    + N'OR CHARINDEX(CHAR(13), ' + QUOTENAME(COLUMN_NAME) + N') > 0 THEN 1 ELSE 0 END) AS control_char_count, '
    + N'COUNT(DISTINCT ' + QUOTENAME(COLUMN_NAME) + N') AS distinct_count, '
    + N'COUNT(DISTINCT ' + QUOTENAME(COLUMN_NAME) + N' COLLATE Latin1_General_BIN2) - COUNT(DISTINCT ' + QUOTENAME(COLUMN_NAME) + N') AS case_variants, '
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
