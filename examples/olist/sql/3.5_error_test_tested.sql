/* ============================================================================
   3.5t  Error-handling test with a hard-coded path (the version that ran)
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Loads 02_working\errortest.csv into a 3-character temp table; the over-long row goes to the rejects folder.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : Grid shows rows 1, 2, 4; a reject file and .Error.Txt exist in 02_working\rejects.
   ============================================================================ */

USE RawToClean_Lab;
GO

DROP TABLE IF EXISTS #error_test;
CREATE TABLE #error_test (id NVARCHAR(3), label NVARCHAR(3));

BULK INSERT #error_test
FROM 'C:\bsg-playbook\02_working\errortest.csv'

WITH (
    FORMAT          = 'CSV',
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0a',
    CODEPAGE        = '65001',
    MAXERRORS       = 10,
        ERRORFILE       = 'C:\bsg-playbook\02_working\rejects\errortest_rejects.txt'

);

SELECT id, label FROM #error_test;
GO
