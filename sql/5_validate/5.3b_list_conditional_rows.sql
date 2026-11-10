/* ============================================================================
   5.3b  List the rows behind a conditional-column finding
   Status : TESTED on Olist (build notes). The values in the DECLARE lines are the Olist example - change them for your data.
   What   : Shows the actual rows for one driver value where any of the nullable columns is NULL.
   Edit   : @schema, @table, @driver, @driver_value, @nullable.
   Pass   : Use it to decide if a finding is a real defect or an allowed case.
   ============================================================================ */

USE RawToClean_Lab;
GO

DECLARE @schema       SYSNAME       = 'raw';
DECLARE @table        SYSNAME       = 'orders';
DECLARE @driver       SYSNAME       = 'order_status';
DECLARE @driver_value NVARCHAR(100) = 'delivered';
DECLARE @nullable     NVARCHAR(MAX) = 'order_approved_at,order_delivered_carrier_date,order_delivered_customer_date';
DECLARE @cond         NVARCHAR(MAX);
DECLARE @sql          NVARCHAR(MAX);

SELECT @cond = STRING_AGG(CAST(QUOTENAME(c.COLUMN_NAME) + N' IS NULL' AS NVARCHAR(MAX)), N' OR ')
    WITHIN GROUP (ORDER BY c.ORDINAL_POSITION)
FROM INFORMATION_SCHEMA.COLUMNS AS c
JOIN STRING_SPLIT(@nullable, ',') AS s
  ON c.COLUMN_NAME = LTRIM(RTRIM(s.value))
WHERE c.TABLE_SCHEMA = @schema AND c.TABLE_NAME = @table;

SET @sql = N'SELECT * FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
         + N' WHERE ' + QUOTENAME(@driver) + N' = @v AND (' + @cond + N');';

EXEC sys.sp_executesql @sql, N'@v NVARCHAR(100)', @v = @driver_value;
GO
