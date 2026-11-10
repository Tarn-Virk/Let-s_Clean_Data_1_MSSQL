/* ============================================================================
   4.6  Numeric profile: min, max, average, median, decimals
   Status : TESTED on Olist (build notes). The values in the DECLARE lines are the Olist example - change them for your data.
   What   : For the numeric columns you list: how many values are numeric vs not, min, max, average, standard deviation, percentiles (p01, p25, median, p75, p99 via PERCENTILE_CONT), zero and negative counts.
   Edit   : @schema, @table, @numeric (comma list).
   Pass   : No pass/fail. not_numeric above 0, negative prices, or zero where zero is impossible are findings; compare p99 with max to spot outliers.
   ============================================================================ */

USE RawToClean_Lab;
GO

DECLARE @schema  SYSNAME       = 'raw';
DECLARE @table   SYSNAME       = 'order_items';
DECLARE @numeric NVARCHAR(MAX) = 'price,freight_value';
DECLARE @sql     NVARCHAR(MAX);

SELECT @sql = STRING_AGG(CAST(
      N'SELECT ' + CAST(c.ORDINAL_POSITION AS NVARCHAR(10)) + N' AS position, '
    + QUOTENAME(c.COLUMN_NAME, '''') + N' AS column_name, '
    + N'COUNT(*) AS rows_total, '
    + N'SUM(CASE WHEN LTRIM(RTRIM(raw_text)) <> '''' THEN 1 ELSE 0 END) AS filled_values, '
    + N'COUNT(v) AS numeric_values, '
    + N'SUM(CASE WHEN LTRIM(RTRIM(raw_text)) <> '''' AND v IS NULL THEN 1 ELSE 0 END) AS not_numeric, '
    + N'MIN(v) AS min_value, '
    + N'MAX(v) AS max_value, '
    + N'CAST(AVG(v) AS DECIMAL(18,2)) AS avg_value, '
    + N'CAST(STDEV(v) AS DECIMAL(18,2)) AS stdev_value, '
    + N'CAST(MAX(p01) AS DECIMAL(18,2)) AS p01, '
    + N'CAST(MAX(p25) AS DECIMAL(18,2)) AS p25, '
    + N'CAST(MAX(med) AS DECIMAL(18,2)) AS median, '
    + N'CAST(MAX(p75) AS DECIMAL(18,2)) AS p75, '
    + N'CAST(MAX(p99) AS DECIMAL(18,2)) AS p99, '
    + N'SUM(CASE WHEN v = 0 THEN 1 ELSE 0 END) AS zero_count, '
    + N'SUM(CASE WHEN v < 0 THEN 1 ELSE 0 END) AS negative_count '
    + N'FROM (SELECT raw_text, v, '
    + N'PERCENTILE_CONT(0.01) WITHIN GROUP (ORDER BY v) OVER () AS p01, '
    + N'PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY v) OVER () AS p25, '
    + N'PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY v) OVER () AS med, '
    + N'PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY v) OVER () AS p75, '
        + N'PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY v) OVER () AS p99 '

    + N'FROM (SELECT ' + QUOTENAME(c.COLUMN_NAME) + N' AS raw_text, '
    + N'TRY_CAST(NULLIF(LTRIM(RTRIM(' + QUOTENAME(c.COLUMN_NAME) + N')), '''') AS DECIMAL(18,4)) AS v '
    + N'FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N') AS a) AS b'
    AS NVARCHAR(MAX)), N' UNION ALL ')
    WITHIN GROUP (ORDER BY c.ORDINAL_POSITION)
FROM INFORMATION_SCHEMA.COLUMNS AS c
JOIN STRING_SPLIT(@numeric, ',') AS s
  ON c.COLUMN_NAME = LTRIM(RTRIM(s.value))
WHERE c.TABLE_SCHEMA = @schema AND c.TABLE_NAME = @table;

SET @sql = @sql + N' ORDER BY position;';

EXEC sys.sp_executesql @sql;
GO
