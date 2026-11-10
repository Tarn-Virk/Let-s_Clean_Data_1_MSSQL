/* ============================================================================
   3.8  Check the raw table is ready / loaded
   Status : NEW generic version of the tested orders-only check (not yet run)
   What   : Column count and row count of one raw table.
   Edit   : @schema, @table.
   Pass   : column_count equals the header column count from step 2.3;
            row_count equals the data-row count from step 2.5.
   ============================================================================ */
USE RawToClean_Lab;
GO

DECLARE @schema SYSNAME = N'raw';
DECLARE @table  SYSNAME = N'orders';
DECLARE @sql    NVARCHAR(MAX);

SET @sql = N'SELECT '
         + N'(SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = @s AND TABLE_NAME = @t) AS column_count, '
         + N'(SELECT COUNT(*) FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N') AS row_count;';
EXEC sys.sp_executesql @sql, N'@s SYSNAME, @t SYSNAME', @s = @schema, @t = @table;
GO
