/* ============================================================================
   6.5i  Create and load clean.order_items
   Status : TESTED on Olist (verbatim from the build notes; only the folder path changed)
   What   : Typed items: DECIMAL(10,2) price and freight, TINYINT item number, DATETIME2(0) shipping limit, composite primary key (order_id, order_item_id).
   Edit   : Nothing for the Olist run. This is the exact script that was run for the Olist example.
   Pass   : Row count equals raw.order_items; PK created.
   ============================================================================ */

USE RawToClean_Lab;
GO

DROP TABLE IF EXISTS clean.order_items;
GO

CREATE TABLE clean.order_items (
    order_id           NVARCHAR(32)   NOT NULL,
    order_item_id      TINYINT        NOT NULL,
    product_id         NVARCHAR(32)   NOT NULL,
    seller_id          NVARCHAR(32)   NOT NULL,
    shipping_limit_ts  DATETIME2(0)   NOT NULL,
    price              DECIMAL(10,2)  NOT NULL,
    freight_value      DECIMAL(10,2)  NOT NULL,
    CONSTRAINT PK_clean_order_items PRIMARY KEY (order_id, order_item_id)
);
GO

INSERT INTO clean.order_items
    (order_id, order_item_id, product_id, seller_id, shipping_limit_ts, price, freight_value)
SELECT
    LTRIM(RTRIM(order_id)),
    TRY_CAST(NULLIF(LTRIM(RTRIM(order_item_id)), '')       AS TINYINT),
    LTRIM(RTRIM(product_id)),
    LTRIM(RTRIM(seller_id)),
    TRY_CAST(NULLIF(LTRIM(RTRIM(shipping_limit_date)), '') AS DATETIME2(0)),
    TRY_CAST(NULLIF(LTRIM(RTRIM(price)), '')               AS DECIMAL(10,2)),
    TRY_CAST(NULLIF(LTRIM(RTRIM(freight_value)), '')       AS DECIMAL(10,2))
FROM raw.order_items;
GO

SELECT r.rows_raw, c.rows_clean,
       r.price_raw, c.price_clean,
       r.freight_raw, c.freight_clean,
       CASE WHEN r.rows_raw    = c.rows_clean
             AND r.price_raw   = c.price_clean
             AND r.freight_raw = c.freight_clean
            THEN 'PASS' ELSE 'FAIL' END AS result
FROM (SELECT COUNT(*)                                    AS rows_raw,
             SUM(TRY_CAST(price AS DECIMAL(18,2)))         AS price_raw,
             SUM(TRY_CAST(freight_value AS DECIMAL(18,2))) AS freight_raw
      FROM raw.order_items) AS r
CROSS JOIN
     (SELECT COUNT(*)           AS rows_clean,
             SUM(price)         AS price_clean,
             SUM(freight_value) AS freight_clean
      FROM clean.order_items) AS c;
GO
