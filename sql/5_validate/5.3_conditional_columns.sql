/* ============================================================================
   5.3  Completeness: columns that may be blank only for some statuses
   Status : TESTED on Olist (build notes). The values in the DECLARE lines are the Olist example - change them for your data.
   What   : Groups by a driver column (e.g. order_status) and shows how many NULLs each conditional column has per value.
   Edit   : @schema, @table, @driver, @nullable (comma list).
   Pass   : Read, then decide the rule: e.g. delivered orders must have a delivery date, cancelled orders need not.
   ============================================================================ */

USE RawToClean_Lab;
GO

DECLARE @schema   SYSNAME       = 'raw';
DECLARE @table    SYSNAME       = 'orders';
DECLARE @driver   SYSNAME       = 'order_status';
DECLARE @nullable NVARCHAR(MAX) = 'order_approved_at,order_delivered_carrier_date,order_delivered_customer_date';
DECLARE @cols     NVARCHAR(MAX);
DECLARE @sql      NVARCHAR(MAX);

SELECT @cols = STRING_AGG(CAST(
      N'SUM(CASE WHEN ' + QUOTENAME(c.COLUMN_NAME) + N' IS NULL THEN 1 ELSE 0 END) AS '
    + QUOTENAME(c.COLUMN_NAME + N'_null')
    AS NVARCHAR(MAX)), N', ')
    WITHIN GROUP (ORDER BY c.ORDINAL_POSITION)
FROM INFORMATION_SCHEMA.COLUMNS AS c
JOIN STRING_SPLIT(@nullable, ',') AS s
  ON c.COLUMN_NAME = LTRIM(RTRIM(s.value))
WHERE c.TABLE_SCHEMA = @schema AND c.TABLE_NAME = @table;

SET @sql = N'SELECT ' + QUOTENAME(@driver) + N' AS driver_value, COUNT(*) AS total_rows, ' + @cols
         + N' FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
         + N' GROUP BY ' + QUOTENAME(@driver)
         + N' ORDER BY total_rows DESC;';

EXEC sys.sp_executesql @sql;
GO
