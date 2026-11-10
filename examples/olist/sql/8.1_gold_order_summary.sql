/* ============================================================================
   8.1o  gold.order_summary (grain: one row per order)
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Builds the gold table with LEFT JOINs from the grain, items aggregated before the join, a reporting-window flag and days_late; reconciles to clean; shows a state summary.
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : All 5 reconciliation rows PASS.
   ============================================================================ */

USE RawToClean_Lab;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'gold')
    EXEC('CREATE SCHEMA gold');
GO

DROP TABLE IF EXISTS gold.order_summary;
GO

CREATE TABLE gold.order_summary (
    order_id                 NVARCHAR(32)   NOT NULL,
    customer_unique_id       NVARCHAR(32)   NOT NULL,
    customer_state           NVARCHAR(2)    NOT NULL,
    order_status             NVARCHAR(20)   NOT NULL,
    purchase_ts              DATETIME2(0)   NOT NULL,
    purchase_month           DATE           NOT NULL,
    in_reporting_window      BIT            NOT NULL,
    estimated_delivery_date  DATE           NOT NULL,
    delivered_ts             DATETIME2(0)   NULL,
    item_count               INT            NOT NULL,
    item_revenue             DECIMAL(12,2)  NOT NULL,
    freight_total            DECIMAL(12,2)  NOT NULL,
    days_late                INT            NULL,
    is_late                  BIT            NULL,
    date_issue_codes         NVARCHAR(100)  NULL,
    CONSTRAINT PK_gold_order_summary PRIMARY KEY (order_id)
);
GO

INSERT INTO gold.order_summary
    (order_id, customer_unique_id, customer_state, order_status, purchase_ts,
     purchase_month, in_reporting_window, estimated_delivery_date, delivered_ts,
     item_count, item_revenue, freight_total, days_late, is_late, date_issue_codes)
SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_state,
    o.order_status,
    o.purchase_ts,
    DATEFROMPARTS(YEAR(o.purchase_ts), MONTH(o.purchase_ts), 1),
    CASE WHEN o.purchase_ts >= '2017-01-01' AND o.purchase_ts < '2018-09-01' THEN 1 ELSE 0 END,
    o.estimated_delivery_date,
    o.delivered_ts,
    ISNULL(i.item_count, 0),
    ISNULL(i.item_revenue, 0),
    ISNULL(i.freight_total, 0),
    l.days_late,
    CASE WHEN l.days_late IS NULL THEN NULL WHEN l.days_late > 0 THEN 1 ELSE 0 END,
    o.date_issue_codes
FROM clean.orders AS o
LEFT JOIN clean.customers AS c
       ON c.customer_id = o.customer_id
LEFT JOIN (
    SELECT order_id,
           COUNT(*)           AS item_count,
           SUM(price)         AS item_revenue,
           SUM(freight_value) AS freight_total
    FROM clean.order_items
    GROUP BY order_id
) AS i ON i.order_id = o.order_id
CROSS APPLY (
    SELECT CASE WHEN o.order_status = 'delivered'
                                  AND o.delivered_ts IS NOT NULL

                 AND (o.date_issue_codes IS NULL OR o.date_issue_codes NOT LIKE '%AFTER_DELIVERED%')
                THEN DATEDIFF(DAY, o.estimated_delivery_date, CAST(o.delivered_ts AS DATE))
           END AS days_late
) AS l;
GO

SELECT test, gold_value, silver_value,
       CASE WHEN gold_value = silver_value THEN 'PASS' ELSE 'FAIL' END AS result
FROM (
    SELECT 1 AS n, 'order rows' AS test,
           (SELECT COUNT(*) FROM gold.order_summary) AS gold_value,
           (SELECT COUNT(*) FROM clean.orders)       AS silver_value
    UNION ALL
    SELECT 2, 'item rows (sum of item_count)',
           (SELECT SUM(item_count) FROM gold.order_summary),
           (SELECT COUNT(*) FROM clean.order_items)
    UNION ALL
    SELECT 3, 'total price',
           (SELECT SUM(item_revenue) FROM gold.order_summary),
           (SELECT SUM(price) FROM clean.order_items)
    UNION ALL
    SELECT 4, 'total freight',
           (SELECT SUM(freight_total) FROM gold.order_summary),
           (SELECT SUM(freight_value) FROM clean.order_items)
    UNION ALL
    SELECT 5, 'orders in reporting window',
           (SELECT COUNT(*) FROM gold.order_summary WHERE in_reporting_window = 1),
           (SELECT COUNT(*) FROM clean.orders
            WHERE purchase_ts >= '2017-01-01' AND purchase_ts < '2018-09-01')
) AS t
ORDER BY n;
GO

SELECT TOP (10)
       customer_state,
       COUNT(*)                                     AS orders,
       SUM(item_revenue)                            AS revenue,
       COUNT(is_late)                               AS measurable_deliveries,
       SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) AS late_deliveries,
       CAST(100.0 * SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END)
            / NULLIF(COUNT(is_late), 0) AS DECIMAL(5,2)) AS pct_late
FROM gold.order_summary
WHERE in_reporting_window = 1
  AND order_status NOT IN ('canceled', 'unavailable')
GROUP BY customer_state
ORDER BY revenue DESC;
GO
