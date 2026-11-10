/* ============================================================================
   5.1  Completeness: mandatory columns must never be blank
   Status : TESTED on Olist (build notes). The values in the DECLARE lines are the Olist example - change them for your data.
   What   : Counts NULL or empty/space-only values in each column you list as mandatory.
   Edit   : @schema, @table, @mandatory (comma list).
   Pass   : missing_count = 0 and result PASS for every row.
   ============================================================================ */

USE RawToClean_Lab;
GO

DECLARE @schema    SYSNAME       = 'raw';
DECLARE @table     SYSNAME       = 'orders';
DECLARE @mandatory NVARCHAR(MAX) = 'order_id,customer_id,order_status,order_purchase_timestamp,order_estimated_delivery_date';
DECLARE @sql       NVARCHAR(MAX);

SELECT @sql = STRING_AGG(CAST(
      N'SELECT ' + CAST(c.ORDINAL_POSITION AS NVARCHAR(10)) + N' AS position, '
    + N'''' + c.COLUMN_NAME + N''' AS column_name, '
    + N'SUM(CASE WHEN ' + QUOTENAME(c.COLUMN_NAME) + N' IS NULL '
    + N'OR LTRIM(RTRIM(' + QUOTENAME(c.COLUMN_NAME) + N')) = '''' THEN 1 ELSE 0 END) AS missing_count '
    + N'FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
    AS NVARCHAR(MAX)), N' UNION ALL ')
    WITHIN GROUP (ORDER BY c.ORDINAL_POSITION)
FROM INFORMATION_SCHEMA.COLUMNS AS c
JOIN STRING_SPLIT(@mandatory, ',') AS s
  ON c.COLUMN_NAME = LTRIM(RTRIM(s.value))
WHERE c.TABLE_SCHEMA = @schema AND c.TABLE_NAME = @table;

SET @sql = N'SELECT column_name, missing_count, '
         + N'CASE WHEN missing_count = 0 THEN ''PASS'' ELSE ''FAIL'' END AS result '
         + N'FROM (' + @sql + N') AS t ORDER BY position;';

EXEC sys.sp_executesql @sql;
GO
