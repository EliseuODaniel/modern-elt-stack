create or replace view "warehouse"."main_silver"."silver_order_items__dbt_int" as (
        select * from 's3://datalake/silver/erp/order_items/silver_order_items.parquet'
    );