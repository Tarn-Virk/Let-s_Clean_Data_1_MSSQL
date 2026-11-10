/* ============================================================================
   5.5  Consistency: date A must not be later than date B
   Status : TESTED on Olist (build notes). The values in the DECLARE lines are the Olist example - change them for your data.
   What   : Each rule is earlier_col, later_col. Counts rows where both parse and later < earlier.
   Edit   : The @rules table and @schema, @table.
   Pass   : violations = 0. Violations are not deleted: they become reason-code flags in step 6.
   ============================================================================ */

USE RawToClean_Lab;
GO

DECLARE @schema SYSNAME = 'raw';
DECLARE @table  SYSNAME = 'orders';
DECLARE @sql    NVARCHAR(MAX);

DECLARE @rules TABLE (rule_no INT, earlier_col SYSNAME, later_col SYSNAME);
INSERT INTO @rules (rule_no, earlier_col, later_col) VALUES
    (1, 'order_purchase_timestamp',     'order_approved_at'),
    (2, 'order_purchase_timestamp',     'order_delivered_carrier_date'),
    (3, 'order_purchase_timestamp',     'order_delivered_customer_date'),
    (4, 'order_approved_at',            'order_delivered_carrier_date'),
    (5, 'order_approved_at',            'order_delivered_customer_date'),
    (6, 'order_delivered_carrier_date', 'order_delivered_customer_date'),
    (7, 'order_purchase_timestamp',     'order_estimated_delivery_date');

SELECT @sql = STRING_AGG(CAST(
      N'SELECT ' + CAST(rule_no AS NVARCHAR(10)) + N' AS rule_no, '
    + N'''' + earlier_col + N' <= ' + later_col + N''' AS check_name, '
    + N'SUM(CASE WHEN TRY_CAST(' + QUOTENAME(earlier_col) + N' AS DATETIME2) IS NOT NULL '
    + N'AND TRY_CAST(' + QUOTENAME(later_col) + N' AS DATETIME2) IS NOT NULL THEN 1 ELSE 0 END) AS rows_compared, '
    + N'SUM(CASE WHEN TRY_CAST(' + QUOTENAME(later_col) + N' AS DATETIME2) '
    + N'< TRY_CAST(' + QUOTENAME(earlier_col) + N' AS DATETIME2) THEN 1 ELSE 0 END) AS violations '
    + N'FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
    AS NVARCHAR(MAX)), N' UNION ALL ')
    WITHIN GROUP (ORDER BY rule_no)
FROM @rules;

SET @sql = N'SELECT check_name, rows_compared, violations, '
         + N'CASE WHEN violations = 0 THEN ''PASS'' ELSE ''FAIL'' END AS result '
         + N'FROM (' + @sql + N') AS t ORDER BY rule_no;';

EXEC sys.sp_executesql @sql;
GO
