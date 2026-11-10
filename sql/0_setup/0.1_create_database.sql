/* ============================================================================
   0.1  Create the working database
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Creates RawToClean_Lab if it does not exist (collation is the server default), then lists it.
   Edit   : Nothing, or rename the database everywhere if you want another name (find/replace RawToClean_Lab).
   Pass   : The final grid shows one row: name, state_desc = ONLINE, collation_name, create_date.
   ============================================================================ */

USE master;
GO

IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'RawToClean_Lab')
    CREATE DATABASE RawToClean_Lab;
GO

SELECT name, state_desc, collation_name, create_date
FROM sys.databases
WHERE name = 'RawToClean_Lab';
GO
