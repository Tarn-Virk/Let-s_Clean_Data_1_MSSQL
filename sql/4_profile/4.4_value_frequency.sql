/* ============================================================================
   4.4  Frequency of values in one column
   Status : TESTED on Olist (build notes). The values in the DECLARE lines are the Olist example - change them for your data.
   What   : Lists each distinct value with its count and percentage. Use on status / category / code columns.
   Edit   : @schema, @table, @col.
   Pass   : No pass/fail. Typos and case variants (Delivered / delivered) show up as separate rows.
   ============================================================================ */

USE RawToClean_Lab;
GO

DECLARE @schema SYSNAME = 'raw';
DECLARE @table  SYSNAME = 'orders';
DECLARE @col    SYSNAME = 'order_status';

DECLARE @sql NVARCHAR(MAX) =
    N'SELECT ' + QUOTENAME(@col) + N' COLLATE Latin1_General_BIN2 AS value, '
  + N'COUNT(*) AS n, '
  + N'CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) AS pct '
  + N'FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
  + N' GROUP BY ' + QUOTENAME(@col) + N' COLLATE Latin1_General_BIN2'
  + N' ORDER BY n DESC;';

EXEC sys.sp_executesql @sql;
GO
