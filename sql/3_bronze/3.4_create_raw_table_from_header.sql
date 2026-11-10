/* ============================================================================
   3.4  Create the raw table from the file header
   Status : NEW in this framework (not yet run on a live server) - if it errors,
            use the manual template in examples/olist/sql/3.4_create_raw_orders_manual.sql
   What   : Reads line 1 of the CSV, builds a CREATE TABLE with one text column
            per header name (same order as the file), shows the generated code,
            and creates the table only if it does not exist yet.
   Why    : BULK INSERT maps file fields to table columns by POSITION. Building
            the table from the header removes copy-paste order mistakes.
   Edit   : the CONFIG block only.
   Pass   : last grid shows PASS on every row and the column count equals the
            header column count you recorded in step 2.3.
   ============================================================================ */
USE RawToClean_Lab;
GO

/* ---------- CONFIG ---------- */
DECLARE @project_root NVARCHAR(300) = N'C:\bsg-playbook\';                         -- folder that holds 01_raw, 02_working, 03_outputs (keep the trailing \)
DECLARE @file_path    NVARCHAR(300) = N'01_raw\archive\olist_orders_dataset.csv';  -- CSV path, relative to @project_root
DECLARE @schema       SYSNAME       = N'raw';
DECLARE @table        SYSNAME       = N'orders';                                   -- name of the raw table to create
DECLARE @field_term   NVARCHAR(10)  = N',';                                        -- delimiter from step 2.2 (tab = NCHAR(9))
DECLARE @row_term     NVARCHAR(10)  = N'0x0a';                                     -- LF = 0x0a, CRLF = \r\n (step 2.2)
DECLARE @codepage     NVARCHAR(10)  = N'65001';                                    -- 65001 = UTF-8
DECLARE @col_width    NVARCHAR(10)  = N'4000';                                     -- raw text width per column (a number up to 4000, or MAX)
/* ---------- END CONFIG ---------- */

DECLARE @src  NVARCHAR(600) = @project_root + @file_path;
DECLARE @tbl  NVARCHAR(300) = QUOTENAME(@schema) + N'.' + QUOTENAME(@table);
DECLARE @sep  NVARCHAR(10)  = N',' + CHAR(10);
DECLARE @bulk_term NVARCHAR(10) = CASE WHEN @field_term = NCHAR(9) THEN N'\t' ELSE @field_term END;
DECLARE @sql    NVARCHAR(MAX);
DECLARE @header NVARCHAR(MAX);
DECLARE @ddl    NVARCHAR(MAX);

-- 1) read line 1 of the file into a one-column temp table
DROP TABLE IF EXISTS #header_line;
CREATE TABLE #header_line (line NVARCHAR(MAX));

SET @sql = N'BULK INSERT #header_line FROM ''' + @src + N''' WITH ('
         + N'FIRSTROW = 1, LASTROW = 1, FIELDTERMINATOR = ''0x0b'', '
         + N'ROWTERMINATOR = ''' + @row_term + N''', CODEPAGE = ''' + @codepage + N''');';
EXEC sys.sp_executesql @sql;

SELECT @header = line FROM #header_line;
-- strip BOM, carriage return and quote characters
SET @header = REPLACE(REPLACE(REPLACE(@header, NCHAR(65279), N''), NCHAR(13), N''), N'"', N'');

-- 2) split the header into one row per column name
DECLARE @json NVARCHAR(MAX) = N'["' + REPLACE(REPLACE(@header, N'\', N'\\'), @field_term, N'","') + N'"]';

DROP TABLE IF EXISTS #cols;
SELECT CAST(j.[key] AS INT) + 1 AS pos,
       LTRIM(RTRIM(j.[value]))   AS col_name
INTO   #cols
FROM   OPENJSON(@json) AS j;

-- 3) sanity check on the names
SELECT N'columns found'   AS check_name, COUNT(*) AS value FROM #cols
UNION ALL
SELECT N'blank names',     COUNT(*) FROM #cols WHERE col_name = N''
UNION ALL
SELECT N'duplicate names', COUNT(*) FROM (SELECT col_name FROM #cols GROUP BY col_name HAVING COUNT(*) > 1) AS d;

-- 4) build the CREATE TABLE text, show it, create the table if missing
SELECT @ddl = N'CREATE TABLE ' + @tbl + N' (' + CHAR(10)
            + STRING_AGG(CAST(N'    ' + QUOTENAME(col_name) + N' NVARCHAR(' + @col_width + N')' AS NVARCHAR(MAX)), @sep)
                         WITHIN GROUP (ORDER BY pos)
            + CHAR(10) + N');'
FROM #cols;

SELECT @ddl AS generated_create_table;

IF OBJECT_ID(@tbl, N'U') IS NULL
BEGIN
    EXEC sys.sp_executesql @ddl;
    SELECT N'created ' + @tbl AS status;
END
ELSE
    SELECT N'table already exists, nothing changed: ' + @tbl AS status;

-- 5) prove the table columns match the file header, position by position
SELECT c.pos             AS header_position,
       c.col_name        AS header_name,
       t.ORDINAL_POSITION AS table_position,
       t.COLUMN_NAME     AS table_name,
       CASE WHEN c.col_name COLLATE Latin1_General_BIN2 = t.COLUMN_NAME COLLATE Latin1_General_BIN2
            THEN 'PASS' ELSE 'FAIL' END AS result
FROM #cols AS c
FULL OUTER JOIN (SELECT ORDINAL_POSITION, COLUMN_NAME
                 FROM INFORMATION_SCHEMA.COLUMNS
                 WHERE TABLE_SCHEMA = @schema AND TABLE_NAME = @table) AS t
       ON t.ORDINAL_POSITION = c.pos
ORDER BY COALESCE(c.pos, t.ORDINAL_POSITION);
GO
