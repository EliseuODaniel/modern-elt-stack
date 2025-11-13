

-- Silver layer: cleans customer attributes and standardizes casing.
WITH source AS (
    SELECT * FROM "warehouse"."main_bronze"."bronze_customers"
)
SELECT
    CAST(customer_id AS INTEGER) AS customer_id,
    UPPER(customer_name) AS customer_name,
    LOWER(email) AS email,
    phone,
    UPPER(country) AS country,
    CAST(created_at AS TIMESTAMP) AS created_at,
    CURRENT_TIMESTAMP AS silver_loaded_at
FROM source