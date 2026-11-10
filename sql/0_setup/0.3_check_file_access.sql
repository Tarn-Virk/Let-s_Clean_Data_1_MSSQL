/* ============================================================================
   0.3  Check who SQL Server runs as, and whether it can see your file
   Status : Service-account query TESTED on Olist; xp_fileexist call is the exact form used in the notes with the path made a variable
   What   : BULK INSERT reads files AS THE SQL SERVER SERVICE ACCOUNT, not as you. This shows that account and tests one file.
   Edit   : @file below: the full path of one CSV.
   Pass   : File_Exists = 1. If 0: grant the service account Read on the folder (docs/phase-03-bronze.md, "Permissions"). The account is shown in the first grid (normally NT Service\MSSQL$SQLEXPRESS).
   ============================================================================ */

USE RawToClean_Lab;
GO

SELECT servicename, service_account, status_desc
FROM sys.dm_server_services;

SELECT DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS database_collation;
GO

-- Can the service account see the file? (1 = yes, 0 = no)
DECLARE @file NVARCHAR(400) = N'C:\bsg-playbook\01_raw\archive\olist_orders_dataset.csv';  -- CONFIG: full path
EXEC master.sys.xp_fileexist @file;
GO
