/* ============================================================================
   0.2  Create the schemas (raw, clean, gold)
   Status : raw schema + checks TESTED on Olist; the clean and gold lines use the same pattern the notes used in steps 5 and 8
   What   : Confirms you are in RawToClean_Lab, creates the three layer schemas if missing, and lists them.
   Edit   : Nothing.
   Pass   : current_database = RawToClean_Lab; the last grid lists raw, clean and gold.
   ============================================================================ */

USE RawToClean_Lab;
GO

SELECT DB_NAME() AS current_database;
GO


IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'raw')
    EXEC('CREATE SCHEMA raw');
GO


SELECT
    s.name                                      AS schema_name,
    DB_NAME()                                   AS current_database,
    DATABASEPROPERTYEX(DB_NAME(), 'Collation')  AS database_collation
FROM sys.schemas AS s
WHERE s.name = 'raw';
GO

-- clean and gold schemas (same pattern)
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'clean')
    EXEC('CREATE SCHEMA clean');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
    EXEC('CREATE SCHEMA gold');
GO

SELECT s.name AS schema_name, DB_NAME() AS database_name
FROM sys.schemas AS s
WHERE s.name IN ('raw', 'clean', 'gold')
ORDER BY s.name;
GO
