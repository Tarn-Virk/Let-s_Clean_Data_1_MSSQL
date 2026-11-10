/* ============================================================================
   6.4c  Create and load clean.customers
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Typed, trimmed customers: zip prefix kept as text (NVARCHAR(5)), state upper-cased, city lower-cased, primary key customer_id.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : Row count equals raw.customers.
   ============================================================================ */

USE RawToClean_Lab;
GO

DROP TABLE IF EXISTS clean.customers;
GO

CREATE TABLE clean.customers (
    customer_id               NVARCHAR(32)  NOT NULL,
    customer_unique_id        NVARCHAR(32)  NOT NULL,
    customer_zip_code_prefix  NVARCHAR(5)   NOT NULL,
    customer_city             NVARCHAR(40)  NOT NULL,
    customer_state            NVARCHAR(2)   NOT NULL,
    CONSTRAINT PK_clean_customers PRIMARY KEY (customer_id)
);
GO

INSERT INTO clean.customers
    (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
SELECT
    LTRIM(RTRIM(customer_id)),
    LTRIM(RTRIM(customer_unique_id)),
    LTRIM(RTRIM(customer_zip_code_prefix)),
    LOWER(LTRIM(RTRIM(customer_city))),
    UPPER(LTRIM(RTRIM(customer_state)))
FROM raw.customers;
GO

SELECT COUNT(*) AS rows_changed_by_cleaning
FROM raw.customers AS r
JOIN clean.customers AS c
  ON c.customer_id = r.customer_id
WHERE r.customer_unique_id        COLLATE Latin1_General_BIN2 <> c.customer_unique_id
   OR r.customer_zip_code_prefix  COLLATE Latin1_General_BIN2 <> c.customer_zip_code_prefix
   OR r.customer_city             COLLATE Latin1_General_BIN2 <> c.customer_city
   OR r.customer_state            COLLATE Latin1_General_BIN2 <> c.customer_state;
GO
