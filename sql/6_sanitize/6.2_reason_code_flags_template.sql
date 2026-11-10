/* ============================================================================
   6.2  Reason-code flags: keep suspicious rows, label them, never drop them
   Status : TEMPLATE (pattern TESTED on Olist in examples/olist/sql/6.2_clean_orders_load.sql).
            This file is NOT runnable as-is: replace every <angle-bracket> part.
   What   : Shows how to turn each business rule from step 5 into a flag. A row that
            breaks a rule is loaded anyway, with a short code in <issue_codes>.
            Several broken rules on one row give "CODE_A;CODE_B".
   Why    : Deleting rows hides the problem and breaks reconciliation. A flag lets
            analysts include or exclude the rows knowingly, and the counts still tie
            back to the file.
   Steps  : 1) Finish 6.1a/6.1b so the clean table exists with typed columns.
            2) Add the column:  <issue_codes> NVARCHAR(200) NULL  to the clean DDL
               (or ALTER TABLE <clean_schema>.<clean_table> ADD <issue_codes> NVARCHAR(200) NULL).
            3) Re-run the load with the CASE block below in the SELECT list.
            4) Re-test (see 6.3 pattern): expected rows per code (from step 5 counts)
               must equal actual rows per code. Use STRING_SPLIT(<issue_codes>, ';').
   Pass   : every code's actual count equals the violation count found in step 5.
   ============================================================================ */
USE RawToClean_Lab;
GO

/*
INSERT INTO <clean_schema>.<clean_table>
    (<key>, <column_1>, <column_2>, <issue_codes>)
SELECT
    c.<key>, c.<column_1>, c.<column_2>,
    NULLIF(CONCAT_WS(';',
        -- ordering rule from step 5.5: later column must not be earlier than the earlier one
        CASE WHEN c.<later_ts>   < c.<earlier_ts> THEN '<EARLIER>_AFTER_<LATER>' END,
        -- conditional-completeness rule from step 5.3: status says it must exist
        CASE WHEN c.<status> = '<status_value>' AND c.<must_exist_col> IS NULL THEN '<STATUS>_NO_<COLUMN>' END,
        -- range rule: value outside what is possible
        CASE WHEN c.<amount> < 0 THEN 'NEGATIVE_<AMOUNT>' END
    ), '') AS <issue_codes>
FROM (
    SELECT
        LTRIM(RTRIM(<key>))                                   AS <key>,
        TRY_CAST(NULLIF(LTRIM(RTRIM(<ts_col>)), '') AS DATETIME2(0)) AS <earlier_ts>,
        ...
    FROM <raw_schema>.<raw_table>
) AS c;
*/

-- Re-test skeleton: expected counts come from step 5, actual from the clean table.
/*
WITH expected AS (
    SELECT code, expected_rows
    FROM (VALUES ('<CODE_1>', <n1>), ('<CODE_2>', <n2>)) AS v (code, expected_rows)
),
actual AS (
    SELECT s.value AS code, COUNT(*) AS actual_rows
    FROM <clean_schema>.<clean_table> AS t
    CROSS APPLY STRING_SPLIT(t.<issue_codes>, ';') AS s
    GROUP BY s.value
)
SELECT COALESCE(e.code, a.code) AS issue_code, e.expected_rows, ISNULL(a.actual_rows, 0) AS actual_rows,
       CASE WHEN e.expected_rows = ISNULL(a.actual_rows, 0) THEN 'PASS' ELSE 'FAIL' END AS result
FROM expected AS e
FULL OUTER JOIN actual AS a ON a.code = e.code;
*/
GO
