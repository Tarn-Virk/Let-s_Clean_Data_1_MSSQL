/* ============================================================================
   6.2o  Load clean.orders with reason-code flags
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Typed load from raw.orders. Seven date rules become semicolon-separated codes in date_issue_codes. Nothing is dropped.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : clean.orders has 99441 rows (see 6.3).
   ============================================================================ */

USE RawToClean_Lab;
GO

TRUNCATE TABLE clean.orders;
GO

INSERT INTO clean.orders
    (order_id, customer_id, order_status, purchase_ts, approved_ts,
     carrier_ts, delivered_ts, estimated_delivery_date, date_issue_codes)
SELECT
    c.order_id,
    c.customer_id,
    c.order_status,
    c.purchase_ts,
    c.approved_ts,
    c.carrier_ts,
    c.delivered_ts,
    c.estimated_delivery_date,
    NULLIF(CONCAT_WS(';',
        CASE WHEN c.carrier_ts   < c.purchase_ts THEN 'PURCHASE_AFTER_CARRIER'   END,
        CASE WHEN c.carrier_ts   < c.approved_ts THEN 'APPROVED_AFTER_CARRIER'   END,
        CASE WHEN c.delivered_ts < c.approved_ts THEN 'APPROVED_AFTER_DELIVERED' END,
        CASE WHEN c.delivered_ts < c.carrier_ts  THEN 'CARRIER_AFTER_DELIVERED'  END,
        CASE WHEN c.order_status = 'delivered' AND c.approved_ts  IS NULL THEN 'DELIVERED_NO_APPROVED' END,
        CASE WHEN c.order_status = 'delivered' AND c.carrier_ts   IS NULL THEN 'DELIVERED_NO_CARRIER'  END,
        CASE WHEN c.order_status = 'delivered' AND c.delivered_ts IS NULL THEN 'DELIVERED_NO_DELIVERY' END
    ), '') AS date_issue_codes
FROM (
    SELECT
        LTRIM(RTRIM(order_id))             AS order_id,
        LTRIM(RTRIM(customer_id))          AS customer_id,
        LOWER(LTRIM(RTRIM(order_status)))  AS order_status,
        TRY_CAST(NULLIF(LTRIM(RTRIM(order_purchase_timestamp)),      '') AS DATETIME2(0)) AS purchase_ts,
        TRY_CAST(NULLIF(LTRIM(RTRIM(order_approved_at)),             '') AS DATETIME2(0)) AS approved_ts,
        TRY_CAST(NULLIF(LTRIM(RTRIM(order_delivered_carrier_date)),  '') AS DATETIME2(0)) AS carrier_ts,
        TRY_CAST(NULLIF(LTRIM(RTRIM(order_delivered_customer_date)), '') AS DATETIME2(0)) AS delivered_ts,
        TRY_CAST(NULLIF(LTRIM(RTRIM(order_estimated_delivery_date)), '') AS DATE)         AS estimated_delivery_date
    FROM raw.orders
) AS c;
GO
