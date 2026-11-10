/* ============================================================================
   6.1b  Generate (and optionally run) the clean table + typed load from ##column_map
   Status : NEW (not yet run on a live server)
   Needs  : 6.1a run first, in the SAME query window, and ##column_map reviewed/edited.
   What   : Builds
              1) CREATE TABLE <clean_schema>.<clean_table> from the column map,
              2) INSERT ... SELECT that TRIMs text, turns blanks into NULL and
                 TRY_CASTs typed columns,
              3) a per-column "silent loss" test: non-blank values in raw must equal
                 non-NULL values in clean. A difference means TRY_CAST turned a bad
                 value into NULL - nothing may disappear silently.
            @execute = 0 -> only shows the generated code (read it, paste it into the
            reason-code step 6.2 if you need flags, run it yourself).
            @execute = 1 -> drops and rebuilds the clean table (safe: raw is untouched),
            loads it, and runs the reconciliation.
   Edit   : the CONFIG block.
   Pass   : (execute = 1) rows_raw = rows_clean (PASS) and every row of the silent-loss
            grid shows PASS. A FAIL lists the column and how many values were lost:
            fix the target type, or add a cleaning rule, then re-run.
   ============================================================================ */
USE RawToClean_Lab;
GO

/* ---------- CONFIG ---------- */
DECLARE @raw_schema   SYSNAME       = N'raw';
DECLARE @raw_table    SYSNAME       = N'order_items';
DECLARE @clean_schema SYSNAME       = N'clean';
DECLARE @clean_table  SYSNAME       = N'order_items';
DECLARE @pk_cols      NVARCHAR(MAX) = N'order_id,order_item_id';   -- key from step 5.2 (comma list); use the clean (target) names; leave N'' for no key
DECLARE @execute      BIT           = 0;                           -- 0 = show code only, 1 = build and load
/* ---------- END CONFIG ---------- */

IF OBJECT_ID('tempdb..##column_map') IS NULL
BEGIN
    RAISERROR('##column_map not found. Run 6.1a first, in this same query window.', 16, 1);
    RETURN;
END;

DECLARE @raw   NVARCHAR(300) = QUOTENAME(@raw_schema)   + N'.' + QUOTENAME(@raw_table);
DECLARE @clean NVARCHAR(300) = QUOTENAME(@clean_schema) + N'.' + QUOTENAME(@clean_table);
DECLARE @nl    NVARCHAR(10)  = CHAR(13) + CHAR(10);
DECLARE @ddl   NVARCHAR(MAX);
DECLARE @ins   NVARCHAR(MAX);
DECLARE @chk   NVARCHAR(MAX);
DECLARE @pk    NVARCHAR(MAX) = N'';

-- 1) CREATE TABLE
IF LTRIM(RTRIM(@pk_cols)) <> N''
    SELECT @pk = N',' + @nl + N'    CONSTRAINT ' + QUOTENAME(N'PK_' + @clean_schema + N'_' + @clean_table)
               + N' PRIMARY KEY (' + STRING_AGG(CAST(QUOTENAME(LTRIM(RTRIM(s.value))) AS NVARCHAR(MAX)), N', ') + N')'
    FROM STRING_SPLIT(@pk_cols, N',') AS s;

SELECT @ddl = N'CREATE TABLE ' + @clean + N' (' + @nl
            + STRING_AGG(CAST(
                  N'    ' + QUOTENAME(m.target_name) + N' ' + m.target_type + N' '
                + CASE WHEN m.nullability = N'NOT NULL' OR m.is_pk = 1 THEN N'NOT NULL' ELSE N'NULL' END
                AS NVARCHAR(MAX)), N',' + @nl) WITHIN GROUP (ORDER BY m.ordinal)
            + @pk + @nl + N');'
FROM (SELECT cm.*,
             CASE WHEN EXISTS (SELECT 1 FROM STRING_SPLIT(@pk_cols, N',') AS s
                               WHERE LTRIM(RTRIM(s.value)) = cm.target_name)
                  THEN 1 ELSE 0 END AS is_pk
      FROM ##column_map AS cm) AS m;

-- 2) INSERT ... SELECT with TRIM / blank-to-NULL / TRY_CAST
SELECT @ins = N'INSERT INTO ' + @clean + N' (' + @nl
            + STRING_AGG(CAST(N'    ' + QUOTENAME(m.target_name) AS NVARCHAR(MAX)), N',' + @nl) WITHIN GROUP (ORDER BY m.ordinal)
            + @nl + N')' + @nl + N'SELECT' + @nl
            + STRING_AGG(CAST(
                  N'    ' + CASE WHEN m.target_type LIKE N'NVARCHAR%'
                                 THEN N'NULLIF(LTRIM(RTRIM(' + QUOTENAME(m.column_name) + N')), N'''')'
                                 ELSE N'TRY_CAST(NULLIF(LTRIM(RTRIM(' + QUOTENAME(m.column_name) + N')), N'''') AS ' + m.target_type + N')'
                            END
                AS NVARCHAR(MAX)), N',' + @nl) WITHIN GROUP (ORDER BY m.ordinal)
            + @nl + N'FROM ' + @raw + N';'
FROM ##column_map AS m;

-- 3) silent-loss test: non-blank in raw must equal non-NULL in clean, per column
SELECT @chk = N'SELECT column_name, raw_non_blank, clean_non_null, '
            + N'CASE WHEN raw_non_blank = clean_non_null THEN ''PASS'' ELSE ''FAIL'' END AS result FROM ('
            + STRING_AGG(CAST(
                  N'SELECT ' + CAST(m.ordinal AS NVARCHAR(10)) + N' AS ordinal, '
                + QUOTENAME(m.target_name, '''') + N' AS column_name, '
                + N'(SELECT COUNT(NULLIF(LTRIM(RTRIM(' + QUOTENAME(m.column_name) + N')), N'''')) FROM ' + @raw + N') AS raw_non_blank, '
                + N'(SELECT COUNT(' + QUOTENAME(m.target_name) + N') FROM ' + @clean + N') AS clean_non_null'
                AS NVARCHAR(MAX)), N' UNION ALL ') WITHIN GROUP (ORDER BY m.ordinal)
            + N') AS t ORDER BY ordinal;'
FROM ##column_map AS m;

SELECT @ddl AS generated_create_table;
SELECT @ins AS generated_insert;
SELECT @chk AS generated_silent_loss_test;

IF @execute = 1
BEGIN
    DECLARE @drop NVARCHAR(400) = N'DROP TABLE IF EXISTS ' + @clean + N';';
    DECLARE @cnt  NVARCHAR(MAX);
    DECLARE @rows_raw INT, @rows_clean INT;

    EXEC sys.sp_executesql @drop;
    EXEC sys.sp_executesql @ddl;
    EXEC sys.sp_executesql @ins;

    SET @cnt = N'SELECT @n = COUNT(*) FROM ' + @raw + N';';
    EXEC sys.sp_executesql @cnt, N'@n INT OUTPUT', @n = @rows_raw OUTPUT;
    SET @cnt = N'SELECT @n = COUNT(*) FROM ' + @clean + N';';
    EXEC sys.sp_executesql @cnt, N'@n INT OUTPUT', @n = @rows_clean OUTPUT;

    SELECT @rows_raw AS rows_raw, @rows_clean AS rows_clean,
           CASE WHEN @rows_raw = @rows_clean THEN 'PASS' ELSE 'FAIL' END AS result;

    EXEC sys.sp_executesql @chk;
END;
GO
