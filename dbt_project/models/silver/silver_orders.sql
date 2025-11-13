{{
  config(
    materialized='external',
    format='parquet',
    location='s3://datalake/silver/erp/orders/silver_orders.parquet'
  )
}}

-- Silver layer: enrich order headers with payment metadata.
WITH orders AS (
    SELECT * FROM {{ ref('bronze_orders') }}
),
payments AS (
    SELECT
        order_id,
        MAX(payment_method) AS payment_method,
        MAX(status) AS payment_status,
        MAX(payment_ts) AS latest_payment_ts
    FROM {{ ref('bronze_payments') }}
    GROUP BY 1
)
SELECT
    CAST(o.order_id AS INTEGER) AS order_id,
    CAST(o.customer_id AS INTEGER) AS customer_id,
    UPPER(o.order_status) AS order_status,
    CAST(o.order_ts AS TIMESTAMP) AS order_ts,
    CAST(o.updated_ts AS TIMESTAMP) AS updated_ts,
    CAST(o.total_amount AS DOUBLE) AS total_amount,
    p.payment_method,
    p.payment_status,
    CAST(p.latest_payment_ts AS TIMESTAMP) AS payment_ts,
    CURRENT_TIMESTAMP AS silver_loaded_at
FROM orders o
LEFT JOIN payments p USING (order_id)
