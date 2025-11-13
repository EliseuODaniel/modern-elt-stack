{{
  config(
    materialized='external',
    format='parquet',
    location='s3://datalake/silver/erp/order_items/silver_order_items.parquet'
  )
}}

-- Silver layer: normalized line items with computed extended amounts.
WITH items AS (
    SELECT * FROM {{ ref('bronze_order_items') }}
)
SELECT
    CAST(order_item_id AS INTEGER) AS order_item_id,
    CAST(order_id AS INTEGER) AS order_id,
    CAST(product_id AS INTEGER) AS product_id,
    CAST(quantity AS INTEGER) AS quantity,
    CAST(unit_price AS DOUBLE) AS unit_price,
    currency,
    quantity * CAST(unit_price AS DOUBLE) AS extended_amount,
    CURRENT_TIMESTAMP AS silver_loaded_at
FROM items
