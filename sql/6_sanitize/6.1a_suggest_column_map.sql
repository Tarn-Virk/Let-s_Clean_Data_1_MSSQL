/* ============================================================================
   6.1a  Suggest the clean-table column map (data types, nullability)
   Status : NEW (not yet run on a live server). Uses only functions that appear in the tested scripts
            (TRY_CAST, NULLIF, STRING_AGG, INFORMATION_SCHEMA, sp_executesql).
   What   : Scans every column of ONE raw table and suggests a clean data type by
            testing what the data actually does:
              all blank                     -> NVARCHAR(100)   (kind EMPTY)
              name ends _id/_code, contains zip/prefix, or has leading zeros
                                            -> text            (kind TEXT_ID)
              every value parses as date    -> DATETIME2(0)    (kind DATE)
              every value is a whole number -> INT or BIGINT
              every value has <= 2 decimals -> DECIMAL(18,2)
              every value is numeric        -> DECIMAL(18,4)
              anything else                 -> NVARCHAR(width) sized from the longest value
            Result is stored in the GLOBAL temp table ##column_map so you can edit it
            (UPDATE ##column_map SET target_type = ... WHERE column_name = ...)
            and then run 6.1b IN THE SAME QUERY WINDOW (a global temp table lives only
            as long as your connection).
   Edit   : @raw_schema, @raw_table.
   Pass   : You read the grid and agree with every row. This is a SUGGESTION: you own
            the decision. Typical overrides: a date that is really a month-year text,
            money that must be DECIMAL(12,2), a code column that must stay text.
   ============================================================================ */
USE RawToClean_Lab;
GO

/* ---------- CONFIG ---------- */
DECLARE @raw_schema SYSNAME = N'raw';
DECLARE @raw_table  SYSNAME = N'order_items';
/* ---------- END CONFIG ---------- */

DECLARE @tbl NVARCHAR(300) = QUOTENAME(@raw_schema) + N'.' + QUOTENAME(@raw_table);
DECLARE @sql NVARCHAR(MAX);

DROP TABLE IF EXISTS #prof;
CREATE TABLE #prof (
    ordinal INT, column_name SYSNAME, total_rows INT, non_blank INT,
    int_ok INT, bigint_ok INT, dec_ok INT, dec2_ok INT, date_ok INT,
    leading_zero INT, max_len INT
);

SELECT @sql = STRING_AGG(CAST(
      N'SELECT ' + CAST(c.ORDINAL_POSITION AS NVARCHAR(10)) + N' AS ordinal, '
    + QUOTENAME(c.COLUMN_NAME, '''') + N' AS column_name, '
    + N'COUNT(*) AS total_rows, COUNT(x.v) AS non_blank, '
    + N'COUNT(TRY_CAST(x.v AS INT)) AS int_ok, '
    + N'COUNT(TRY_CAST(x.v AS BIGINT)) AS bigint_ok, '
    + N'COUNT(TRY_CAST(x.v AS DECIMAL(18,4))) AS dec_ok, '
    + N'COUNT(CASE WHEN TRY_CAST(x.v AS DECIMAL(18,4)) = TRY_CAST(x.v AS DECIMAL(18,2)) THEN 1 END) AS dec2_ok, '
    + N'COUNT(CASE WHEN LEN(x.v) >= 8 THEN TRY_CAST(x.v AS DATETIME2) END) AS date_ok, '
    + N'COUNT(CASE WHEN x.v LIKE N''0[0-9]%'' THEN 1 END) AS leading_zero, '
    + N'ISNULL(MAX(LEN(x.v)), 0) AS max_len '
    + N'FROM ' + @tbl
    + N' CROSS APPLY (SELECT NULLIF(LTRIM(RTRIM(' + QUOTENAME(c.COLUMN_NAME) + N')), N'''') AS v) AS x'
    AS NVARCHAR(MAX)), N' UNION ALL ')
    WITHIN GROUP (ORDER BY c.ORDINAL_POSITION)
FROM INFORMATION_SCHEMA.COLUMNS AS c
WHERE c.TABLE_SCHEMA = @raw_schema AND c.TABLE_NAME = @raw_table;

INSERT INTO #prof EXEC sys.sp_executesql @sql;

DROP TABLE IF EXISTS ##column_map;

SELECT p.ordinal,
       p.column_name,
       CAST(p.column_name AS SYSNAME)                              AS target_name,
       CAST(CASE k.kind
                 WHEN 'DATE'   THEN 'DATETIME2(0)'
                 WHEN 'INT'    THEN 'INT'
                 WHEN 'BIGINT' THEN 'BIGINT'
                 WHEN 'DEC2'   THEN 'DECIMAL(18,2)'
                 WHEN 'DEC4'   THEN 'DECIMAL(18,4)'
                 WHEN 'EMPTY'  THEN 'NVARCHAR(100)'
                 ELSE 'NVARCHAR(' + CAST(CASE WHEN p.max_len <= 20   THEN 20
                                               WHEN p.max_len <= 50   THEN 50
                                               WHEN p.max_len <= 100  THEN 100
                                               WHEN p.max_len <= 255  THEN 255
                                               WHEN p.max_len <= 1000 THEN 1000
                                               ELSE 4000 END AS VARCHAR(10)) + ')'
            END AS NVARCHAR(40))                                   AS target_type,
       CAST(CASE WHEN p.non_blank < p.total_rows THEN 'NULL' ELSE 'NOT NULL' END AS NVARCHAR(10)) AS nullability,
       p.total_rows - p.non_blank                                  AS blank_rows,
       p.max_len,
       k.kind
INTO   ##column_map
FROM   #prof AS p
CROSS APPLY (
    SELECT CASE
             WHEN p.non_blank = 0 THEN 'EMPTY'
             WHEN p.column_name LIKE '%[_]id' OR p.column_name LIKE '%[_]code'
               OR p.column_name LIKE '%zip%'  OR p.column_name LIKE '%prefix%'
               OR p.leading_zero > 0 THEN 'TEXT_ID'
             WHEN p.date_ok = p.non_blank AND p.int_ok < p.non_blank THEN 'DATE'
             WHEN p.int_ok    = p.non_blank THEN 'INT'
             WHEN p.bigint_ok = p.non_blank THEN 'BIGINT'
             WHEN p.dec2_ok   = p.non_blank THEN 'DEC2'
             WHEN p.dec_ok    = p.non_blank THEN 'DEC4'
             ELSE 'TEXT'
           END AS kind
) AS k;

SELECT ordinal, column_name, target_name, target_type, nullability, blank_rows, max_len, kind
FROM ##column_map
ORDER BY ordinal;
GO
