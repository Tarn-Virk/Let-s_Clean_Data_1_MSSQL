/* ============================================================================
   5.6  Timeliness: monthly volume with gap detection
   Status : TESTED on Olist (build notes). The values in the DECLARE lines are the Olist example - change them for your data.
   What   : Builds a calendar (recursive CTE) from first to last month and left-joins the monthly row counts, marking empty months GAP.
   Edit   : @schema, @table, @date_col.
   Pass   : No GAP rows inside the period you intend to report on. A ramp-up or tail-off at the ends is a finding: define a reporting window in gold.
   ============================================================================ */

USE RawToClean_Lab;
GO

DECLARE @schema   SYSNAME = 'raw';
DECLARE @table    SYSNAME = 'orders';
DECLARE @date_col SYSNAME = 'order_purchase_timestamp';
DECLARE @sql      NVARCHAR(MAX);

SET @sql = N'

WITH monthly AS (
    SELECT DATEFROMPARTS(YEAR(d), MONTH(d), 1) AS month_start,
           COUNT(*) AS row_count
    FROM (SELECT TRY_CAST(' + QUOTENAME(@date_col) + N' AS DATETIME2) AS d
          FROM ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table) + N') AS x
    WHERE d IS NOT NULL
        GROUP BY DATEFROMPARTS(YEAR(d), MONTH(d), 1)

),

bounds AS (
    SELECT MIN(month_start) AS first_month, MAX(month_start) AS last_month
        FROM monthly

),

calendar AS (
    SELECT first_month AS month_start, last_month FROM bounds
    UNION ALL
    SELECT DATEADD(MONTH, 1, month_start), last_month
    FROM calendar
        WHERE month_start < last_month

)

SELECT c.month_start,
       ISNULL(m.row_count, 0) AS row_count,
              CASE WHEN m.row_count IS NULL THEN ''GAP'' ELSE '''' END AS flag

FROM calendar AS c
LEFT JOIN monthly AS m ON m.month_start = c.month_start

ORDER BY c.month_start

OPTION (MAXRECURSION 0);';

EXEC sys.sp_executesql @sql;
GO
