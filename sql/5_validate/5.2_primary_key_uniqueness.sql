/* ============================================================================
   5.2  Uniqueness: is the declared key really unique and never blank?
   Status : NEW (not yet run on a live server). Same dynamic-SQL pattern as the tested scripts.
   What   : For a single or composite key (comma list) reports total rows, distinct
            key combinations, duplicate groups, rows with a blank key part, then
            lists the 10 largest duplicate groups.
   Edit   : @schema, @table, @key_cols.
   Pass   : duplicate_key_groups = 0 and rows_with_blank_key_part = 0 (result PASS)
            and total_rows = distinct_keys.
   Note   : the grain of a table is its key. If this fails, do NOT add DISTINCT to
            hide it - find out why (step 5.3b style) and decide: flag, reject, or
            change the declared grain.
   ============================================================================ */
USE RawToClean_Lab;
GO

/* ---------- CONFIG ---------- */
DECLARE @schema   SYSNAME       = N'raw';
DECLARE @table    SYSNAME       = N'order_items';
DECLARE @key_cols NVARCHAR(MAX) = N'order_id,order_item_id';   -- one column, or several separated by commas
/* ---------- END CONFIG ---------- */

DECLARE @tbl   NVARCHAR(300) = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
DECLARE @cols  NVARCHAR(MAX);
DECLARE @blank NVARCHAR(MAX);
DECLARE @sql   NVARCHAR(MAX);

SELECT @cols = STRING_AGG(CAST(QUOTENAME(LTRIM(RTRIM(s.value))) AS NVARCHAR(MAX)), N', ')
FROM STRING_SPLIT(@key_cols, N',') AS s;

SELECT @blank = STRING_AGG(CAST(
         QUOTENAME(LTRIM(RTRIM(s.value))) + N' IS NULL OR LTRIM(RTRIM(' + QUOTENAME(LTRIM(RTRIM(s.value))) + N')) = '''''
         AS NVARCHAR(MAX)), N' OR ')
FROM STRING_SPLIT(@key_cols, N',') AS s;

SET @sql = N'SELECT total_rows, distinct_keys, duplicate_key_groups, rows_with_blank_key_part, '
         + N'CASE WHEN duplicate_key_groups = 0 AND rows_with_blank_key_part = 0 AND total_rows = distinct_keys '
         + N'THEN ''PASS'' ELSE ''FAIL'' END AS result FROM ('
         + N'SELECT (SELECT COUNT(*) FROM ' + @tbl + N') AS total_rows, '
         + N'(SELECT COUNT(*) FROM (SELECT ' + @cols + N' FROM ' + @tbl + N' GROUP BY ' + @cols + N') AS k) AS distinct_keys, '
         + N'(SELECT COUNT(*) FROM (SELECT ' + @cols + N' FROM ' + @tbl + N' GROUP BY ' + @cols + N' HAVING COUNT(*) > 1) AS d) AS duplicate_key_groups, '
         + N'(SELECT COUNT(*) FROM ' + @tbl + N' WHERE ' + @blank + N') AS rows_with_blank_key_part'
         + N') AS t;';
EXEC sys.sp_executesql @sql;

SET @sql = N'SELECT TOP (10) ' + @cols + N', COUNT(*) AS copies FROM ' + @tbl
         + N' GROUP BY ' + @cols + N' HAVING COUNT(*) > 1 ORDER BY COUNT(*) DESC;';
EXEC sys.sp_executesql @sql;
GO
