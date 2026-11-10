/* ============================================================================
   3.5  Test the error-handling safety net on a tiny practice file
   Status : Logic TESTED on Olist (build notes). Paths now come from @project_root.
   What   : Loads 02_working\errortest.csv (4 rows, row 3 deliberately too long)
            into a temp table with 3-character columns. SQL Server must load
            rows 1, 2, 4 and write row 3 to a reject file with the reason.
   Rule   : rows in table + rows in reject file = rows in source file.
   Edit   : @project_root only.
   Pass   : grid shows 3 rows (1 aaa, 2 bbb, 4 ddd); 02_working\rejects holds
            errortest_rejects_<stamp>.txt and a matching .Error.Txt file.
   ============================================================================ */
USE RawToClean_Lab;
GO

/* ---------- CONFIG ---------- */
DECLARE @project_root NVARCHAR(300) = N'C:\bsg-playbook\';   -- folder that holds 01_raw, 02_working, 03_outputs (keep the trailing \)
/* ---------- END CONFIG ---------- */

DECLARE @run_stamp NVARCHAR(20) = FORMAT(SYSDATETIME(), 'yyyyMMdd_HHmmss');
DECLARE @sql NVARCHAR(MAX);

DROP TABLE IF EXISTS #error_test;
CREATE TABLE #error_test (id NVARCHAR(3), label NVARCHAR(3));

SET @sql = N'BULK INSERT #error_test FROM ''' + @project_root + N'02_working\errortest.csv'' WITH ('
         + N'FORMAT = ''CSV'', FIRSTROW = 2, FIELDTERMINATOR = '','', ROWTERMINATOR = ''0x0a'', '
         + N'CODEPAGE = ''65001'', MAXERRORS = 10, '
         + N'ERRORFILE = ''' + @project_root + N'02_working\rejects\errortest_rejects_' + @run_stamp + N'.txt'');';
EXEC sys.sp_executesql @sql;

SELECT id, label FROM #error_test;
GO
