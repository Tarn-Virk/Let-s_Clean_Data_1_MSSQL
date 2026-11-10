/* ============================================================================
   5.4  Validity: values must come from an allowed list
   Status : NEW (not yet run on a live server)
   What   : Each rule is: column + comma list of allowed values. Counts non-blank
            values not in the list (exact, case-sensitive match) and shows the
            offending values with counts.
   Edit   : @schema, @table and the @rules rows.
   Pass   : violations = 0 on every rule. Case variants such as 'Delivered' vs
            'delivered' count as violations on purpose - they are real defects.
   Get the list from step 4.4 (value frequency), do not guess it.
   ============================================================================ */
USE RawToClean_Lab;
GO

/* ---------- CONFIG ---------- */
DECLARE @schema SYSNAME = N'raw';
DECLARE @table  SYSNAME = N'orders';
DECLARE @rules TABLE (rule_no INT, column_name SYSNAME, allowed_values NVARCHAR(MAX));
INSERT INTO @rules (rule_no, column_name, allowed_values) VALUES
    (1, N'order_status', N'delivered,shipped,canceled,unavailable,invoiced,processing,created,approved');
/* ---------- END CONFIG ---------- */

DECLARE @tbl NVARCHAR(300) = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
DECLARE @sql NVARCHAR(MAX);

-- 1) violation counts per rule
SELECT @sql = STRING_AGG(CAST(
      N'SELECT ' + CAST(r.rule_no AS NVARCHAR(10)) + N' AS rule_no, '
    + QUOTENAME(r.column_name, '''') + N' AS column_name, '
    + N'COUNT(*) AS rows_checked, '
    + N'SUM(CASE WHEN NULLIF(LTRIM(RTRIM(' + QUOTENAME(r.column_name) + N')), N'''') IS NOT NULL '
    + N'AND LTRIM(RTRIM(' + QUOTENAME(r.column_name) + N')) COLLATE Latin1_General_BIN2 NOT IN (' + a.in_list + N') '
    + N'THEN 1 ELSE 0 END) AS violations '
    + N'FROM ' + @tbl
    AS NVARCHAR(MAX)), N' UNION ALL ')
    WITHIN GROUP (ORDER BY r.rule_no)
FROM @rules AS r
CROSS APPLY (SELECT STRING_AGG(CAST(N'N' + QUOTENAME(LTRIM(RTRIM(s.value)), '''') AS NVARCHAR(MAX)), N', ') AS in_list
             FROM STRING_SPLIT(r.allowed_values, N',') AS s) AS a;

SET @sql = N'SELECT column_name, rows_checked, violations, '
         + N'CASE WHEN violations = 0 THEN ''PASS'' ELSE ''FAIL'' END AS result '
         + N'FROM (' + @sql + N') AS t ORDER BY rule_no;';
EXEC sys.sp_executesql @sql;

-- 2) the offending values (top 10 per rule)
SELECT @sql = STRING_AGG(CAST(
      N'SELECT * FROM (SELECT TOP (10) ' + CAST(r.rule_no AS NVARCHAR(10)) + N' AS rule_no, '
    + QUOTENAME(r.column_name, '''') + N' AS column_name, '
    + QUOTENAME(r.column_name) + N' COLLATE Latin1_General_BIN2 AS offending_value, COUNT(*) AS n '
    + N'FROM ' + @tbl
    + N' WHERE NULLIF(LTRIM(RTRIM(' + QUOTENAME(r.column_name) + N')), N'''') IS NOT NULL '
    + N'AND LTRIM(RTRIM(' + QUOTENAME(r.column_name) + N')) COLLATE Latin1_General_BIN2 NOT IN (' + a.in_list + N') '
    + N'GROUP BY ' + QUOTENAME(r.column_name) + N' COLLATE Latin1_General_BIN2 '
    + N'ORDER BY COUNT(*) DESC) AS r' + CAST(r.rule_no AS NVARCHAR(10))
    AS NVARCHAR(MAX)), N' UNION ALL ')
    WITHIN GROUP (ORDER BY r.rule_no)
FROM @rules AS r
CROSS APPLY (SELECT STRING_AGG(CAST(N'N' + QUOTENAME(LTRIM(RTRIM(s.value)), '''') AS NVARCHAR(MAX)), N', ') AS in_list
             FROM STRING_SPLIT(r.allowed_values, N',') AS s) AS a;

SET @sql = @sql + N' ORDER BY rule_no, n DESC;';
EXEC sys.sp_executesql @sql;
GO
