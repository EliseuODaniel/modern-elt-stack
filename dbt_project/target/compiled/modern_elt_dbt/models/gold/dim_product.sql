

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
FROM "warehouse"."main_silver"."silver_products"