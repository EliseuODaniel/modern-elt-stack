{{
  config(
    materialized='external',
    format='parquet',
    location='s3://datalake/gold/dim_customer/dim_customer.parquet'
  )
}}

-- Gold layer: slowly changing dimension style view for customers.
SELECT
    customer_id,
    customer_name,
    email,
    country,
    created_at,
    DATE_DIFF('day', CAST(created_at AS TIMESTAMP), CAST(CURRENT_TIMESTAMP AS TIMESTAMP)) AS customer_tenure_days,
    silver_loaded_at
FROM {{ ref('silver_customers') }}
