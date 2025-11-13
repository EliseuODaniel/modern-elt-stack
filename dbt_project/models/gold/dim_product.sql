{{
  config(
    materialized='external',
    format='parquet',
    location='s3://datalake/gold/dim_product/dim_product.parquet'
  )
}}

-- Gold layer: dimensional product attributes.
SELECT
    product_id,
    sku,
    product_name,
    category,
    price,
    currency,
    created_at,
    silver_loaded_at
FROM {{ ref('silver_products') }}
