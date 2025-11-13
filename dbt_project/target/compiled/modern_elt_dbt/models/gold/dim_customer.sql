

-- Gold layer: slowly changing dimension style view for customers.
SELECT
    customer_id,
    customer_name,
    email,
    country,
    created_at,
    DATE_DIFF('day', CAST(created_at AS TIMESTAMP), CAST(CURRENT_TIMESTAMP AS TIMESTAMP)) AS customer_tenure_days,
    silver_loaded_at
FROM "warehouse"."main_silver"."silver_customers"