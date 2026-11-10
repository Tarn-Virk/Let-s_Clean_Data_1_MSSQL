/* ============================================================================
   7.1o  Indexes on clean.orders
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Nonclustered indexes on customer_id and purchase_ts, then lists all clean indexes.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : Both indexes are listed.
   ============================================================================ */

USE RawToClean_Lab;
GO

DROP INDEX IF EXISTS IX_clean_orders_customer_id ON clean.orders;
CREATE NONCLUSTERED INDEX IX_clean_orders_customer_id ON clean.orders (customer_id);

DROP INDEX IF EXISTS IX_clean_orders_purchase_ts ON clean.orders;
CREATE NONCLUSTERED INDEX IX_clean_orders_purchase_ts ON clean.orders (purchase_ts);
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
ORDER BY table_name, i.is_primary_key DESC;
GO
