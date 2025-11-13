

-- Silver layer: curated product dimensions with normalized price types.
WITH source AS (
    SELECT * FROM "warehouse"."main_bronze"."bronze_products"
)
SELECT
    CAST(product_id AS INTEGER) AS product_id,
    sku,
    UPPER(product_name) AS product_name,
    UPPER(category) AS category,
    CAST(price AS DOUBLE) AS price,
    currency,
    CAST(created_at AS TIMESTAMP) AS created_at,
    CURRENT_TIMESTAMP AS silver_loaded_at
FROM source