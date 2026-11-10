/* ============================================================================
   7.1  Index the join and filter columns of a clean table
   Status : NEW generic wrapper around the tested CREATE INDEX pattern (not yet run)
   What   : Drops (if present) and creates a nonclustered index on the columns you
            list, then shows every index in the clean schema.
   Why    : Gold joins on keys and filters on dates. Indexes make that fast; the
            primary key already indexes the key.
   Edit   : CONFIG rows (one index per row).
   Pass   : the final grid lists your index with the right key_columns.
   ============================================================================ */
USE RawToClean_Lab;
GO

/* ---------- CONFIG ---------- */
DECLARE @indexes TABLE (schema_name SYSNAME, table_name SYSNAME, index_name SYSNAME, key_columns NVARCHAR(400));
INSERT INTO @indexes (schema_name, table_name, index_name, key_columns) VALUES
    (N'clean', N'orders', N'IX_clean_orders_customer_id', N'customer_id'),
    (N'clean', N'orders', N'IX_clean_orders_purchase_ts', N'purchase_ts');
/* ---------- END CONFIG ---------- */

DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql = @sql
    + N'DROP INDEX IF EXISTS ' + QUOTENAME(index_name) + N' ON ' + QUOTENAME(schema_name) + N'.' + QUOTENAME(table_name) + N'; '
    + N'CREATE NONCLUSTERED INDEX ' + QUOTENAME(index_name) + N' ON ' + QUOTENAME(schema_name) + N'.' + QUOTENAME(table_name)
    + N' (' + (SELECT STRING_AGG(CAST(QUOTENAME(LTRIM(RTRIM(s.value))) AS NVARCHAR(MAX)), N', ')
               FROM STRING_SPLIT(key_columns, N',') AS s) + N'); '
FROM @indexes;

EXEC sys.sp_executesql @sql;
GO

SELECT OBJECT_SCHEMA_NAME(i.object_id) + '.' + OBJECT_NAME(i.object_id) AS table_name,
       i.name AS index_name,
       i.type_desc,
       i.is_primary_key,
       STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS key_columns
FROM sys.indexes AS i
JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN sys.columns AS c        ON c.object_id  = ic.object_id AND c.column_id = ic.column_id
WHERE OBJECT_SCHEMA_NAME(i.object_id) = 'clean'
  AND ic.is_included_column = 0
GROUP BY i.object_id, i.name, i.type_desc, i.is_primary_key
ORDER BY table_name, i.is_primary_key DESC, i.name;
GO
