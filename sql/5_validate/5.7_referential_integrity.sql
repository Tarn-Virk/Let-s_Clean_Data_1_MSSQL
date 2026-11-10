/* ============================================================================
   5.7  Referential integrity: child keys must exist in the parent
   Status : TESTED on Olist (build notes). The values in the DECLARE lines are the Olist example - change them for your data.
   What   : Counts orphan child rows, duplicated parent keys, and parents without children.
   Edit   : @child_schema/@child_table/@child_key and @parent_schema/@parent_table/@parent_key.
   Pass   : orphan_child_rows = 0 and duplicated_parent_keys = 0 (result PASS). parent_without_children is information, not a failure.
   ============================================================================ */

USE RawToClean_Lab;
GO

DECLARE @child_schema  SYSNAME = 'raw';
DECLARE @child_table   SYSNAME = 'orders';
DECLARE @child_key     SYSNAME = 'customer_id';
DECLARE @parent_schema SYSNAME = 'raw';
DECLARE @parent_table  SYSNAME = 'customers';
DECLARE @parent_key    SYSNAME = 'customer_id';

DECLARE @child  NVARCHAR(300) = QUOTENAME(@child_schema)  + N'.' + QUOTENAME(@child_table);
DECLARE @parent NVARCHAR(300) = QUOTENAME(@parent_schema) + N'.' + QUOTENAME(@parent_table);
DECLARE @ck     NVARCHAR(150) = QUOTENAME(@child_key);
DECLARE @pk     NVARCHAR(150) = QUOTENAME(@parent_key);
DECLARE @sql    NVARCHAR(MAX);

SET @sql = N'

SELECT child_rows, orphan_child_rows, parent_rows,
       duplicated_parent_keys, parent_without_children,
       CASE WHEN orphan_child_rows = 0 AND duplicated_parent_keys = 0
                        THEN ''PASS'' ELSE ''FAIL'' END AS result

FROM (
    SELECT
        (SELECT COUNT(*) FROM ' + @child + N') AS child_rows,
        (SELECT COUNT(*) FROM ' + @child + N' AS c
         WHERE c.' + @ck + N' IS NOT NULL
           AND NOT EXISTS (SELECT 1 FROM ' + @parent + N' AS p
                           WHERE p.' + @pk + N' = c.' + @ck + N')) AS orphan_child_rows,
        (SELECT COUNT(*) FROM ' + @parent + N') AS parent_rows,
        (SELECT COUNT(*) FROM (SELECT ' + @pk + N' FROM ' + @parent + N'
                               GROUP BY ' + @pk + N' HAVING COUNT(*) > 1) AS d) AS duplicated_parent_keys,
                (SELECT COUNT(*) FROM ' + @parent + N' AS p

         WHERE NOT EXISTS (SELECT 1 FROM ' + @child + N' AS c
                                                      WHERE c.' + @ck + N' = p.' + @pk + N')) AS parent_without_children

) AS t;';

EXEC sys.sp_executesql @sql;
GO
