/* ============================================================================
   4.7  Format check with patterns (zip = digits, state = capital letters ...)
   Status : TESTED on Olist (build notes). The values in the DECLARE lines are the Olist example - change them for your data.
   What   : Each rule is: column + a BAD pattern + plain-English meaning. Counts violations and lists the top offending values. Uses a binary collation so a-z and A-Z are really different.
   Edit   : The @rules table (rule_no, column_name, bad_pattern, meaning) and @schema, @table.
   Pass   : violations = 0 on every row. Otherwise the second grid shows the offending values with counts.
   ============================================================================ */

USE RawToClean_Lab;
GO

DECLARE @schema SYSNAME = 'raw';
DECLARE @table  SYSNAME = 'customers';
DECLARE @sql    NVARCHAR(MAX);

DECLARE @rules TABLE (rule_no INT, column_name SYSNAME, bad_pattern NVARCHAR(50), meaning NVARCHAR(100));
INSERT INTO @rules (rule_no, column_name, bad_pattern, meaning) VALUES
    (1, 'customer_zip_code_prefix', '%[^0-9]%',     'digits only'),
    (2, 'customer_state',           '%[^A-Z]%',     'capital letters only'),
    (3, 'customer_city',            '%[^a-z ''-]%', 'lowercase letters, spaces, apostrophes and hyphens only');

SELECT @sql = STRING_AGG(CAST(
      N'SELECT ' + CAST(rule_no AS NVARCHAR(10)) + N' AS rule_no, '
    + QUOTENAME(column_name, '''') + N' AS column_name, '
    + QUOTENAME(meaning, '''') + N' AS allowed, '
    + N'COUNT(*) AS rows_checked, '
    + N'SUM(CASE WHEN ' + QUOTENAME(column_name) + N' COLLATE Latin1_General_BIN2 LIKE '
    + QUOTENAME(bad_pattern, '''') + N' THEN 1 ELSE 0 END) AS violations '
    + N'FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
    AS NVARCHAR(MAX)), N' UNION ALL ')
    WITHIN GROUP (ORDER BY rule_no)
FROM @rules;

SET @sql = N'SELECT column_name, allowed, rows_checked, violations, '
         + N'CASE WHEN violations = 0 THEN ''PASS'' ELSE ''FAIL'' END AS result '
         + N'FROM (' + @sql + N') AS t ORDER BY rule_no;';

EXEC sys.sp_executesql @sql;

SELECT @sql = STRING_AGG(CAST(
      N'SELECT * FROM (SELECT TOP (10) ' + CAST(rule_no AS NVARCHAR(10)) + N' AS rule_no, '
    + QUOTENAME(column_name, '''') + N' AS column_name, '
    + QUOTENAME(column_name) + N' COLLATE Latin1_General_BIN2 AS offending_value, '
    + N'COUNT(*) AS n '
    + N'FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
    + N' WHERE ' + QUOTENAME(column_name) + N' COLLATE Latin1_General_BIN2 LIKE '
    + QUOTENAME(bad_pattern, '''')
    + N' GROUP BY ' + QUOTENAME(column_name) + N' COLLATE Latin1_General_BIN2 '
    + N'ORDER BY COUNT(*) DESC) AS r' + CAST(rule_no AS NVARCHAR(10))
    AS NVARCHAR(MAX)), N' UNION ALL ')
    WITHIN GROUP (ORDER BY rule_no)
FROM @rules;

SET @sql = @sql + N' ORDER BY rule_no, n DESC;';

EXEC sys.sp_executesql @sql;
GO
