# Olist dataset cards (all 9 files)

Source: Kaggle "Brazilian E-Commerce Public Dataset by Olist" (https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce), downloaded as `archive.zip`.
Every number below was measured directly on the files (row counts, line endings, BOM, key uniqueness) with a script that reads the files only; nothing was edited.

All nine files: comma delimiter, UTF-8, header in row 1, every data row has the same number of fields as the header.

## Format summary

| File | Size | Data rows | Cols | Line ending | BOM | Final line break | Quotes used |
|---|---:|---:|---:|---|---|---|---|
| olist_orders_dataset.csv | 17.7 MB | 99,441 | 8 | LF | no | yes | yes |
| olist_customers_dataset.csv | 9.0 MB | 99,441 | 5 | LF | no | yes | yes |
| olist_order_items_dataset.csv | 15.4 MB | 112,650 | 7 | LF | no | yes | yes |
| olist_order_payments_dataset.csv | 5.8 MB | 103,886 | 5 | LF | no | yes | yes |
| olist_order_reviews_dataset.csv | 14.5 MB | 99,224 | 7 | **CRLF** (also inside quoted comments) | no | yes | yes |
| olist_products_dataset.csv | 2.4 MB | 32,951 | 9 | LF | no | yes | yes |
| olist_sellers_dataset.csv | 175 KB | 3,095 | 4 | LF | no | yes | yes |
| olist_geolocation_dataset.csv | 61.3 MB | 1,000,163 | 5 | LF | no | yes | yes |
| product_category_name_translation.csv | 2.6 KB | 71 | 2 | **CRLF** | **yes** | **no** | no |

What this means for the load:
* Reviews: use `ROWTERMINATOR = '\r\n'` with `FORMAT = 'CSV'`. Free-text comments contain line breaks inside quotes; only `FORMAT='CSV'` keeps those inside one row. Count rows with a CSV parser, NOT with the editor line number (the file has more physical lines than rows).
* Translation: UTF-8 BOM at the start (the 3.4 script strips it from the header), CRLF, and **no line break after the last row**. Test the last row after loading.
* Geolocation: 1 million rows. Load a sample first, then the full file; expect it to take longest.
* All others: `ROWTERMINATOR = '0x0a'`.
* The products header has two spelling mistakes that are in the source: `product_name_lenght`, `product_description_lenght`. Keep the raw names in raw; rename them in clean (see the column map in 6.1a).

## Keys and grain (declared, then proven unique with a script on the files)

| Raw table | Grain: one row per ... | Key | Distinct / rows | Notes |
|---|---|---|---|---|
| orders | order | order_id | 99,441 / 99,441 | unique |
| customers | customer_id (one per order placement) | customer_id | 99,441 / 99,441 | `customer_unique_id` has only 96,096 distinct values: it is the real person, so a person can have several `customer_id`s |
| order_items | item line in an order | (order_id, order_item_id) | 112,650 / 112,650 | composite key |
| order_payments | payment part of an order | (order_id, payment_sequential) | 103,886 / 103,886 | composite key; `payment_type` values seen: boleto, credit_card, debit_card, voucher, not_defined |
| order_reviews | review of an order | (review_id, order_id) | 99,224 / 99,224 | **`review_id` alone is NOT unique** (98,410 distinct for 99,224 rows). Do not declare it the key |
| products | product | product_id | 32,951 / 32,951 | 610 rows blank in category, name length, description length and photos; 2 rows blank in weight and the three dimensions |
| sellers | seller | seller_id | 3,095 / 3,095 | unique |
| geolocation | coordinate sample | none | 19,015 distinct zip prefixes in 1,000,163 rows | many rows per zip prefix; no key. Aggregate to one row per zip prefix in gold if you need one |
| category translation | Portuguese category name | product_category_name | 71 / 71 | lookup table |

Reviews: `review_comment_title` is blank in 87,658 rows and `review_comment_message` in 58,274 rows (blank is normal there: optional text).

## Relationships (for step 5.7 referential-integrity tests)

```
customers.customer_id        <- orders.customer_id
orders.order_id              <- order_items.order_id
orders.order_id              <- order_payments.order_id
orders.order_id              <- order_reviews.order_id
products.product_id          <- order_items.product_id
sellers.seller_id            <- order_items.seller_id
translation.product_category_name <- products.product_category_name
(zip prefixes link customers / sellers to geolocation, many-to-many)
```

## How far each table was taken in the original build

| Table | Raw load | Profile | Validate | Clean | Gold |
|---|---|---|---|---|---|
| orders | yes | yes | yes | yes (7 date-rule flags) | yes (gold.order_summary) |
| customers | yes | yes | yes | yes | feeds gold |
| order_items | yes | yes | yes | yes | feeds gold |
| payments, reviews, products, sellers, geolocation, translation | **not built** | | | | |

For the six remaining tables follow `docs/adding-a-new-dataset.md`: it is the same loop, and scripts 3.4, 3.6, 4.x, 5.x, 6.1a/6.1b need only their CONFIG lines changed.

## Orders: what the original run found (use as expected values when you rerun)

| Check | Result |
|---|---|
| Rows | 99,441 (file = raw = clean = gold) |
| Mandatory columns blank | 0 |
| Delivered orders missing a date (flag code: rows) | DELIVERED_NO_APPROVED 14, DELIVERED_NO_CARRIER 2, DELIVERED_NO_DELIVERY 8 (the notes counted 23 distinct delivered orders with a gap, so some orders carry more than one code) |
| Date-order violations (flag code: rows) | PURCHASE_AFTER_CARRIER 166, APPROVED_AFTER_CARRIER 1,359, APPROVED_AFTER_DELIVERED 61, CARRIER_AFTER_DELIVERED 23 |
| Date range | purchases fall in 2016-2018 with no placeholder dates; gold marks `in_reporting_window` = 1 for purchases from 2017-01-01 up to (not including) 2018-09-01, the window used in the original build |
