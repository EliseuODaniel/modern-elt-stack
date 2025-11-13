

-- Gold layer: order fact table with revenue and operational metrics.
WITH line_rollup AS (
    SELECT
        order_id,
        SUM(extended_amount) AS gross_item_amount,
        SUM(quantity) AS total_units,
        COUNT(DISTINCT product_id) AS distinct_products
    FROM "warehouse"."main_silver"."silver_order_items"
    GROUP BY 1
)
SELECT
    o.order_id,
    o.customer_id,
    c.customer_name,
    o.order_status,
    o.payment_method,
    o.payment_status,
    o.order_ts,
    o.updated_ts,
    COALESCE(o.total_amount, line_rollup.gross_item_amount) AS total_amount,
    line_rollup.total_units,
    line_rollup.distinct_products,
    CURRENT_TIMESTAMP AS gold_loaded_at
FROM "warehouse"."main_silver"."silver_orders" o
LEFT JOIN line_rollup USING (order_id)
LEFT JOIN "warehouse"."main_silver"."silver_customers" c USING (customer_id)